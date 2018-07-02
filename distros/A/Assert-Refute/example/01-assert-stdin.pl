#!/usr/bin/perl

use strict;
use warnings;

=pod

This is really a stupid example.
It reads (string, int, int) triads from STDIN and applies simple rules to them:

=over

=item * string must be a valid identifier;

=item * it must be unique;

=item * first int must be nonzero;

=item * second int must be divisible by the first one.

=back

If these conditions are met, a value is added to a global hash
that is printed at the end.

=cut

# This imports Test::More sibling subs
#    use qw(:core) or just omit the argument to keep namespace clean
use Assert::Refute qw(:all), { on_fail => 'carp' };

my %list;
while (<>) {
    # vital checks are NOT what Refute is for
    /^\s*#/ and next;
    /\S/ or next;
    /(\w+)\s+(\d+)\s+(\d+)/ or do {
        warn "Format is: <name> <number> <n x number>";
        next;
    };

    my ($name, $base, $product) = ($1, $2, $3);

    # String parsed, GO!

    # This issues a warning if conditions aren't met
    my $report = try_refute {
        # Can copy these to a Test::More script, *verbatim*
        # You'll still need Assert::Refute for refute (antonym of ok) though
        like $name, qr/^[a-z][a-z_0-9]*$/i, "Name is an identifier";
        refute $list{$name}, "Value not set for name";
        ok $base, "Base is nonzero";
        ok !($product % $base), "Product divides base"
            if $base;
    };

    # Where I work there wouldn't be such a conditional because
    #     THE SHOW MUST GO ON
    # Nevertheless, a warning helps to know when to expect
    #     angry customer knocking at office door
    $list{$name} = $product/$base
        if $report->is_passing;
};

# Print results - only integers there
print "$_: $list{$_}\n" for sort keys %list;

