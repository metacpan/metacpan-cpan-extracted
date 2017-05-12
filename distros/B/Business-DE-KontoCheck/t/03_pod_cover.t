# $Id: 24_pod_cover.t,v 1.5 2006/10/02 16:09:19 tinita Exp $
use blib; # for development

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 2;
# thanks to mark, at least HTC::Utils is covered...
pod_coverage_ok( "Business::DE::Konto", "Business::DE::Konto is covered");
pod_coverage_ok( "Business::DE::KontoCheck", "Business::DE::KontoCheck is covered");

