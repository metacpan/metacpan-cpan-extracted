use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

BEGIN {
    use_ok 'Badge::Depot::Plugin::Githubactions';
}

my $badge = Badge::Depot::Plugin::Githubactions->new(user => 'testuser', workflow => 'myflow', _meta => { repo => 'testrepo' });

is $badge->to_html,
   '<a href="https://github.com/testuser/testrepo/actions?query=workflow%3Amyflow"><img src="https://img.shields.io/github/workflow/status/testuser/testrepo/myflow" alt="Build status at Github" /></a>',
   'Correct html';


$badge = Badge::Depot::Plugin::Githubactions->new(user => 'testuser', workflow => 'myflow', branch => 'build-branch', _meta => { repo => 'testrepo' });

is $badge->to_html,
   '<a href="https://github.com/testuser/testrepo/actions?query=workflow%3Amyflow+branch%3Abuild-branch"><img src="https://img.shields.io/github/workflow/status/testuser/testrepo/myflow/build-branch" alt="Build status at Github" /></a>',
   'Correct html';

done_testing;
