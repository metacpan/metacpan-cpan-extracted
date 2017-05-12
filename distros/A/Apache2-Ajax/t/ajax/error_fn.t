########################################################################
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;
use Apache2::Const -compile => qw(OK SERVER_ERROR);

my $module = 'TestAjax::error_fn';
my $path = Apache::TestRequest::module2path($module);

plan tests => 1;

my $res = GET "/$path";
ok t_cmp($res->code, Apache2::Const::SERVER_ERROR, 
	"Server error expected with no perl functions");
