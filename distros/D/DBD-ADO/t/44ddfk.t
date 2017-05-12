#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use DBD_TEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 4;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Foreign key tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

# -----------------------------------------------------------------------------
SKIP: {
  local ($dbh->{Warn}, $dbh->{PrintError});
  $dbh->{PrintError} = $dbh->{Warn} = 0;
  my $sth = $dbh->foreign_key_info( undef, undef, undef, undef, undef, undef );
  my $non_supported = '-2146825037';
  skip 'foreign_key_info not supported by provider', 1
    if $dbh->err && $dbh->err == $non_supported;
  ok( defined $sth,'Statement handle defined for foreign_key_info()');
  DBD_TEST::dump_results( $sth );
}
# -----------------------------------------------------------------------------

ok( $dbh->disconnect,'Disconnect');
