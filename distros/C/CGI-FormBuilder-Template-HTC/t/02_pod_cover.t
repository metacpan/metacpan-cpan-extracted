# $Id: 02_pod_cover.t,v 1.1 2006/11/21 22:08:09 tinita Exp $
use blib; # for development

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "CGI::FormBuilder::Template::HTC", "CGI::FormBuilder::Template::HTC is covered");

