package CTK::DBI;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::DBI - Database independent interface for CTKlib

=head1 VERSION

Version 2.31

=head1 SYNOPSIS

    use CTK::DBI;

    # Enable debugging
    # $CTK::DBI::CTK_DBI_DEBUG = 1;

    # MySQL connect
    my $mso = CTK::DBI->new(
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
    my $mso = CTK::DBI->new(
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

=head2 connect

    my $dbh = $mso->connect;

See L</dbh>

=head2 dbh

    my $dbh = $mso->dbh;

Returns DBH object (DB handler of DBI)

=head2 disconnect

    my $rc = $mso->disconnect;

Forced disconnecting. Please not use this method

=head2 error

    die $mso->error if $mso->error;

Returns error string

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

L<DBI>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '2.31';

our $CTK_DBI_DEBUG = 0;
our $CTK_DBI_ERROR = "";

use Carp;
use CTK::Util qw( :API );
use CTK::Timeout;
use DBI qw();

# Create global Timeout object
my $to = CTK::Timeout->new();

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
            connect_to  => $in[3] // 0,
            request_to  => $in[4] // 0,
            attr        => $in[5] || undef,
            prepare_attr=> $in[6] || undef,
            debug       => $in[7] // 0,
            dbh         => undef,
            error       => "", # Ok
        );

    # Connect
    my $_err = "";
    $args{dbh} = DBI_CONNECT($args{dsn}, $args{user}, $args{password}, $args{attr}, $args{connect_to}, \$_err);

    # Create CTK::DBI object
    my $self = bless {%args}, $class;
    if ($args{dbh}) { # Ok
        _debug(sprintf("--- CTK::DBI CONNECT {%s} ---", $args{dsn}));
    } else {
        $self->_set_error($_err);
    }

    return $self;
}

sub _set_error {
    my $self = shift;
    my $merr = shift;
    my $dbh = $self->{dbh};

    # Set error string
    $self->{error} = "";
    if (defined($merr)) {
        $self->{error} = $merr;
    } else {
        if ($dbh && $dbh->can('errstr')) {
            $self->{error} = $dbh->errstr // '';
        }
        unless (length($self->{error})) {
            $self->{error} = $DBI::errstr;
        }
    }

    # Print error if PrintError
    if ($dbh && $dbh->{PrintError}) {
        carp(sprintf("%s: %s", __PACKAGE__, $self->{error})) if length($self->{error});
    }

    return;
}

sub error {
    my $self = shift;
    return $self->{error} // "";
}
sub dbh {
    # Returns dbh object
    my $self = shift;
    return $self->{dbh};
}
sub connect { goto &dbh }
sub disconnect {
    my $self = shift;
    return unless $self->{dbh};
    my $rc = $self->{dbh}->disconnect;
    _debug(sprintf("--- CTK::DBI DISCONNECT {%s} ---", $self->{dsn} || ''));
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
    $self->_set_error(""); # Flush errors first
    return $self->_set_error("No statement specified") unless length($sql);

    # Prepare
    my $prepare_attr = $self->{prepare_attr};
    my %attr = ($prepare_attr && ref($prepare_attr) eq 'HASH') ? %$prepare_attr : ();
    my $sth_ex = keys(%attr)
        ? $dbh->prepare($sql, {%attr})
        : $dbh->prepare($sql);
    unless ($sth_ex) {
        return $self->_set_error(sprintf("Can't prepare statement \"%s\": %s", $sql, $dbh->errstr // 'unknown error'));
    }

    # Execute
    my $err = "";
    my $retval = $to->timeout_call(sub {
            unless ($sth_ex->execute(@inargs)) {
                $err = $dbh->errstr || "the DBI::execute method has returned false status";
            }
            1;
        }, $self->{request_to});
    unless ($retval) {
        $err = $to->error || "unknown error";
    }

    # Errors
    if ($err) {
        my @repsrgs = @inargs;
        my $argb = "";
        $argb = sprintf(" with bind variables: %s", join(", ", map {defined($_) ? sprintf("\"%s\"", $_) : 'undef'} @repsrgs))
            if exists($inargs[0]);
        return $self->_set_error(sprintf("Can't execute statement \"%s\"%s: %s", $sql, $argb, $err));
    }

    return $sth_ex;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect();
}
sub DBI_CONNECT {
    # $dbh = DBI_CONNECT($dsn, $user, $password, $attr, $timeout, \$error)
    my $db_dsn      = shift || ''; # DSN
    my $db_user     = shift // ''; # DB Username
    my $db_password = shift // ''; # DB Password
    my $db_attr     = shift || {}; # Attributes DBD::* (hash-ref) E.g., {ORACLE_enable_utf8 => 1}
    my $db_tocnt    = shift // 0;  # Timeout value
    my $rerr        = shift;       # Reference to error scalar
       $rerr = \$CTK_DBI_ERROR unless $rerr && ref($rerr) eq 'SCALAR';
    my $dbh;

    # Connect
    my $err = "";
    my $retval = $to->timeout_call(sub {
            $dbh = DBI->connect($db_dsn, "$db_user", "$db_password", $db_attr);
            unless ($dbh) {
                $err = $DBI::errstr || "the DBI::connect method has returned false status";
            }
            1;
        }, $db_tocnt);
    unless ($retval) {
        $err = $to->error || "unknown error";
    }

    # Errors
    if ($err) {
        $$rerr = sprintf("Can't connect to \"%s\", %s", $db_dsn, $err);
    }

    # DBI handler or undef
    return $dbh;
}

sub _debug { $CTK_DBI_DEBUG ? carp(@_) : 1 }

1;

__END__
