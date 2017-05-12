use strict;
use warnings;
use Test::More tests => 3;

for my $test (qw/t::Create t::MoveFile t::MoveDir/){
    subtest $test => sub {
        eval "require $test" or die;
        $test->new->main;
    };
}
