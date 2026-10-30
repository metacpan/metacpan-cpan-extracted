use v5.40;
use blib;
use Acme::Parataxis qw[async yield await fiber];
use Test2::V1 -ipP;
$|++;
#
subtest 'Resume after nested spawn' => sub {
    my $out = '';
    async {
        fiber {1};
        yield;
        $out = 'done';
    };
    is $out, 'done', 'fiber completed its body after yield following a nested spawn';
};
subtest 'Spawn and await in the same fiber, then yield' => sub {
    my @log;
    async {
        my $child = fiber {1};
        my $r     = await($child);
        push @log, "child=$r";
        yield;
        push @log, 'parent-done';
    };
    is "@log", 'child=1 parent-done', 'resumed fiber saw both its nested result and the post-yield continuation';
};
#
done_testing();
