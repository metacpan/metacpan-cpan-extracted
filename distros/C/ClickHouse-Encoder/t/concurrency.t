use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use Digest::SHA qw(sha1_hex);
use Config;

plan skip_all => 'fork not available on this perl'
    unless $Config{d_fork} && $Config{d_fork} eq 'define';

# Verify the encoder has no shared mutable state between processes:
# fork N children, each encodes the same input M times, hash the output,
# parent compares. Drift -> shared globals or unsafe statics.

my $N_CHILDREN = 4;
my $N_ENCODES  = 50;

my @cols = (
    ['id',    'UInt64'],
    ['user',  'String'],
    ['tags',  'Array(String)'],
    ['score', 'Nullable(Float64)'],
    ['stamp', 'DateTime'],
);
my @rows = map { [$_, "u$_", ['x','y',"r$_"], $_ % 5 ? rand(100) : undef, 1700000000+$_] }
    1 .. 200;

# Reference hash from the parent before forking.
my $parent_enc = ClickHouse::Encoder->new(columns => \@cols);
my $reference  = sha1_hex($parent_enc->encode(\@rows));

my @kids;
for my $i (1 .. $N_CHILDREN) {
    pipe(my $r, my $w) or die "pipe: $!";
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $r;
        my $enc = ClickHouse::Encoder->new(columns => \@cols);
        my $stable = 1;
        for (1 .. $N_ENCODES) {
            $stable = 0 if sha1_hex($enc->encode(\@rows)) ne $reference;
        }
        print $w $stable ? "OK\n" : "DRIFT\n";
        close $w;
        exit 0;
    }
    close $w;
    push @kids, [$pid, $r];
}

my $all_ok = 1;
for my $kid (@kids) {
    my ($pid, $r) = @$kid;
    my $line = <$r>;
    waitpid($pid, 0);
    chomp $line if defined $line;
    is($line, 'OK', "child $pid produces stable encoding");
    $all_ok &&= (defined $line && $line eq 'OK');
}

ok($all_ok, "$N_CHILDREN children x $N_ENCODES encodes all match reference");

done_testing();
