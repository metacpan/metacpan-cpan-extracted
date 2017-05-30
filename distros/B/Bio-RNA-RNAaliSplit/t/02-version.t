use Test::More tests => 2;
use lib 'inc';
eval "use Version::Compare";
plan skip_all => "Version::Compare required to test version of non-CPAN modules" if $@;

BEGIN {
  use_ok( 'RNA' ) || print "Bail out! Cannot load Vienna RNA Perl module \n";
}
cmp_ok( Version::Compare::version_compare($RNA::VERSION,'2.3.4'), '>=', 0,
'check if RNA is >= v2.3.4' );
