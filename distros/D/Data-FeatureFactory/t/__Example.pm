package Data::FeatureFactory::Example;

use strict;
use utf8;
use base qw(Data::FeatureFactory);

our @features = (
    { name => 'first_vowel', 'values' => [qw/a e i o u y/], format => 'binary' },
    { name => 'num_vowels', type => 'integer', label => 'novals' },
    { name => 'first_digit', type => 'integer', range => '0 .. 9', label => 'onnums' },
    { name => 'digit_avg', type => 'numeric', range => '0 .. 9', label => [qw(novals onnums)] },
    { name => 'capped', type => 'boolean' },
    { name => 'parity', type => 'cat', 'values' => [qw(even odd)], default => 'nan', format => 'normal', label => 'onnums' },
    { name => 'letter1', values_file => 'lcletters.txt', postproc => sub { uc $_[0] }, default => '_', code => \&letter, label => 'long' },
    { name => 'letter2', values_file => 'lcletters.txt', default => '_', code => \&letter, label => 'long' },
    { name => 'id', postproc => sub { lc $_[0] }, label => 'novals' },
);

sub first_vowel {
    my ($v) = lc($_[0]) =~ /([aeiouy])/i;
    return $v
}

sub num_vowels {
    my @v = $_[0] =~ /([aeiouy])/ig;
    return scalar @v
}

sub first_digit {
    my ($d) = $_[0] =~ /(\d)/;
    return $d
}

sub digit_avg {
    my @digits = $_[0] =~ /(\d)/g;
    return undef if @digits == 0;
    my $sum = 0;
    $sum += $_ for @digits;
    return $sum / @digits
}

sub capped {
    return undef if $_[0] =~ /^[^[:alpha:]]/;
    return $_[0] =~ /^[[:upper:]]/ ? 1 : 0
}

sub parity {
    return '' if $_[0] =~ /\D/;
    return $_[0] % 2 ? 'odd' : 'even'
}

sub letter {
    $Data::FeatureFactory::CURRENT_FEATURE =~ /(\d)$/;
    my $p = $1 - 1;
    return lc substr $_[0], $p, 1
}

sub id {
    return $_[0]
}

1
