use Cwd;
use File::Spec;
my $pwd = cwd();
my @pieces = split /\//, $pwd;
if (-f 'test-common.pl') {
    pop @pieces;
}
elsif (-f 't/test-common.pl') {
}
our $BASE = File::Spec->catdir(@pieces);
our $SAMPLES = File::Spec->catdir($BASE, 't', 'samples');

1;
