package CTK::DBI; # $Id: DBI.pm 272 2019-09-26 08:45:46Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::DBI - Database independent interface for CTKlib

=head1 VERSION

Version 2.30

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
            #-prepare_attr => {},
            #-debug     => 1,
        );

    my $dbh = $mso->connect or die($mso->error);

    die($mso->error) if $mso->error;

    # Table select (as array)
    my @result = $mso->table($sql, @inargs);

    # Table select (as hash)
    my %result = $mso->tableh($key, $sql, @inargs); # $key - primary index field name

    # Record (as array)
    my @result = $mso->record($sql, @inargs);

    # Record (as hash)
    my %result = $mso->recordh($sql, @inargs);

    # Field (as scalar)
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
            #-prepare_attr => {},
            #-debug     => 1,
        );

Create the DBI object

=head2 error

    die $mso->error if $mso->error;

Returns error string

=head2 connect

    my $dbh = $mso->connect;

Get DBH (DB handler)

=head2 disconnect

    my $rc = $mso->disconnect;

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

=head1 VARIABLES

=over 4

=item B<$CTK::DBI::CTK_DBI_DEBUG>

Debug mode flag. Default: 0

=item B<$CTK::DBI::CTK_DBI_ERROR>

General error string

=back

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
our $CTK_DBI_ERROR = "";
use vars qw/$VERSION/;
$VERSION = '2.30';

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
    _debug("Package Sys::SigAction don't installed! Please install this package") unless WIN;
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
          ['ATTRIBUTES','ATTR','ATTRS','ATTRHASH','PARAMS'],
          ['PREPARE_ATTRIBUTES','PREPARE_ATTR','PREPARE_ATTRS'],
          ['DEBUG'],
        ], @_);
    if ($in[7]) {
        $CTK_DBI_DEBUG = 1;
    }

    # General arguments
    my %args = (
            dsn         => $in[0] || '',
            user        => $in[1] // '',
            password    => $in[2] // '',
            connect_to  => $in[3] || TIMEOUT_CONNECT,
            request_to  => $in[4] || TIMEOUT_REQUEST,
            attr        => $in[5] || undef,
            prepare_attr=> $in[6] || undef,
            debug       => $in[7] // 0,
            dbh         => undef,
            error       => "", # Ok
        );

    # Connect
    my $_err = "";
    $args{dbh} = DBI_CONNECT($args{dsn}, $args{user}, $args{password}, $args{attr}, $args{connect_to}, \$_err);
    my $self = bless {%args}, $class;
    if ($args{dbh}) { # Ok
        _debug(sprintf("--- DBI CONNECT {%s} ---", $args{dsn}));
    } else {
        $self->_set_error($_err);
    }

    return $self;
}

sub _set_error {
    my $self = shift;
    my $merr = shift;
    my $dbh = $self->{dbh};

    if (defined($merr)) {
        $self->{error} = $merr;
    } elsif ($dbh && $dbh->can('errstr')) {
        $self->{error} = $self->{dbh}->errstr // '';
    } elsif (defined($DBI::errstr)) {
        $self->{error} = $DBI::errstr;
    } else {
        $self->{error} = "";
    }
    if ($dbh && $dbh->{PrintError}) {
        carp(sprintf("%s: %s", __PACKAGE__, $self->{error})) if length($self->{error});
    }

    return undef;
}

sub error {
    my $self = shift;
    return $self->{error} // "";
}
sub connect {
    # Returns dbh object
    my $self = shift;
    return $self->{dbh};
}
sub disconnect {
    my $self = shift;
    return unless $self->{dbh};
    my $rc = $self->{dbh}->disconnect;
    _debug(sprintf("--- DBI DISCONNECT {%s} ---", $self->{dsn} || ''));
    return $rc;
}
sub field {
    my $self = shift;
    my @result = $self->record(@_);
    return shift @result;
}
sub record {
    my $self = shift;
    my $sth = $self->execute(@_);
    return () unless $sth;
    my @result = $sth->fetchrow_array;
    $sth->finish;
    return @result;
}
sub recordh {
    my $self = shift;
    my $sth = $self->execute(@_);
    return () unless $sth;
    my $rslt = $sth->fetchrow_hashref;
    $rslt = {} unless $rslt && ref($rslt) eq 'HASH';
    my %result = %$rslt;
    $sth->finish;
    return %result;
}
sub table {
    my $self = shift;
    my $sth = $self->execute(@_);
    return () unless $sth;
    my $rslt = $sth->fetchall_arrayref;
       $rslt = [] unless $rslt && ref($rslt) eq 'ARRAY';
    my @result = @$rslt;
    $sth->finish;
    return @result;
}
sub tableh {
    my $self = shift;
    my $key_field = shift; # See keys (http://search.cpan.org/~timb/DBI-1.607/DBI.pm#fetchall_hashref)
    my $sth = $self->execute(@_);
    return () unless $sth;
    my $rslt = $sth->fetchall_hashref($key_field);
       $rslt = {} unless $rslt && ref($rslt) eq 'HASH';
    my %result = %$rslt;
    $sth->finish;
    return %result;
}
sub execute {
    my $self = shift;
    my $sql = shift // '';
    my @inargs = @_;
    my $dbh = $self->{dbh} || return;
    return $self->_set_error("No statement specified") unless length($sql);
    $self->_set_error(""); # Flush errors

    # Prepare
    my $prepare_attr = $self->{prepare_attr};
    my %attr = ($prepare_attr && ref($prepare_attr) eq 'HASH') ? %$prepare_attr : ();
    my $sth_ex = keys(%attr) ? $dbh->prepare($sql, {%attr}) : $dbh->prepare($sql);
    unless ($sth_ex) {
        return $self->_set_error(sprintf("Can't prepare statement \"%s\": %s", $sql, $dbh->errstr // 'unknown error'));
    }

    # Execute
    my $rto = $self->{request_to};
    my $count_execute     = 1;     # TRUE
    my $count_execute_msg = 'ok';  # TRUE
    eval {
        local $SIG{ALRM} = sub { die "execute timed out ($rto sec)" } unless $LOAD_SigAction;
        my $h = Sys::SigAction::set_sig_handler( 'ALRM' ,sub { die "execute timed out ($rto sec)" ; } );
        eval {
            alarm($rto);
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
        my @repsrgs = @inargs;
        my $argb = "";
        $argb = sprintf(" with bind variables: %s", join(", ", map {defined($_) ? sprintf("\"%s\"", $_) : 'undef'} @repsrgs))
            if exists($inargs[0]);
        return $self->_set_error(sprintf("Can't execute statement \"%s\"%s: %s", $sql, $argb || '', $count_execute_msg // 'unknown error'));
    }

    return $sth_ex;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect();
}
sub DBI_CONNECT {
    # Connect
    # $dbh = DBI_CONNECT($dsn, $user, $password, $attr, $to, $error)
    # IN:
    #   <DSN>      - DSN
    #   <USER>     - DB Username
    #   <PASSWORD> - DB Password
    #   <ATTR>     - Attributes DBD::* (hash-ref)
    #   <TIMEOUT>  - Timeout value
    #   <\ERROR>   - Reference to error scalar
    # OUT:
    #   $dbh - DataBase Handler Object
    #
    my $db_dsn      = shift || ''; # DSN
    my $db_user     = shift // '';
    my $db_password = shift // '';
    my $db_attr     = shift || {}; # E.g., {ORACLE_enable_utf8 => 1}
    my $db_tocnt    = shift || TIMEOUT_CONNECT;
    my $rerr        = shift;
       $rerr = \$CTK_DBI_ERROR unless $rerr && ref($rerr) eq 'SCALAR';

    my $dbh;

    my $count_connect     = 1;     # TRUE
    my $count_connect_msg = 'ok';  # TRUE
    eval {
        local $SIG{ALRM} = sub { die "connect timed out ($db_tocnt sec)" } unless $LOAD_SigAction;
        my $h = Sys::SigAction::set_sig_handler( 'ALRM', sub { die "connect timed out ($db_tocnt sec)" } );
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
        $$rerr = sprintf("Can't connect to \"%s\", %s", $db_dsn, $count_connect_msg // 'unknown error');;
    }

    return $dbh;
}

sub _debug { $CTK_DBI_DEBUG ? carp(@_) : 1 }

1;

__END__
