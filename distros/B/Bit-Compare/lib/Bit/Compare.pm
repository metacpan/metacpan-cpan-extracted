use strict;
use warnings;
package Bit::Compare;
{
  $Bit::Compare::VERSION = '0.001';
}
#ABSTRACT: Compare two "bit strings", returning differing bits

use Sub::Exporter -setup => {
    exports => [ qw/bitcompare bit/ ],
    groups => {
        default => [ qw/bitcompare/ ],
    },
};


sub bitcompare {
    if (@_ == 3) {
        shift; # remove class/package to support old calling forms
    }
    my ($s1, $s2) = @_;
    $s1 = bit($s1);
    $s2 = bit($s2);
    return unless ($s1 and $s2);
    my $v = "" . join("", unpack("c*", $s1 ^ $s2));
    $v =~ s/0//g;

    return length($v);
}


sub bit {
    my ($s) = @_;
    return unless defined $s;
    my @a;
    foreach (split(/(.{2})/, $s)) {
        next unless length("$_") > 0;
        my $v = hex($_);
        my $b = unpack("B*", pack("C",$v));
        if (length("$_") == 1) {
            $b = substr($b, -4);
        }
        push(@a, split(//, $b));
    }
    return (wantarray ? @a : join("", @a));
}

1;

__END__
=pod

=head1 NAME

Bit::Compare - Compare two "bit strings", returning differing bits

=head1 VERSION

version 0.001

=head3 bitcompare $s1, $s2

Returns the number of bits that are different between $s1 and $s2.

=head3 bit $string

Converts $string from hex to integer, and to bit pattern, and returns
as an array

=head1 AUTHOR

Andreas Marienborg <andremar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

