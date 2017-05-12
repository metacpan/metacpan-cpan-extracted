use strict;
use warnings;
use Test::More tests => 12;
#use Test::More 'no_plan';

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok 'TestApp' or die }

# Check basic inheritance.
ok my $td = TestApp->view('Appconfig'), 'Get Appconfig view object';
is $td->render(undef, 'test_self'), 'Self is TestApp::Templates::Appconfig',
    'self should be the subclass';

is $td->render(undef, 'test_isa', { what => 'Template::Declare::Catalyst' }),
    'Self is Template::Declare::Catalyst',
    'self should be a Template::Declare::Catalyst';

is $td->render(undef, 'test_isa', { what => 'Template::Declare' }),
    'Self is Template::Declare',
    'self should be a Template::Declare';

# Check auto-aliasing.
ok $td = TestApp->view('HTML'), 'Get HTML view object';
ok $td->auto_alias, 'It should be auto-aliasing';
is $td->render(undef, 'body'), "header\nbody\nfooter\n",
    'Utility templates should be aliased';
is $td->render(undef, 'user/list'), "header\nuser list\nfooter\n",
    'User templates should be aliased under /user';

# Check manual aliasing.
ok $td = TestApp->view('NoAlias'), 'Get NoAlias view object';
ok !$td->auto_alias, 'It should not be auto-aliasing';
is $td->render(undef, 'body'), "header\nbody\nfooter\n",
    'It should have its own utility templates';
