use strict;
use warnings;
use Test::More;

use App::jl;

my @cases = ({
    opts => ['-X'],
    test => sub {
        ok $_[0]->{xxxxx};
    },
}, {
    opts => ['-g', 'foo'],
    test => sub {
        is $_[0]->{grep}->[0], 'foo'; # grep option is array
    },
}, {
    opts => ['-yml'],
    test => sub {
        ok $_[0]->{yaml};
    },
});

for my $case (@cases) {
    my $opt = App::jl->_parse_opt(@{$case->{opts}});
    $case->{test}->($opt);
}

done_testing;
