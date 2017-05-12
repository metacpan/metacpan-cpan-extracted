# -*- perl -*-
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

#
# sanity check first -- view
#
my $view = TestApp->view('ByCode');
is ref $view, 'TestApp::View::ByCode', 'View is OK' ;

#
# check if view-config settings can get retrieved
#
can_ok $view, qw(extension root_dir wrapper include);

#
# check if settings are as we expect them to be
#
$view->extension, '.pl', 'unset config is at its default value' ;
$view->root_dir,  'xxroot/xxbycode', 'config setting from View looks good' ;
$view->wrapper,   'xxx.pl', 'config setting from app looks good' ;
is_deeply $view->include, ['List::MoreUtil'], 'app has precedence over view';

done_testing();
