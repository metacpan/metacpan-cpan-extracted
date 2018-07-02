#!/usr/bin/env perl

=pod

Although there are better data validation tools for perl,
L<Assert::Refute> can do this, providing a summary of detected discrepancies.

This example shows some stupid data format.

The same validation rules may be applied to incoming data (as here)
or output of some function in either production or unit-test.

Expected input is JSON (and the script dies unless it's technically correct).
This will pass validation:

    {"number":42,"complete":true,"users":[{"id":137,"name":"fine"}]}

Omitting required keys, adding extra ones, and changing the format
of the existing ones will cause a failed test and a more detailed summary.

=cut

use strict;
use warnings;
use JSON;

# mute try_refute as we're going to print TAP anyway
use Assert::Refute qw(:all), {on_fail => 'skip', on_pass => 'skip'};
use Assert::Refute::T::Array;
use Assert::Refute::T::Hash;

# Just read JSON without much precaution
my $data = do {
    local $/;
    my $content = <>;
    die $! unless defined $content;
    exit unless $content =~ /\S/; # skip missing input
    decode_json( $content );
};

my $report = try_refute {
    # keys_are \%hash, \@required, \@optional
    keys_are $data, [qw[users number]], [qw[complete]], "Hash keys";

    # values_are \%hash, \%rules
    values_are $data, {
        number   => qr/^-?\d+(\.\d+)?$/,
        users    => sub {
            # the first argument is NOT the report being returned - it's subtest!
            my ($rep, $array) = @_;

            # array_of \@array, $regex|CODEREF
            array_of $array, sub {
                # Another subtest here, $_ is localized to array element
                like $_->{id}, qr/^\d+$/, "id present";
                like $_->{name}, qr/^\w+([ -]\w+)*$/, "Name in expected format";
            };
        },
    };
    like $data->{complete}, qr/^[01]$/, "Complete is [01]"
        if exists $data->{complete};
};

# examine returned summary
print $report->get_tap;
exit !$report->is_passing;
