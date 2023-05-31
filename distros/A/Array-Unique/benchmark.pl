#!/usr/bin/perl
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);

my @a = 'aaaa' .. 'bbbb';  # 18,280 words;
my $value = "bbbb";



#print scalar @a;
#exit;

sub ina {
    my $value = shift;
    #my $ar = shift;

    return scalar grep {$value eq $_} @_;
}

sub ina2($\@) {
    my $value = shift;
    my $ar = shift;

    foreach my $v (@$ar) {
	return 1 if ($v eq $value);
    }
    return 0;
}


print ina($value, @a),"\n";
print ina2($value, @a),"\n";
print scalar grep({$value eq $_} @a), "\n";
foreach my $v (@a) {
    if ($v eq $value) {
	print "Ok\n";
	last;
    }
}

timethese(1000000, {
    ina => q(ina($value, @a)),
    ina2 => q(ina($value, @a)),
    ina3 => q(scalar grep {$value eq $_} @a),
    ina4 => q|foreach my $v (@a) { last if ($v eq $value)}|,
});

