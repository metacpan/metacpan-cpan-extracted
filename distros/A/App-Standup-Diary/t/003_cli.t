use v5.28.0;
use Test2::V0;
use Test::Cmd;
use strict;
use warnings;

my $test = Test::Cmd->new( prog => 'script/diary --help', workdir => '' );
$test->run();

todo 'mbtiny does not want to do that' => sub {
    # We just make sure it can run
    like $test->stdout, qr/See also perldoc Standup::Diary/, 'standard out';
};

done_testing();
