package DBIx::ObjectMapper::Engine::DBI;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Scalar::Util qw(refaddr);
use DBI;
use Data::Dumper;
use Data::Dump;
use Digest::MD5;
use Try::Tiny;

use base qw(DBIx::ObjectMapper::Engine);
use DBIx::ObjectMapper::SQL;
use DBIx::ObjectMapper::Utils;
use DBIx::ObjectMapper::Engine::DBI::Iterator;
use DBIx::ObjectMapper::Engine::DBI::Driver;
use DBIx::ObjectMapper::Engine::DBI::Transaction;

sub _init {
    my $self = shift;
    my $param = shift || confess 'invalid parameter.';
    $param = [ $param, @_ ] unless ref $param;

    my @connect_info;
    my $option;
    if ( ref $param eq 'ARRAY' ) {
        @connect_info = @$param[ 0 .. 2 ];
        $option = $param->[3] if $param->[3];
    }
    elsif ( ref $param eq 'HASH' ) {
        @connect_info = (
            delete $param->{dsn},
            delete $param->{username},
            delete $param->{password},
        );
        $option = $param;
    }
    else {
        confess 'invalid parameter.';
    }

    my $connect_do    = delete $option->{on_connect_do}    || [];
    my $disconnect_do = delete $option->{on_disconnect_do} || [];
    $self->{connect_do}
        = ref $connect_do eq 'ARRAY' ? $connect_do : [$connect_do];
    $self->{disconnect_do}
        = ref $disconnect_do eq 'ARRAY' ? $disconnect_do : [$disconnect_do];

    for my $name ( qw(db_schema namesep quote datetime_parser iterator
                      time_zone disable_prepare_caching cache) ) {
        $self->{$name} = delete $option->{$name} || undef;
    }

    push @connect_info,  {
        AutoCommit         => 1,
        RaiseError         => 1,
        PrintError         => 0,
        ShowErrorStatement => 1,
        HandleError        => sub{ confess($_[0]) },
        %{ $option || {} }
    };

    $self->{connect_info}       = \@connect_info;
    $self->{driver_type}        = undef;
    $self->{driver}             = undef;
    $self->{cache_target_table} = +{};
    $self->{iterator}         ||= 'DBIx::ObjectMapper::Engine::DBI::Iterator';
    $self->{txn_depth}          = 0;
    $self->{savepoints}         = [];

    return $self;
}

### Driver
sub iterator        { $_[0]->{iterator} }
sub namesep         { $_[0]->driver->namesep }
sub datetime_parser { $_[0]->driver->datetime_parser }
sub time_zone       { $_[0]->{time_zone} }
sub cache           { $_[0]->{cache} }

sub driver_type     {
    my $self = shift;
    $self->dbh unless $self->{driver_type};
    return $self->{driver_type};
}

sub query {
    my $self = shift;
    $self->dbh unless $self->{query};
    return $self->{query};
}

sub driver {
    my $self = shift;
    $self->connect unless $self->connected;
    return $self->{driver};
}


### Database Handle

sub DESTROY {
    my $self = shift;
    # some databases need this to stop spewing warnings
    if (my $dbh = $self->{_dbh}) {
        $self->_verify_pid;
        local $@;
        eval { $self->disconnect };
    }
    $self->{_dbh} = undef;
}

sub dbh {
    my $self = shift;
    $self->connect unless $self->connected;
    return $self->{_dbh};
}

sub connected {
    my $self = shift;

    if ( my $dbh = $self->{_dbh} ) {
        if( defined $self->{_tid} && $self->{_tid} != threads->tid ) {
            $self->{_dbh} = undef;
            return 0;
        }
        else {
            $self->_verify_pid;
            return 0 if !$self->{_dbh};
        }

        return ($dbh->{Active} && $dbh->ping);
    }

    return 0;
}

sub connect {
    my $self = shift;
    $self->{_pid} = $$;
    $self->{_tid} = threads->tid if $INC{'threads.pm'};
    $self->{_dbh} = $self->_connect;
}

sub _verify_pid {
    my ($self) = @_;

    return if defined $self->{_pid} && $self->{_pid} == $$;

    $self->{_dbh}->{InactiveDestroy} = 1;
    $self->{_dbh} = undef;
    return;
}

sub _connect {
    my $self = shift;

    my $dbh = do {
        if ($INC{'Apache/DBI.pm'} && $ENV{MOD_PERL}) {
            local $DBI::connect_via = 'connect'; # Disable Apache::DBI.
            DBI->connect( @{ $self->{connect_info} } );
        } else {
            DBI->connect( @{ $self->{connect_info} } );
        }
    };

    confess DBI->errstr unless $dbh;
    $self->log_connect('CONNECT');
    my $driver_type = $dbh->{Driver}{Name}
        || (DBI->parse_dsn( $self->{connect_info}[0] ))[1];

    $self->{query} ||= DBIx::ObjectMapper::SQL->new($driver_type);
    $self->{driver_type} = $driver_type;

    $self->{driver} = DBIx::ObjectMapper::Engine::DBI::Driver->new(
        $driver_type,
        $dbh,
        db_schema       => $self->{db_schema}       || undef,
        namesep         => $self->{namesep}         || undef,
        quote           => $self->{quote}           || undef,
        query           => $self->query,
        log             => $self->log,
        datetime_parser => $self->{datetime_parser} || undef,
        time_zone       => $self->{time_zone},
    );

    if ( $self->{time_zone}
        and my $tzq = $self->{driver}->set_time_zone_query($dbh) )
    {
        push @{ $self->{connect_do} }, $tzq;
    }

    $self->dbh_do( $dbh, $self->{connect_do} );

    $self->{txn_depth} = $dbh->{AutoCommit} ? 0 : 1 ;
    $self->{_dbh_gen}++;

    return $dbh;
}

sub disconnect {
    my ($self) = @_;
    if( my $dbh = $self->{_dbh} ) {
        $self->dbh_do( $dbh, $self->{disconnect_do} );
        while( $self->{txn_depth} > 0 ) {
            $self->_txn_rollback;
        }
        $dbh->disconnect;
        $self->log_connect('DISCONNECT');
        $self->{_dbh} = undef;
    }
}

#### TRANSACTION & SAVEPOINT

sub txn_begin {
    my $self = shift;

    my $dbh = $self->dbh;

    if ( $self->{txn_depth} == 0 ) {
        eval { $dbh->begin_work };
        if ($@) {
            confess "begin_work failed:" . $@;
        }
        else {
            $self->log_sql('BEGIN');
        }
    }
    else {
        $self->svp_begin;
    }

    return $self->{txn_depth}++;
}

sub txn_commit {
    my $self = shift;
    $self->_txn_end('commit', @_);
}

sub txn_rollback {
    my $self = shift;
    $self->_txn_end('rollback', @_);
}

sub _txn_end {
    my $self = shift;
    my $meth = shift;

    my $dbh = $self->dbh
        or confess "$meth called without a stored handle--begin_work?";

    if( $self->{txn_depth} == 1 ) {
        eval { $dbh->$meth() };
        confess "$meth failed for driver $self: $@" if $@;
        $self->log_sql( uc($meth) );
        $self->{txn_depth} = 0;
    }
    elsif( $self->{txn_depth} > 1 ) {
        $self->svp_rollback if $meth eq 'rollback';
        $self->svp_release;
        $self->{txn_depth}--;
    }
    else {
        confess 'Refusing to commit without a started transaction';
    }

    return 1;
}

sub txn_do {
    my $self = shift;
    my $code = shift;
    confess "it must be CODE reference" unless ref $code eq 'CODE';

    return $self->svp_do( $code, @_ ) if $self->{txn_depth};

    my @res;
    eval {
        $self->txn_begin(@_);
        @res = $code->();
        $self->txn_commit(@_);
    };

    if( my $err = $@ ) {
        $self->txn_rollback(@_);
        confess 'Transaction aborted: ' . $err;
    }

    return wantarray ? @res : $res[0];
}

sub svp_begin {
    my ( $self, $name ) = @_;
    confess "You can't use savepoints outside a transaction"
        unless $self->{txn_depth};
    $name ||= 'savepoint_' . scalar(@{$self->{savepoints}});
    push @{ $self->{savepoints} }, $name;
    $self->log_sql('SAVEPOINT ' . $name );
    return $self->driver->set_savepoint( $self->dbh, $name);
}

sub svp_release {
    my ($self, $name) = @_;

    confess "You can't use savepoints outside a transaction"
        unless $self->{txn_depth};

    if (defined $name) {
        confess "Savepoint '$name' does not exist"
            unless grep { $_ eq $name } @{ $self->{savepoints} };
        my $svp;
        do { $svp = pop @{ $self->{savepoints} } } while $svp ne $name;
    } else {
        $name = pop @{ $self->{savepoints} };
    }

    $self->log_sql( 'RELEASE SAVEPOINT ' . $name );
    return $self->driver->release_savepoint( $self->dbh, $name );
}

sub svp_rollback {
    my ($self, $name) = @_;

    confess "You can't use savepoints outside a transaction"
        unless $self->{txn_depth};

    if (defined $name) {
        unless(grep({ $_ eq $name } @{ $self->{savepoints} })) {
            confess "Savepoint '$name' does not exist!";
        }

        while(my $s = pop(@{ $self->{savepoints} })) {
            last if($s eq $name);
        }
        # Add the savepoint back to the stack, as a rollback doesn't remove the
        # named savepoint, only everything after it.
        push(@{ $self->{savepoints} }, $name);
    } else {
        # We'll assume they want to rollback to the last savepoint
        $name = $self->{savepoints}->[-1];
    }

    $self->log_sql( 'ROLLBACK TO SAVEPOINT ' . $name );
    return $self->driver->rollback_savepoint( $self->dbh, $name );
}


sub svp_do {
    my $self = shift;
    my $code = shift;
    confess "it must be CODE reference" unless ref $code eq 'CODE';

    my $dbh    = $self->dbh;
    my $driver = $self->driver;
    my @ret;
    eval {
        $self->svp_begin;
        @ret = $code->();
        $self->svp_release;
    };

    if (my $err = $@) {
        $self->svp_rollback;
        $self->svp_release;
        confess $err;
    }

    return wantarray ? @ret : $ret[0];
}

sub dbh_do {
    my ( $self, $dbh, $code ) = @_;

    if( ( ref $code || '' ) eq 'CODE' ) {
        $code->($dbh);
    }
    elsif( ( ref $code || '' ) eq 'ARRAY' ) {
        for my $c ( @$code ) {
            $self->dbh_do($dbh, $c);
        }
    }
    else {
        $self->log_sql($code);
        $dbh->do($code) or confess $self->dbh->errstr;
        $self->{sql_cnt}++;
    }
}

###################
sub transaction {
    my $self = shift;
    if (@_) {
        my $code = shift;
        confess "it must be CODE reference"
            unless $code and ref $code eq 'CODE';
        return $self->txn_do($code);
    }
    else {
        return DBIx::ObjectMapper::Engine::DBI::Transaction->new($self);
    }
}


### Metadata
sub get_primary_key {
    my ( $self, $table ) = @_;
    return $self->driver->get_primary_key($self->dbh, $table);
}

sub get_column_info {
    my ( $self, $table ) = @_;
    return $self->driver->get_column_info($self->dbh, $table);
}

sub get_unique_key {
    my ( $self, $table ) = @_;
    return $self->driver->get_table_uniq_info($self->dbh, $table);
}

sub get_foreign_key {
    my ( $self, $table ) = @_;
    return $self->driver->get_table_fk_info($self->dbh, $table);
}

sub get_tables {
    my ( $self ) = @_;
    return $self->driver->get_tables($self->dbh);
}

### Query

sub _prepare {
    my ( $self, $sql ) = @_;
    my $dbh = $self->dbh; # for on_connect_do
    return $self->{disable_prepare_caching}
        ? $dbh->prepare($sql)
        : $dbh->prepare_cached( $sql, undef, 3 );
}

sub select {
    my ( $self, $query, $callback ) = @_;
    my $query_class = ref( $self->query ) . '::Select';
    unless ( ref $query eq $query_class ) {
        $query = $self->_as_query_object( 'select', $query );
    }
    return $self->iterator->new( $query, $self, $callback );
}

sub select_single {
    my ( $self, $query, $callback ) = @_;
    my $query_class = ref( $self->query ) . '::Select';
    unless ( ref $query eq $query_class ) {
        $query = $self->_as_query_object('select', $query);
    }

    my ( $sql, @bind ) = $query->as_sql;
    $self->log_sql($sql, @bind);
    my ($key, $cache) = $self->get_cache_id($query);
    my $result;
    if( $key and $cache ) {
        $result = $cache;
    }
    else {
        #$result = $self->dbh->selectrow_arrayref($sql, +{}, @bind);
        my $sth = $self->_prepare($sql);
        $sth->execute(@bind) || confess $sth->errstr;
        $result = $sth->fetchrow_arrayref;
        $sth->finish;
        $self->{sql_cnt}++;
    }

    if( $key and !$cache and $result ) {
        $self->log_cache( 'Cache Set:' . $key );
        $self->cache->set( $key => $result );
    }

    return $callback && ref($callback) eq 'CODE'
        ? $callback->( $result, $query )
        : $result;
}

sub _as_query_object {
    my ($self, $action, $query ) = @_;
    return $self->query->$action( %$query );
}

sub update {
    my ( $self, $query, $callback ) = @_;

    my $query_class = ref( $self->query ) . '::Update';
    unless ( ref $query eq $query_class ) {
        $query = $self->_as_query_object('update', $query);
    }

    $callback->($query, $self->dbh) if $callback and ref($callback) eq 'CODE';

    if ( my $keys = $self->{cache_target_table}{ $query->table } ) {
        $self->{cache_target_table}{ $query->table } = [];
        $self->log_cache( 'Cache Remove : ' . join( ', ', @$keys ) );
        $self->cache->remove( $_ ) for @$keys;
    }

    my ( $sql, @bind ) = $query->as_sql;
    $self->log_sql($sql, @bind);
    my $ret = $self->dbh->do($sql, {}, @bind);
    $self->{sql_cnt}++;
    return $ret;
}

sub insert {
    my ( $self, $query, $callback, $primary_keys ) = @_;

    my $query_class = ref( $self->query ) . '::Insert';
    unless ( ref $query eq $query_class ) {
        $query = $self->_as_query_object('insert', $query);
    }

    $callback->($query, $self->dbh) if $callback and ref($callback) eq 'CODE';

    my ( $sql, @bind ) = $query->as_sql;
    $self->log_sql($sql, @bind);
    $self->dbh->do( $sql, {}, @bind );
    $self->{sql_cnt}++;

    my $ret_id = ref($query->values) eq 'HASH' ? $query->values : +{};

    if( $primary_keys ) {
        for my $pk (@$primary_keys) {
            unless ( defined $query->{values}->{$pk} ) {
                $ret_id->{$pk} = $self->driver->last_insert_id(
                    $self->dbh,
                    ($self->__get_table_name($query->into))[0],
                    $pk
                );
            }
        }
    }

    return $ret_id;
}

sub delete {
    my ( $self, $query, $callback ) = @_;

    my $query_class = ref( $self->query ) . '::Delete';
    unless ( ref $query eq $query_class ) {
        $query = $self->_as_query_object('delete', $query);
    }

    $callback->($query, $self->dbh) if $callback and ref($callback) eq 'CODE';

    if ( my $keys = $self->{cache_target_table}{ $query->table } ) {
        $self->{cache_target_table}{ $query->table } = [];
        $self->log_cache( 'Cache Remove : ' . join( ', ', @$keys ) );
        $self->cache->remove( $_ ) for @$keys;
    }

    my ( $sql, @bind ) = $query->as_sql;
    $self->log_sql($sql, @bind);
    my $ret = $self->dbh->do( $sql, {}, @bind );
    $self->{sql_cnt}++;
    return $ret;
}

# XXXX TODO CREATE TABLE
# sub create {  }

sub log_sql {
    my ( $self, $sql, @bind ) = @_;
    if( $self->log->is_info ) {
        $self->log->info( '{SQL}{'
                . refaddr($self) . '} '
                . _format_output_sql( $sql, @bind ) );
    }
}

sub _format_output_sql {
    my ( $sql, @bind ) = @_;
    my @output;
    push @output, $sql;
    push @output, \@bind if @bind;
    return Data::Dump::dump(@output);
}

sub log_connect {
    my ( $self, $meth ) = @_;
    if ( $self->log->is_info ) {
        $self->log->info( '{'
                . uc($meth) . '}{'
                . refaddr($self) . '} '
                . $self->{connect_info}[0] );
    }
}

sub log_cache {
    my ( $self, $comment ) = @_;
    if ( $self->log->is_info ) {
        $self->log->info( '{QueryCache}{' . refaddr($self) . '} ' . $comment );
    }
}

sub get_cache_id {
    my ( $self, $query ) = @_;

    return
        if !$self->cache
            or !$query->from
            or ( $query->limit and !$query->order_by );

    my @target_tables = $self->__get_table_name($query->from);

    push @target_tables, $self->__get_table_name( $query->{join} )
        if @{$query->{join}};

    local $Data::Dumper::Sortkeys = 1;
    my $key = Digest::MD5::md5_hex(ref($self) . Data::Dumper::Dumper($query));
    if( my $cache = $self->cache->get($key) ) {
        $self->log_cache( 'Cache Hit : '
                . $key . ' => '
                . _format_output_sql( $query->as_sql ) );
        return ($key, $cache);
    }

    push @{$self->{cache_target_table}{$_}}, $key for @target_tables;

    return $key;
}

sub __get_table_name {
    my ( $self, $from ) = @_;

    if( ref($from) eq 'ARRAY' ) {
        my @res;
        for my $f ( @$from ) {
            if( ref( $f ) eq 'ARRAY' ){
                push @res, $f->[0];
            }
            else{
                push @res, $f;
            }
        }
        return @res;
    }
    else {
        return $from;
    }
}

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Engine::DBI - the DBI engine

=head1 SYNOPSIS

 my $engine = DBIx::ObjectMapper::Engine::DBI->new({
     dsn => 'DBI:SQLite',
     username => 'username',
     password => 'password',
     AutoCommit         => 1,
     RaiseError         => 1,
     PrintError         => 0,
     ShowErrorStatement => 1,
     HandleError        => sub{ confess($_[0]) },
     on_connect_do => [],
     on_disconnect_do => [],
     db_schema => 'public',
     namesep => '.',
     quote => '"',
     iterator => '',
     time_zone => 'UTC',
     disable_prepare_caching => '',
     cache => '',
 });

 # or like a DBI module

 my $engine = DBIx::ObjectMapper::Engine::DBI->new([
     'DBI:SQLite','username', 'password',
     {
        AutoCommit         => 1,
        RaiseError         => 1,
        PrintError         => 0,
        ShowErrorStatement => 1,
        HandleError        => sub{ confess($_[0]) },
        on_connect_do => [],
        on_disconnect_do => [],
        db_schema => 'public',
        namesep => '.',
        quote => '"',
        iterator => '',
        time_zone => 'UTC',
        disable_prepare_caching => '',
        cache => '',
     }
 ]);


=head1 DESCRIPTION

=head1 PARAMETERS

=head2 dsn

=head2 username

=head2 password

=head2 on_connect_do

=head2 on_disconnect_do

=head2 db_schema

=head2 namesep

=head2 quote

=head2 iterator

=head2 time_zone

=head2 disable_prepare_caching

=head2 cache

=head1 METHODS

=head2 iterator

=head2 namesep

=head2 datetime_parser

=head2 time_zone

=head2 cache

=head2 driver_type

=head2 query

=head2 driver

=head2 dbh

=head2 connected

=head2 connect

=head2 disconnect

=head2 txn_begin

=head2 txn_commit

=head2 txn_rollback

=head2 txn_do

=head2 svp_do

=head2 dbh_do

=head2 transaction

=head2 get_primary_key

=head2 get_column_info

=head2 get_unique_key

=head2 get_foreign_key

=head2 get_tables

=head2 select

=head2 select_single

=head2 update

=head2 insert

=head2 delete

=head2 log_sql

=head2 log_connect

=head2 log_cache

=head2 get_cache_id

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
