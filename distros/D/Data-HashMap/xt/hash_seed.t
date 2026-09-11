use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);


my @inc = map { "-I$_" } grep { !ref } @INC;

my ($fh, $child) = tempfile(UNLINK => 1);
print {$fh} <<'CHILD';
use Data::HashMap::SS;
my $m = Data::HashMap::SS->new;
$m->put("k$_", 1) for 1 .. 16;
my @order;
while (my ($k) = $m->each) { push @order, $k }
print join(",", @order), "\n";
CHILD
close $fh;

sub order_from_child {
    my (%env) = @_;
    local %ENV = (%ENV, %env);
    my $out = `$^X @inc $child`;
    chomp $out;
    die "child produced no output\n" unless length $out;
    return $out;
}

{
    my %seen;
    $seen{ order_from_child() }++ for 1 .. 6;
    cmp_ok scalar(keys %seen), '>', 1, 'slot order varies between processes';
}

{
    my %seen;
    $seen{ order_from_child(PERL_HASH_SEED => '0') }++ for 1 .. 3;
    is scalar(keys %seen), 1, 'PERL_HASH_SEED=0 pins slot order across processes';
}

done_testing;
