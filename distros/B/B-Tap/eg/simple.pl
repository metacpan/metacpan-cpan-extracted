use 5.014000;
use Devel::CodeObserver;
use Data::Dumper;

my $dat = {
    x => {
        y => 0,
    },
    z => {
        m => [
            +{
                n => 3
            }
        ]
    }
};

my $tracer = Devel::CodeObserver->new();
my ($retval, $result) = $tracer->call(sub { $dat->{z}->{m}[0]{n} eq 4 ? 1 : 0 });
print "RETVAL: $retval\n";
for my $pair (@{$result->dump_pairs}) {
    my ($code, $val) = @$pair;
    print "$code => $val\n";
}
