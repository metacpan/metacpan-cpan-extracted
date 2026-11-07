#!perl
use 5.010;
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempdir);
use Apophis;

# Each method through its custom op against the same call compiled as an
# ordinary method call, under no Apophis.

my $dir     = tempdir(CLEANUP => 1);
my $ca      = Apophis->new(namespace => 'bench', store_dir => $dir);
my $text    = 'x' x 64;
my $id      = $ca->store(\$text);
my $missing = '00000000-0000-5000-8000-000000000000';

my %op = (
    identify => sub { $ca->identify(\$text) },
    exists   => sub { $ca->exists($id) },
    missing  => sub { $ca->exists($missing) },
    store    => sub { $ca->store(\$text) },
    fetch    => sub { $ca->fetch($id) },
    verify   => sub { $ca->verify($id) },
);

my %sub;
{
    no Apophis;
    %sub = (
        identify => sub { $ca->identify(\$text) },
        exists   => sub { $ca->exists($id) },
        missing  => sub { $ca->exists($missing) },
        store    => sub { $ca->store(\$text) },
        fetch    => sub { $ca->fetch($id) },
        verify   => sub { $ca->verify($id) },
    );
}

for my $case (qw(identify exists missing store fetch verify)) {
    print "\n$case\n";
    cmpthese(-2, { op => $op{$case}, sub => $sub{$case} });
}
