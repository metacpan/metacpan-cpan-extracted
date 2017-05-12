use Test::More;

use CallGraph::Lang::Fortran;

my %dump_opts = (
    dups => { dups => 1 },
    nodups => { dups => 0 },
    indent4 => { indent => 4 },
);

my @files = qw(test test_rec );

plan tests => @files * (keys(%dump_opts) + 1);

for my $base (@files) {
    my $graph = CallGraph::Lang::Fortran->new(files => "$base.f");
    isa_ok($graph, "CallGraph::Lang::Fortran");
    for my $dump_opt (sort keys %dump_opts) {
        my $dump = eval {$graph->dump(%{$dump_opts{$dump_opt}});};
        if ($@) { use Data::Dumper; print Dumper $graph; }
        my $fname = "${base}_$dump_opt.txt";
        open F, "<", $fname or die "couldn't open $fname: $!";
        my $expected;
        { local $/ = undef; $expected = <F> }
        is($dump, $expected, "$fname");
    }
}
