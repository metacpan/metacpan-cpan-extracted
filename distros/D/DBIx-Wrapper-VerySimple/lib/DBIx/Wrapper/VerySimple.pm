# $Header: /usr/local/CVS/perl-modules/DBIx-Wrapper-VerySimple/lib/DBIx/Wrapper/VerySimple.pm,v 1.5 2006/11/02 04:10:39 matisse Exp $
###############################################################################

package DBIx::Wrapper::VerySimple;
use strict;
use warnings;
use Carp qw(cluck confess);
use DBI;
our $VERSION = 0.051;

# private instance variables
my %DB_HANDLES = ();
my %ARGS       = ();

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $ARGS{$self} = \@_;    # So we can use them to reconnect if needed
    $DB_HANDLES{$self} = DBI->connect(@_)
      || confess("Could not connect using DSN: '@_'");

    return $self;
}

sub dbh {
    my ($self) = @_;
    return $DB_HANDLES{$self};
}

sub get_args {
    my ($self) = @_;
    return $ARGS{$self};
}

sub FetchHash {    ## no critic ProhibitMixedCaseVars
    my ( $self, $sql, @bind_values ) = @_;
    my $sth = $DB_HANDLES{$self}->prepare_cached($sql)
      or confess( $DB_HANDLES{$self}->errstr, "SQL: {$sql}" );
    $sth->execute(@bind_values) or confess("SQL: {$sql}");
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    return $row;
}

sub FetchAll {    ## no critic ProhibitMixedCaseVars
    my ( $self, $sql, @bind_values ) = @_;
    my @rows;
    my $sth = $DB_HANDLES{$self}->prepare_cached($sql)
      or confess( $DB_HANDLES{$self}->errstr, "SQL: {$sql}" );
    $sth->execute(@bind_values) or confess("SQL: {$sql}");
    while ( my $row = $sth->fetchrow_hashref ) {
        push @rows, $row;
    }
    $sth->finish;
    return \@rows;
}

{
    no warnings qw(once);
    *fetch_hash = \&FetchHash;
    *fetch_all  = \&FetchAll;
}    

sub Do {    ## no critic ProhibitMixedCaseVars
    my ( $self, $sql, @bind_values ) = @_;
    my $sth = $DB_HANDLES{$self}->prepare_cached($sql)
      or confess( $DB_HANDLES{$self}->errstr, "SQL: {$sql}" );
    my $result_code = $sth->execute(@bind_values)
      or confess( $DB_HANDLES{$self}->errstr, "SQL: {$sql}" );
    $sth->finish;
    return $result_code;
}

sub DESTROY {
    my ($self) = @_;

    # warn ref $self, " executing DESTROY method. Disconnecting from database";
    return $DB_HANDLES{$self}->disconnect if $DB_HANDLES{$self};
}

###########################################################################
1;

__END__

=head1 NAME

DBIx::Wrapper::VerySimple - Simplify use of DBI

=head1 VERSION

0.051

=head1 SYNOPSIS

  use DBIx::Wrapper::VerySimple;
  $db = DBIx::Wrapper::VerySimple->new( $dsn, @other_args ); 
  $hashref = $db->FetchHash($sql, @bind_values);
  $arrayref = $db->FetchAll($sql, @bind_values);
  $rv       = $db->Do($sql, @bind_values);
  $original_args = $db->get_args();  # arrayref
  $dbh      = $db->dbh();  # Raw DBI database handle

=head1 DESCRIPTION

Provides a wrapper around DBI.

Note: the reason we don't test the connection and attempt to reconnect
is that this module is most likely used in a web environment with
mod_perl and Apache::DBI, and Apache::DBI will attempt to reconnect
if the database connection dies.


=head1 Per-Method Documentation

These are the public methods provided.

=head2 new

	my $db = DBIx::Wrapper::VerySimple->new($dsn,$user,password);

$dsn is a B<DBI> DSN, for example:

	$dsn = q{DBI:mysql:database='Accounting'};

or a more complex example:

	$database = 'Accounting';
	$host     = 'data.ourdomain.com';  # Default is usually 'localhost'
	$port     = '4200';  # 3306 is the MySQl default
	$dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";

=head2 fetch_hash or FetchHash

  $hashref = $db->fetch_hash( $sql, @bind_values );

Returns a HASH ref for one row.
Throws an exception if execution fails.

=head2 fetch_all or FetchAll

  $arrayref = $db->fetch_all( $sql, @bind_values );

Returns an ARRAY ref of HASH refs. @bind_values are optional.
Throws an exception if execution fails.

=head2 Do

    $result_code = $db->Do( $sql, @bind_values );

Executes a non-select SQL statement
Throws an exception if execution fails.

=head2 dbh

  $db->dbh();

Returns the raw database handle from L<DBI>.

=head2 get_args

  $db->get_args();

Returns an ARRAY ref of the original args to new();

=head1 SEE ALSO

L<DBI>, L<Apache::DBI>

=head2 Other Wrapper Modules

L<DBIx::Simple>, L<DBIx::Wrapper> - have more features, but are
not as simple as this module.

=head1 AUTHOR

Matisse Enzer E<lt>matisse@matisse.netE<gt>

=head1 COPYRIGHT

Copyright (c)2001-2006 by Matisse Enzer

=head1 LICENSE

This package is free software and is provided "as is"
without express or implied warranty.  It may be used,
redistributed and/or modified under the terms of the Perl
Artistic License (see http://www.perl.com/perl/misc/Artistic.html)

=cut

