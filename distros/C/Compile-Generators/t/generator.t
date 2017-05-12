use Compile::Generators;
use strict;

use Test::More tests => 3;

sub gen_range :generator {
    my ($min, $max) = @_;
    my $num = $min;
    my $incr;

    while (not defined $max or $num < $max) {
        $incr = shift(@_) || 1;
        yield $num;
        $num += $incr;
    }
}

# Test calling two generators from the same sub at the same time.
# Yay!
my $range = gen_range(50, 100);
my $incr = gen_range(1);

my @numbers;
while (my $num = $range->($incr->())) {
    push @numbers, $num;
}

is(join('-', @numbers), '50-51-53-56-60-65-71-78-86-95', "generator works");

ok ((-f 't/generator.tc'), "Compiled file exists");

pass __FILE__;

