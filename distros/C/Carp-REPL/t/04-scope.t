#!perl
use strict;
use warnings;
use Test::More tests => 37;
use Test::Expect;
use lib 't/lib';
use TestHelpers qw(e_value e_defined);

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/04-scope.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/\b2\b/, 'in the REPL');

e_value('$pre_lexical','alpha');
e_value('$pre_global_safe','sheep');
e_value('$inner_lexical','parking');
e_value('$inner_global','to');
e_value('$pre_global','shadow stabbing');
e_value('$post_global','go');
e_value('$main::post_global','go');

e_defined('$post_local',0);
e_defined('$postcall_local',0);
e_defined('$postcall_global',0);
e_defined('$other_lexical',0);

e_value('$other_global','long jacket');
e_value('$main::other_global','long jacket');

e_defined('$birds',0);
e_defined('$window',0);

e_value('$Mr::Mastodon::Farm::birds','fall');

e_defined('$Mr::Mastodon::Farm::window',0);
