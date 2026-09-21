use v5.40;
use blib;
use Acme::Parataxis qw[async fiber await yield];
use Test2::V1 -ipP;
$|++;
#
subtest 'Join: collect results from spawned fibers' => sub {
    my $p1 = fiber {5};
    my $p2 = fiber { () };
    my $p3 = fiber { ( 0, 1, 2 ) };
    ok !defined await($p2), 'fiber returning () yields undef';
    is await($p1), 5, 'fiber returning 5 yields 5';
    is await($p3), 2, 'fiber returning a list yields its last element (scalar context)';
};
subtest 'Join: fan-out of 20 fibers' => sub {
    my @fs = map {
        my $n = $_;
        fiber { $n * 2 }
    } 1 .. 20;
    my @rs  = map { await($_) } @fs;
    my $sum = 0;
    $sum += $_ for @rs;
    is $sum,       420, 'sum of doubled 1..20';
    is scalar @rs, 20,  'all 20 results collected';
};
subtest 'Join: fibers running side by side inside one scheduler' => sub {
    my @order;
    my @fs;
    async {
        push @fs, fiber { push @order, 'a1'; yield; push @order, 'a2'; return 'A' };
        push @fs, fiber { push @order, 'b1'; yield; push @order, 'b2'; return 'B' };
        push @fs, fiber { push @order, 'c1'; yield; push @order, 'c2'; return 'C' };
    };
    my %result = map { await($_) => $_ } @fs;
    my @done   = sort keys %result;
    is join( q{ }, @done ),  'A B C',             'all three joined';
    is join( q{ }, @order ), 'a1 b1 c1 a2 b2 c2', 'fibers interleaved via yield';
};
#
done_testing();
