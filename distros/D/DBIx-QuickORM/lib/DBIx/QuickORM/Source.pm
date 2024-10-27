package DBIx::QuickORM::Source;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/croak confess/;
use List::Util qw/min zip/;
use Scalar::Util qw/blessed weaken refaddr/;
use DBIx::QuickORM::Util qw/parse_hash_arg mod2file/;

use Scope::Guard;
use DBIx::QuickORM::Row;
use DBIx::QuickORM::Select;
use DBIx::QuickORM::GlobalLookup;

use DBIx::QuickORM::Util::HashBase qw{
    <schema
    <table
    +table_name
    <orm
    +row_class
    <locator
    <created
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::SelectLike';
with 'DBIx::QuickORM::Role::HasORM';

sub source  { $_[0] }
sub count   { shift->select()->count(@_) }
sub update  { shift->select()->update(@_) }
sub shotgun { shift->select()->shotgun(@_) }

sub table_name { $_[0]->{+TABLE_NAME} //= $_[0]->{+TABLE}->name }

sub relations { die "Fixme" }

sub init {
    my $self = shift;

    my $table = $self->{+TABLE} or croak "The 'table' attribute must be provided";
    croak "The 'table' attribute must be an instance of 'DBIx::QuickORM::Table'" unless $table->isa('DBIx::QuickORM::Table');

    my $schema = $self->{+SCHEMA} or croak "The 'schema' attribute must be provided";
    croak "The 'schema' attribute must be an instance of 'DBIx::QuickORM::Schema'" unless $schema->isa('DBIx::QuickORM::Schema');

    weaken($self->{+ORM});

    $self->{+LOCATOR} = DBIx::QuickORM::GlobalLookup->register($self, weak => 1);

    return $self;
}

sub set_row_class {
    my $self = shift;
    my ($class) = @_;

    require(mod2file($class));

    return $self->{+ROW_CLASS} = $class;
}

sub row_class {
    my $self = shift;
    return $self->{+ROW_CLASS} if $self->{+ROW_CLASS};

    my $class = $self->{+TABLE}->row_class // $self->orm->row_class or return $self->{+ROW_CLASS} = 'DBIx::QuickORM::Row';

    require(mod2file($class));

    return $self->{+ROW_CLASS} = $class;
}

sub clone {
    my $self   = shift;
    my %params = @_;
    my $class  = $params{source_class} // blessed($self);

    return $class->new(
        %$self,
        %params,
    );
}

sub update_or_insert {
    my $self = shift;
    my $row_data = $self->parse_hash_arg(@_);

    my $cache = $self->cache;

    if (my $cached = $cache->find_row($self, $row_data)) {
        $cached->update($row_data);
        return $cached;
    }

    # Can we turn this to an upsert?
    my $row = $self->txn_do(sub {
        if (my $row = $self->find($row_data)) {
            $row->update($row_data);
            return $row;
        }

        return $self->insert($row_data);
    });

    return $cache->add_source_row($self, $row);
    return $row;
}

sub find_or_insert {
    my $self = shift;
    my $row_data = $self->parse_hash_arg(@_);

    my $cache = $self->cache;

    if (my $cached = $cache->find_row($self, $row_data)) {
        return $cached;
    }

    my $row = $self->txn_do(sub { $self->find($row_data) // $self->insert($row_data) });

    return $cache->add_source_row($self, $row);
    return $row;
}

sub _parse_find_and_fetch_args {
    my $self = shift;

    return {@_} unless @_ == 1;
    if (ref($_[0]) eq 'HASH') {
        return $_[0] if $_[0]->{where};
        return { where => $_[0] };
    }

    my $pk = $self->{+TABLE}->primary_key;
    croak "Cannot pass in a single value for find() or fetch() when table has no primary key"         unless $pk && @$pk;
    croak "Cannot pass in a single value for find() or fetch() when table has a compound primary key" unless @$pk == 1;
    return {where => {$pk->[0] => $_[0]}};
}

sub aggregate {
    my $self = shift;
    $self->select()->aggregate(@_);
}

sub any {
    my $self = shift;
    $self->select(@_)->first();
}

sub async {
    my $self = shift;
    $self->select(@_)->async();
}

sub aside {
    my $self = shift;
    $self->select(@_)->aside();
}

sub forked {
    my $self = shift;
    $self->select(@_)->forked();
}

sub first {
    my $self = shift;
    $self->select(@_)->first();
}

sub last {
    my $self = shift;
    $self->select(@_)->last();
}

sub all {
    my $self = shift;
    $self->select(@_)->all();
}

sub select {
    my $self = shift;

    # {where}
    # {where}, order
    # where => ..., order => ..., ...
    # {where => { ... }, order => ..., ...}
    my $params;
    if (!@_) {
        $params = {where => {}};
    }
    elsif (ref($_[0]) eq 'HASH') {
        $params = $self->_parse_find_and_fetch_args(shift(@_));
        $params->{order_by} = shift(@_) if @_ == 1;
    }

    $params = {%{$params // {}}, @_} if @_;

    return DBIx::QuickORM::Select->new(source => $self, %$params);
}

sub busy { $_[0]->connection->async_started }

sub count_select {
    my $self = shift;
    my ($params) = @_;

    my $where = $params->{where};

    my $table = $self->{+TABLE};
    my $con = $self->connection;

    confess "This database connection is currently engaged in an async query" if $con->async_started;

    my $source = $table->sqla_source;
    $source = \"$source AS me" unless ref($source);
    my ($stmt, $bind) = $self->build_select_sql($source, ['count(*)'], $where);

    my $sth = $con->dbh->prepare($stmt);
    $sth->execute(@$bind);

    my ($count) = $sth->fetchrow_array;

    $count //= 0;

    if (my $limit = $params->{limit}) {
        $count = min($count, $limit);
    }

    return $count;
}

sub do_select {
    my $self = shift;
    my ($params, %extra) = @_;

    my $aside  = $extra{aside};
    my $async  = $extra{async};
    my $forked = $extra{forked};
    my $where  = $params->{where};
    my $order  = $params->{order_by};

    my $con = $self->connection;

    confess "This database connection is currently engaged in an async query" if $con->async_started;
    confess "Async is not supported by this database engine" if $async && !$con->supports_async;

    my ($source, $cols, $relmap) = $self->_source_and_cols($params->{prefetch});
    my ($stmt, $bind) = $self->build_select_sql($source, $cols, $where, $order ? $order : ());

    if (my $limit = $params->{limit}) {
        $stmt .= " LIMIT ?";
        push @$bind => $limit;
    }

    my $sth = $con->dbh->prepare($stmt, $async ? ($con->async_query_arg) : ());
    $sth->execute(@$bind);

    my $guard;
    if ($aside) {
        $con->add_side_connection;
        $guard = Scope::Guard->new(sub { $con->pop_side_connection });
    }

    return {
        sth    => $sth,
        cols   => $cols,
        relmap => $relmap,
        guard  => $guard,
    } if $forked;

    my $fetch = sub {
        my $source = shift // $self;

        my @out;
        while (my $data = $sth->fetchrow_arrayref) {
            my $row = {};
            @{$row}{@$cols} = @$data;
            $source->expand_relations($row, $relmap);
            push @out => $source->_expand_row($row);
        }

        $con->async_stop() if $async;
        $con->pop_side_connection;

        return \@out;
    };

    return $fetch->() unless $async;

    my $started = {
        fetch  => $fetch,
        sth    => $sth,
        guard  => $guard,
        ready  => sub { $con->async_ready($sth) },
        result => sub { $con->async_result($sth) },
        cancel => sub { $con->async_cancel($sth) },
    };

    $con->async_start($async);

    return $started;
}

sub find {
    my $self  = shift;
    my $params = $self->_parse_find_and_fetch_args(@_);
    my $where = $params->{where};

    # See if there is a cached copy with the data we have
    my $cached = $self->cache->find_row($self, $where);
    return $cached if $cached;

    my $data = $self->fetch($params) or return;

    return $self->_expand_row($data);
}

# Get hashref data for one object (no cache)
sub fetch {
    my $self  = shift;
    my $params = $self->_parse_find_and_fetch_args(@_);
    my $where = $params->{where};

    my $con = $self->connection;

    my ($source, $cols, $relmap) = $self->_source_and_cols($params->{prefetch});
    my ($stmt, $bind) = $self->build_select_sql($source, $cols, $where);
    my $sth = $con->dbh->prepare($stmt);
    $sth->execute(@$bind);

    my $data = $sth->fetchrow_arrayref or return undef;
    my $extra = $sth->fetchrow_arrayref;
    croak "Multiple rows returned for fetch/find operation" if $extra;

    my $row = {};

    if ($relmap) {
        @{$row}{@$cols} = @$data;
        $self->expand_relations($row, $relmap);
    }
    else {
        s/^me\.// for @$cols;
        @{$row}{@$cols} = @$data;
    }


    return $row;
}

sub insert_row {
    my $self = shift;
    my ($row) = @_;

    croak "Row already exists in the database" if $row->stored;

    my $row_data = $row->dirty;

    my $data = $self->_insert($row_data);

    $row->refresh($data, $self->transaction, insert => 1);

    return $self->cache->add_source_row($self, $row);
}

sub insert {
    my $self = shift;

    my $row_data = $self->parse_hash_arg(@_);

    my $data = $self->_insert($row_data);
    my $row  = $self->row_class->new(stored => $data, source => $self);

    return $self->cache->add_source_row($self, $row);
}

sub _insert {
    my $self = shift;
    my ($row_data) = @_;

    my $con   = $self->connection;
    my $ret   = $con->db->insert_returning_supported;
    my $table = $self->{+TABLE};
    my $tname = $table->name;

    $row_data = $self->deflate_row_data($row_data);

    my ($stmt, @bind) = $con->sqla->insert($tname, $row_data, $ret ? {returning => [$table->column_names]} : ());

    my $dbh = $con->dbh;
    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);

    my $data;
    if ($ret) {
        $data = $sth->fetchrow_hashref;
    }
    else {
        my $pk_fields = $self->{+TABLE}->primary_key;

        my $where;
        if (@$pk_fields > 1) {
            $where = {map { my $v = $row_data->{$_} or croak "Auto-generated compound primary keys are not supported for databses that do not support 'returning' functionality"; ($_ => $v) } @$pk_fields};
        }
        else {
            my $kv = $dbh->last_insert_id(undef, undef, $tname);
            $where = {$pk_fields->[0] => $kv};
        }

        my ($stmt, $bind) = $self->build_select_sql($table->sqla_source, $table->sqla_columns, $where);
        my $sth = $dbh->prepare($stmt);
        $sth->execute(@$bind);
        $data = $sth->fetchrow_hashref;
    }

    return $data;
}

sub build_select_sql {
    my $self = shift;
    my ($stmt, $bind, $bind_names) = $self->connection->sqla->select(@_);

    die "Internal error: Length mistmatch between bind elements and bind names (" . @$bind . " vs " . @$bind_names . ")"
        unless @$bind == @$bind_names;

    my @new_bind = map { $self->deflate_column_data(@{$_}) } zip($bind_names, $bind);

    return ($stmt, \@new_bind);
}

sub deflate_row_data {
    my $self = shift;
    my $row_data = $self->parse_hash_arg(@_);

    my $new_data = {map {($_ => $self->deflate_column_data($_, $row_data->{$_}))} keys %$row_data};

    return $new_data;
}

sub deflate_column_data {
    my $self = shift;
    my ($col, $val) = @_;

    my $table = $self->{+TABLE};
    my $tname = $table->name;
    $col =~ s/^\S+\.// if index($col, '.');
    my $def = $table->column($col) or confess "Table '$tname' does not have a column '$col'";

    if (my $conf = $def->{conflate}) {
        return $conf->qorm_deflate(quote_bin => $self->connection, source => $self, column => $def, value => $val, type => $self->connection->column_type($tname, $col));
    }

    if (blessed($val) && $val->can('qorm_deflate')) {
        return $val->qorm_deflate(quote_bin => $self->connection, source => $self, column => $def, value => $val, type => $self->connection->column_type($tname, $col));
    }

    return $val;
}

sub vivify {
    my $self = shift;
    my $row_data = $self->parse_hash_arg(@_);
    return $self->row_class->new(dirty => $row_data, source => $self);
}

sub DESTROY {
    my $self = shift;

    if (my $orm = $self->orm) {
        if (my $cache = $orm->cache) {
            $cache->remove_source($self);
        }
    }

    return;
}

sub _expand_row {
    my $self = shift;
    my ($data) = @_;

    my %relations;

    for my $key (keys %$data) {
        my $row = $data->{$key} or next;
        next unless ref($row) eq 'HASH';

        my $rel = $self->{+TABLE}->relation($key);
        my $source = $self->{+ORM}->source($rel->table);

        $relations{$key} = $source->_expand_row(delete $data->{$key});
    }

    my $cache = $self->cache;

    if (my $cached = $cache->find_row($self, $data)) {
        $cached->refresh($data);
        $cached->_update_fetched_relations(\%relations);
        return $cached;
    }

    return $cache->add_source_row(
        $self,
        $self->row_class->new(stored => $data, source => $self, fetched_relations => \%relations),
    );
}

sub _source_and_cols {
    my $self = shift;
    my ($prefetch) = @_;

    my $table = $self->{+TABLE};
    my $prefetch_sets = $table->prefetch_relations($prefetch);

    unless (@$prefetch_sets) {
        my $source = $table->sqla_source;
        my $cols = $table->sqla_columns;

        return ($source, $cols) if ref($source);

        return (\"$source AS me", [map { "me.$_" } @$cols]);
    }

    my $source = $table->sqla_source . " AS me";
    my @cols   = map { "me.$_" } @{$table->sqla_columns};

    my %relmap;
    my @todo = map {[@{$_}, 'me'] } @$prefetch_sets;

    while (my $item = shift @todo) {
        my ($as, $rel, @path) = @$item;
        my ($from) = @path;

        confess "Multiple relations requested the alias (AS) '$as', please specify an alternate name for one"
            if $relmap{$as};

        my $ftable = $rel->table;

        $relmap{$as} = [@path, $as];

        my $ts = $self->orm->source($ftable);
        my $t2 = $ts->table;

        my $s2 = $t2->sqla_source;
        my $c2 = $t2->sqla_columns;

        $source .= " JOIN $s2 AS $as";
        $source .= " ON(" . $rel->on_sql($from, $as) . ")";

        push @cols => map { "${as}.$_" } @$c2;
        push @todo => map { [@{$_}, @path] } @{$t2->prefetch_relations};
    }

    return (\$source, \@cols, \%relmap);
}

sub expand_relations {
    my $self = shift;
    my ($data, $relmap) = @_;

    $relmap //= {};

    for my $key (keys %$data) {
        next unless $key =~ m/^(.+)\.(.+)$/;
        my ($rel, $col) = ($1, $2);
        if ($rel eq 'me') {
            $data->{$col} = delete $data->{$key};
            next;
        }

        my $path = $relmap->{$rel} or die "No relmap path for '$key'";

        my $p = $data;
        for my $pt (@$path) {
            next if $pt eq 'me';
            $p = $p->{$pt} //= {};
        }

        $p->{$col} = delete $data->{$key};
    }

    return $data;
}

# See the Cpanel::JSON::XS docs
sub FREEZE {
    my $self = shift;
    my ($serializer) = @_;
    return ($self->TO_JSON);
}

sub THAW {
    my $class = shift;
    my ($serializer, $data) = @_;

    return $class->FROM_JSON($data);
}

sub FROM_JSON {
    my $class = shift;
    my ($data) = @_;

    return $data if $data->{error};

    if (my $locator = $data->{locator}) {
        if (my $found = DBIx::QuickORM::GlobalLookup->lookup(@$locator)) {
            my $check = $found->TO_JSON;

            return {error => "Source content mismatch between origin and local copy (Source objects can only be serialized between parent and child processes, and only using source objects established prior to forking)"}
                if grep { $_ eq 'locator' || $data->{$_} ne $check->{$_} } keys %$check;

            return $found;
        }
    }

    return { error => "Could not find the source in this processes memory" }
}

sub TO_JSON {
    my $self = shift;

    my $orm   = $self->{+ORM};
    my $table = $self->{+TABLE};

    # We may be able to relax this later and send the temp table spec, but not
    # going to write that until it is needed.
    return { error => "Cannot serialize, references a temporary table that may not exist when deserialized" }
        if $table->is_temp;

    return {
        orm_name     => $orm->name          // '',
        table_name   => $self->table_name   // '',
        row_class    => $self->{+ROW_CLASS} // '',
        source_class => blessed($self),
        locator      => $self->{+LOCATOR},
    };
}

1;
