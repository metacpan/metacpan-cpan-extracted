#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Catalyst::Test 'TestApp';

# simple stuff
is get('/foo'), 'Welcome to TestApp!', 'simple root action';

# with arguments
is get('/foo/with_args/hello/cthulhu'), 'Hello, Cthulhu!', 'simple argument';
is get('/foo/with_args/at_end/2/3'), 6, 'two arguments at the end';
is get('/foo/with_args/in_the_middle/3/4/end_of_the_middle'), 24, 'two arguments in the middle';
is get('/foo/with_args/4/8/fhtagn/15/16/23/42'), '4, 8, 15, 16, 23, 42', 'complex arguments in both';

# under keyword
is get('/foo/under/23'), 'under 23', 'under as keyword';

# comma separation
is get('/foo/,comma/iaia'), 'iaia', 'comma separation';

# nested under
is get('/foo/lower/down/the/stream'), 'foo/stream', 'nested under blocks';

# action roles
do {
    local $ENV{TESTAPP_ACTIONROLE} = 1;
    is get('/foo/with_role'), 'YES', 'fully named action role works';
};
do {
    local $ENV{TESTAPP_ACTIONROLE} = 0;
    is get('/foo/with_role'), 'NO', 'aliased action role works';
};

# action class
is get('/foo/book/Whatever/view/xml'), 'Page 1 of "Whatever" as XML', 'action class was set';
is get('/foo/book/Fnord/view/html?page=7'), 'Page 7 of "Fnord" as HTML', 'action class was set';

# final keyword
is get('/foo/finals/in_front'), 'foo/in_front', 'final syntax element as declarator';
is get('/foo/finals/final_middle'), 'foo/final_middle', 'final syntax element in the middle';
is get('/foo/finals/final_at_end'), 'foo/final_at_end', 'final syntax element at the end';

# privates
is get('/foo/expose_not_really_here'), 23, 'private action works';

# specify chain target directly via action
is get('/foo/pointed/beaver'), 'Your beaver is pointed!', 'chain target specified via action';

# an action from a role
is get('/foo/action_from_ctrl_role'), 'foo/action_from_ctrl_role', 'action from controller role';

# an action body that was modified
is get('/foo/modifier_target'), 'foo/modifier_target modified', 'action was modified by role';
is get('/foo/surrounded_target'), 'foo/surrounded_target surrounded', 'action was modified with around by role';

# inline classes
is get('/foo/inline_class'), 'HELLO', 'inline classes work as expected';

# error handling
is get('/foo/wants_integer/butdoesntgetone'), 'no integer', 'validation error causes bad request error';

# fix bug with capture args below under { }
is get('/foo/lower/down/the/param/3/road/5'), 8, 'capture args and block under work together';

# Make sure action roles with parameters pass params to attributes
is get('/actionparams/first'), 'action_args_first: 100,101', 'actionrole with params';
is get('/actionparams/second'), 'action_args_second: 200,201', 'actionrole with params (part two)';
is get('/actionparams/third'), 'action_args_third: 300,301', 'actionrole with params (part three)';

is get('/actionparams/forth'), 'action_args_forth: 400,1,401,2', 'actionrole with params (part four)';
is get('/actionparams/first_app_ns'), 'action_args_first: 100,101', 'actionrole with params (from App NS)';
is get('/actionparams/first_cat_ns'), 'action_args_first: 100,101', 'actionrole with params (from Cat NS)';

# Check deep parsing
is get('/actionparams/check_deep'), 'action_args_deep: {a=>1,b=>2}', 'actionrole with deep params';

done_testing;
