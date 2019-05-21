package CTK::DBI; # $Id: DBI.pm 250 2019-05-09 12:09:57Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::DBI - Database independent interface for CTKlib

=head1 VERSION

Version 2.29

=head1 SYNOPSIS

    use CTK::DBI;

    # Enable debugging
    # $CTK::DBI::CTK_DBI_DEBUG = 1;

    # MySQL connect
    my $mso = new CTK::DBI(
            -dsn        => 'DBI:mysql:database=TEST;host=192.168.1.1',
            -user       => 'login',
            -pass       => 'password',
            -connect_to => 5,
            -request_to => 60
            #-attr      => {},
            #-debug     => 1,
        );

    my $dbh = $mso->connect;

    # Table select (as array)
    my @result = $mso->table($sql, @inargs);

    # Table select (as hash)
    my %result = $mso->tableh($key, $sql, @inargs); # $key - primary index field name

    # Record (as array)
    my @result = $mso->record($sql, @inargs);

    # Record (as hash)
    my %result = $mso->recordh($sql, @inargs);

    # Fields (as scalar)
    my $result = $mso->field($sql, @inargs);

    # SQL
    my $sth = $mso->execute($sql, @inargs);
    ...
    $sth->finish;

=head1 DESCRIPTION

For example: print($mso->field("select sysdate() from dual"));

=head2 new

    # MySQL connect
    my $mso = new CTK::DBI(
            -dsn        => 'DBI:mysql:database=TEST;host=192.168.1.1',
            -user       => 'login',
            -pass       => 'password',
            -connect_to => 5,
            -request_to => 60
            #-attr      => {},
            #-debug     => 1,
        );

Create the DBI object

=head2 connect

    my $dbh = $mso->connect;

Get DBH (DB handler)

=head2 disconnect

    my $mso = $mso->disconnect;

Forced disconnecting. Please not use this method

=head2 execute

    # SQL
    my $sth = $mso->execute($sql, @inargs);
    ...
    $sth->finish;

Executing the SQL

=head2 field

    # Fields (as scalar)
    my $result = $mso->field($sql, @inargs);

Get (select) field from database as scalar value

=head2 record, recordh

    # Record (as array)
    my @result = $mso->record($sql, @inargs);

    # Record (as hash)
    my %result = $mso->recordh($sql, @inargs);

Get (select) record from database as array or hash

=head2 table, tableh

    # Table select (as array)
    my @result = $mso->table($sql, @inargs);

    # Table select (as hash)
    my %result = $mso->tableh($key, $sql, @inargs); # $key - primary index field name

Get (select) table from database as array or hash

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<DBI>, L<Sys::SigAction>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<DBI>, L<Sys::SigAction>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Carp;
use CTK::Util qw( :API );

use constant {
    WIN             => $^O =~ /mswin/i ? 1 : 0,
    TIMEOUT_CONNECT => 60, # timeout of connect
    TIMEOUT_REQUEST => 60, # timeout of request
};

our $CTK_DBI_DEBUG = 0;
use vars qw/$VERSION/;
$VERSION = '2.29';

my $LOAD_SigAction = 0;
eval 'use Sys::SigAction';
my $es = $@;
if ($es) {
    eval '
        package # hide me from PAUSE
            Sys::SigAction;
        sub set_sig_handler($$;$$) { 1 };
        1;
    ';
    _error("Package Sys::SigAction don't installed! Please install this package") unless WIN;
} else {
    $LOAD_SigAction = 1;
}

use DBI();

sub new {
    my $class = shift;
    my @in = read_attributes([
          ['DSN','STRING','STR'],
          ['USER','USERNAME','LOGIN'],
          ['PASSWORD','PASS'],
          ['TIMEOUT_CONNECT','CONNECT_TIMEOUT','CNT_TIMEOUT','TIMEOUT_CNT','TO_CONNECT','CONNECT_TO'],
          ['TIMEOUT_REQUEST','REQUEST_TIMEOUT','REQ_TIMEOUT','TIMEOUT_REQ','TO_REQUEST','REQUEST_TO'],
          ['ATTRIBUTES','ATTR','ATTRHASH','PARAMS'],
          ['DEBUG'],
        ],@_);
    if ($in[6]) {
        $CTK_DBI_DEBUG = 1;
    }

    # General arguments
    my %args = (
            dsn         => $in[0] || '',
            user        => $in[1] || '',
            password    => $in[2] || '',
            connect_to  => $in[3] || TIMEOUT_CONNECT,
            request_to  => $in[4] || TIMEOUT_REQUEST,
            attr        => $in[5] || undef,
            dbh         => undef,
        );

    # Connect
    $args{dbh} = DBI_CONNECT(@args{qw/dsn user password attr connect_to/});

    # Ok
    _debug("--- DBI CONNECT {".$args{dsn}."} ---");

    my $self = bless {%args}, $class;
    return $self;
}
sub connect {
    # Returns dbh
    my $self = shift;
    return $self->{dbh};
}
sub disconnect {
    # before DESTROY
    my $self = shift;
    DBI_DISCONNECT ($self->{dbh}) if $self->{dbh};
    # Ok
    _debug("--- DBI DISCONNECT {".($self->{dsn} || '')."} ---");
}
sub field {
    my $self = shift;
    DBI_EXECUTE_FIELD($self->{dbh},$self->{request_to},@_)
}
sub record {
    my $self = shift;
    DBI_EXECUTE_RECORD($self->{dbh},$self->{request_to},@_)
}
sub recordh {
    my $self = shift;
    DBI_EXECUTE_RECORDH($self->{dbh},$self->{request_to},@_)
}
sub table {
    my $self = shift;
    DBI_EXECUTE_TABLE($self->{dbh},$self->{request_to},@_)
}
sub tableh {
    my $self = shift;
    my $key_field = shift; # See keys (http://search.cpan.org/~timb/DBI-1.607/DBI.pm#fetchall_hashref)
    DBI_EXECUTE_TABLEH($self->{dbh},$key_field,$self->{request_to},@_)
}
sub execute {
    my $self = shift;
    DBI_EXECUTE($self->{dbh},$self->{request_to},@_)
}
sub DESTROY {
    my $self = shift;
    $self->disconnect();
}
sub DBI_CONNECT {
    # Connect
    # $dbh = DBI_CONNECT($dsn, $user, $password, $attr)
    # IN:
    #   <DSN>      - DSN
    #   <USER>     - DB Username
    #   <PASSWORD> - DB Password
    #   <ATTR>     - Attributes DBD::* (hash-ref)
    # OUT:
    #   $dbh - DataBase Handler Object
    #
    my $db_dsn      = shift || ''; # DSN
    my $db_user     = shift // '';
    my $db_password = shift // '';
    my $db_attr     = shift || {}; # E.g., {ORACLE_enable_utf8 => 1}
    my $db_tocnt    = shift || TIMEOUT_CONNECT;

    my $dbh;

    my $count_connect     = 1;     # TRUE
    my $count_connect_msg = 'OK';  # TRUE
    eval {
        local $SIG{ALRM} = sub { die "Connecting timeout \"$db_dsn\"" } unless $LOAD_SigAction;
        my $h = Sys::SigAction::set_sig_handler( 'ALRM', sub { die "Connecting timeout \"$db_dsn\"" } );
        eval {
            alarm($db_tocnt); #implement 2 second time out
            unless ($dbh = DBI->connect($db_dsn, "$db_user", "$db_password", $db_attr)) {
                $count_connect     = 0; # FALSE
                $count_connect_msg = $DBI::errstr;
            }
            alarm(0);
        };
        alarm(0);
        die $@ if $@;
    };
    if ( $@ ) {
        # Error
        $count_connect     = 0; # FALSE
        $count_connect_msg = $@;
    }
    unless ($count_connect) {
        # Error :(
        _error("[".__PACKAGE__.": Connecting error \"$db_dsn\"] $count_connect_msg");
    }

    return $dbh;
}
sub DBI_DISCONNECT {
    my $dbh = shift || return 0;
    my $rc = $dbh->disconnect;
    return $rc;
}
sub DBI_EXECUTE_FIELD {
    # Get field
    # $result = DBI_EXECUTE_FIELD($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $sql - SQL
    #   [@inargs] - For binding
    # OUT:
    #   $result - First [0] value

    my @result = DBI_EXECUTE_RECORD(@_);
    return $result[0] || '';
}
sub DBI_EXECUTE_RECORD {
    # Returns one record (array)
    # @result = DBI_EXECUTE_RECORD($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $sql - SQL
    #   [@inargs] - Binding arguments
    # OUT:
    #   @result - Array of data
    my $sth = DBI_EXECUTE(@_);
    return undef unless $sth;
    my @result = $sth->fetchrow_array;
    $sth->finish;
    return @result;
}
sub DBI_EXECUTE_RECORDH {
    # Returns one record (hash)
    # %result = DBI_EXECUTE_RECORDH($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $sql - SQL
    #   [@inargs] - Binding arguments
    # OUT:
    #   %result - Hash of data
    my $sth = DBI_EXECUTE(@_);
    return undef unless $sth;
    my %result = %{$sth->fetchrow_hashref || {}};
    $sth->finish;
    return %result;
}
sub DBI_EXECUTE_TABLE {
    # Get all data (table)
    # @result = DBI_EXECUTE_TABLE($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $sql - SQL
    #   [@inargs] - Binding arguments
    # OUT:
    #   @result - Array

    my $sth = DBI_EXECUTE(@_);
    return undef unless $sth;
    my @result = @{$sth->fetchall_arrayref};
    $sth->finish;
    return @result;
}
sub DBI_EXECUTE_TABLEH {
    # Get all data (table)
    # %result = DBI_EXECUTE_TABLEH($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $key_field - Key (http://search.cpan.org/~timb/DBI-1.607/DBI.pm#fetchall_hashref)
    #   $sql - SQL
    #   [@inargs] - Binding arguments
    # OUT:
    #   Rresult - Hash of Hashes
    my $dbh       = shift;
    my $key_field = shift;

    my $sth = DBI_EXECUTE($dbh,@_);
    return undef unless $sth;
    my %result = %{$sth->fetchall_hashref($key_field) || {}};
    $sth->finish;
    return %result;
}
sub DBI_EXECUTE {
    # Execute
    # $sth = DBI_EXECUTE($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $tor - TimeOut of Request
    #   $sql - SQL
    #   [@inargs] - Binding arguments
    # OUT:
    #   $sth_ex - statement header

    my $dbh = shift || return 0;
    my $tor = shift || TIMEOUT_REQUEST;
    my $sql = shift || return 0;

    my @inargs = ();
    @inargs = @_ if exists $_[0];
    my $argb = "";
    my @repsrgs = @inargs;
    $argb = sprintf("Params: %s", join(", ", map {defined($_) ? sprintf("\"%s\"",$_) : 'undef'} @repsrgs)) if exists $inargs[0];

    my $sth_ex = $dbh->prepare($sql);
    unless ($sth_ex) {
        _error("[".__PACKAGE__.": Preparing error: $sql"."] ".$dbh->errstr);
        return undef;
    }

    my $count_execute     = 1;     # TRUE
    my $count_execute_msg = 'OK';  # TRUE
    eval {
        local $SIG{ALRM} = sub { die "Executing timeout" } unless $LOAD_SigAction;
        my $h = Sys::SigAction::set_sig_handler( 'ALRM' ,sub { die "Executing timeout" ; } );
        eval {
            alarm($tor);
            unless ($sth_ex->execute(@inargs)) {
                $count_execute     = 0; # FALSE
                $count_execute_msg = $dbh->errstr;  # FALSE
            }
            alarm(0);
        };
        alarm(0);
        die $@ if $@;
    };
    if ( $@ ) {
        $count_execute     = 0; # FALSE
        $count_execute_msg = $@;
    }
    unless ($count_execute) {
        # Error
        _error("[".__PACKAGE__.": Executing error: $sql".($argb?" / $argb":'')."] $count_execute_msg");
        return undef;
    }

    return $sth_ex || undef;
}
sub _debug { $CTK_DBI_DEBUG ? carp(@_) : 1 }
sub _error { carp(@_) }

1;

__END__
