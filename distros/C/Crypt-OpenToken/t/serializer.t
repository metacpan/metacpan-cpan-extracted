#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests => 12;
use Test::Differences;
use Crypt::OpenToken::Serializer;

###############################################################################
# TEST: simple key/value pair
simple: {
    my %data = (
        'key' => 'value',
    );
    my $serialized = "key = value\n";

    # Freeze
    my $frozen = Crypt::OpenToken::Serializer::freeze(%data);
    eq_or_diff $frozen, $serialized, 'simple key/value pair; freeze';

    # Thaw
    my %thawed = Crypt::OpenToken::Serializer::thaw($serialized);
    eq_or_diff \%thawed, \%data, 'simple key/value pair; thaw';
}

###############################################################################
# TEST: freeze key w/multiple values
key_with_multiple_values: {
    my %data = (
        'key' => [qw( one two three )],
    );
    my $serialized
        = "key = one\n"
        . "key = two\n"
        . "key = three\n";

    # Freeze
    my $frozen = Crypt::OpenToken::Serializer::freeze(%data);
    is $frozen, $serialized, 'key w/multiple values; freeze';

    # Thaw
    my %thawed = Crypt::OpenToken::Serializer::thaw($serialized);
    eq_or_diff \%thawed, \%data, 'key w/multiple values; thaw';
}

###############################################################################
# TEST: multiple key/value pairs
multiple_key_value_pairs: {
    my %data = (
        'one'   => 'first',
        'two'   => 'second',
    );
    my $serialized
        = "one = first\n"
        . "two = second\n";

    # Freeze
    my $frozen = Crypt::OpenToken::Serializer::freeze(%data);
    is $frozen, $serialized, 'multiple key/value pairs; freeze';

    # Thaw
    my %thawed = Crypt::OpenToken::Serializer::thaw($serialized);
    eq_or_diff \%thawed, \%data, 'multiple key/value pairs; thaw';
}

###############################################################################
# TEST: values containing quotes
values_containing_quotes: {
    my %data = (
        key => qq{this ain't got "quotes" in it. double-negative!},
    );
    my $serialized
        = qq{key = 'this ain\\'t got \\"quotes\\" in it. double-negative!'\n};

    # Freeze
    my $frozen = Crypt::OpenToken::Serializer::freeze(%data);
    is $frozen, $serialized, 'value requiring quoting; freeze';

    # Thaw
    my %thawed = Crypt::OpenToken::Serializer::thaw($serialized);
    eq_or_diff \%thawed, \%data, 'value requiring quoting; thaw';
}

###############################################################################
# TEST: values spanning multiple lines
multi_line_values: {
    my %data = (
        a => 'one line',
        b => "two\nlines",
        c => "trailing\nwhitespace ",
        d => "whew!",
    );
    my $serialized
        = "a = 'one line'\n"
        . "b = 'two\nlines'\n"
        . "c = 'trailing\nwhitespace '\n"
        . "d = 'whew!'\n";

    # Freeze
    my $frozen = Crypt::OpenToken::Serializer::freeze(%data);
    is $frozen, $serialized, 'multi-line values; freeze';

    # Thaw
    my %thawed = Crypt::OpenToken::Serializer::thaw($serialized);
    eq_or_diff \%thawed, \%data, 'multi-line values; thaw';
}

###############################################################################
# TEST: empty/blank values
empty_or_blank_values: {
    my %data = (
        bar => '',
        foo => 'foobar',
    );
    my $serialized
        = "bar = \n"
        . "foo = foobar\n";

    # Freeze
    my $frozen = Crypt::OpenToken::Serializer::freeze(%data);
    is $frozen, $serialized, 'empty/blank values; freeze';

    # Thaw
    my %thawed = Crypt::OpenToken::Serializer::thaw($serialized);
    eq_or_diff \%thawed, \%data, 'empty/blank values; thaw';
}
