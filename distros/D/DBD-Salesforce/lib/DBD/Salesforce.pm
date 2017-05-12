package DBD::Salesforce;

# ----------------------------------------------------------------------
# $Id: Salesforce.pm,v 1.1.1.1 2006/02/14 16:54:03 shimizu Exp $
# ----------------------------------------------------------------------

use strict;
use vars qw($VERSION $REVISION);
use vars qw($err $errstr $state $drh);

use DBI;
use DBD::Salesforce::dr;
use DBD::Salesforce::db;
use DBD::Salesforce::st;

$VERSION = "0.04";    # $Date: 2006/02/14 16:54:03 $
$REVISION = sprintf "%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/;

# ----------------------------------------------------------------------
# Standard DBI globals: $DBI::err, $DBI::errstr, etc
# ----------------------------------------------------------------------
$err     = 0;
$errstr  = "";
$state   = "";
$drh     = undef;

# ----------------------------------------------------------------------
# Creates a new driver handle, which will be a singleton.
# ----------------------------------------------------------------------
sub driver {
    unless ($drh) {
        my ($class, $attr) = @_;
        my %stuff = (
            'Name'              => 'Salesforce',
            'Version'           => $VERSION,
            'DriverRevision'    => $REVISION,
            'Err'               => \$err,
            'Errstr'            => \$errstr,
            'State'             => \$state,
            'Attribution'       => 'DBD::Salesforce - Jun Shimizu <bayside@cpan.org>',
            'AutoCommit'        => 1, # to avoid errors
        );

        $class = join "::", $class, "dr";

        $drh = DBI::_new_drh($class, \%stuff);
    }

    return $drh;
}

sub DESTROY { 1 }

1;

__END__

=head1 NAME

DBD::Salesforce - Treat Salesforce as a datasource for DBI

=head1 SYNOPSIS

  use DBI;

  my $dbh = DBI->connect("dbi:Salesforce:", $id, $pass);
  my $sth = $dbh->prepare(qq[
      SELECT id, firstname, lastname FROM contact
  ]);

  while (my $r = $sth->fetchrow_hashref) {
      ...

=head1 DESCRIPTION

C<DBD::Salesforce> allows you to use Salesforce as a datasource; Salesforce can be
queried using SQL I<SELECT> statements, and iterated over using
standard DBI
conventions.

WARNING:  This is still alpha-quality software.  It works for me, but
that doesn't really mean anything.
