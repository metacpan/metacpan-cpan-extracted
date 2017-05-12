package TestDB;

our $bindir;
use FindBin;
BEGIN { ( $bindir ) = ( $FindBin::Bin =~ /^(.*)$/ ) } # Untaint

use Exporter qw ( import );
use File::Spec::Functions qw ( :ALL );
use strict;
use warnings;

our @EXPORT = qw ( TestDSN TestUsername TestPassword TestHandleSetErr );

sub TestDSN {
  return "dbi:SQLite:".catfile ( $bindir, "lib", "test.db" );
}

use constant TestUsername => undef;

use constant TestPassword => undef;

# We need to allow regression tests to run without a proper database
# backend such as Postgres to test against.  We therefore use
# SQLite.  The DBI driver for SQLite does not support SQLSTATE; we
# hack around this by parsing the error message for some recognised
# keywords, and set the SQLSTATE accordingly.
#
use constant TestHandleSetErr => sub {
  ( my $h, my $err, my $errstr, my $state ) = @_;
  if ( $err && ! defined $state ) {
    if ( $errstr =~ /NULL/i ) {
      $state = "23502";
    } elsif ( $errstr =~ /unique/i ) {
      $state = "23505";
    }
    $_[3] = $state;
  }
  return undef;
};

1;
