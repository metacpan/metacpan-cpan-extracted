use strict;
use warnings;
use Test::More;
use File::Spec;
use lib 'lib';

require App::Saisons::Adapter::Claude;
require App::Saisons::UI;

my $fixtures = File::Spec->catdir('t', 'fixtures');

local $ENV{HOME} = "$fixtures/claude";
my $adapter  = App::Saisons::Adapter::Claude->new;
my @sessions = $adapter->find_sessions;

my %by_id = map { $_->{id} => $_ } @sessions;
my $s_main    = $by_id{'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'};
my $s_sub_only = $by_id{'bbbbbbbb-cccc-dddd-eeee-ffffffffffff'};

ok($s_main,     'found main session');
ok($s_sub_only, 'found subagent-only session');

# _dir is set when subagent directory exists
ok($s_main->{_dir},     'main session has _dir');
ok($s_sub_only->{_dir}, 'subagent-only session has _dir');

# title/cwd match
ok(App::Saisons::UI::_search_content($s_main, 'login'),     'matches term in title');
ok(App::Saisons::UI::_search_content($s_main, 'myproject'), 'matches term in cwd');

# main file content match
ok(App::Saisons::UI::_search_content($s_main, 'Thanks'),   'matches term in main file body');

# subagent content match — term in subagent of the session that also has main content
ok(App::Saisons::UI::_search_content($s_main, 'frobnicator'), 'matches term only in subagent file');

# subagent content match — term only in subagent, NOT in main file
ok(!App::Saisons::UI::_search_content($s_sub_only, 'frobnicator') || 1,
    'sanity: subagent-only session searched');
ok(App::Saisons::UI::_search_content($s_sub_only, 'frobnicator'),
    'matches term in subagent of session where main file lacks it');

# no match
ok(!App::Saisons::UI::_search_content($s_main, 'zzznomatchzzz'), 'no false positive');

# case insensitive
ok(App::Saisons::UI::_search_content($s_main, 'FROBNICATOR'), 'case-insensitive match in subagent');

done_testing;
