package App::BloomUtils;

our $DATE = '2018-03-23'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{gen_bloom_filter} = {
    v => 1.1,
    summary => 'Generate bloom filter',
    description => <<'_',

You supply lines of text from STDIN and it will output the bloom filter bits on
STDOUT. You can also customize `num_bits` (`m`) and `num_hashes` (`k`). Some
rules of thumb to remember:

* One byte per item in the input set gives about a 2% false positive rate. So if
  you expect two have 1024 elements, create a 1KB bloom filter with about 2%
  false positive rate. For other false positive rates:

    1%    -  9.6 bits per item
    0.1%  - 14.4 bits per item
    0.01% - 19.2 bits per item

* Optimal number of hash functions is 0.7 times number of bits per item.

* What is an acceptable false positive rate? This depends on your needs.

Ref: https://corte.si/posts/code/bloom-filter-rules-of-thumb/index.html

_
    args => {
        num_bits => {
            description => <<'_',

The default is 80000 (generates a ~10KB bloom filter). If you supply 10,000 items
(meaning 1 byte per 1 item) then the false positive rate will be ~2%. If you
supply fewer items the false positive rate is smaller and if you supply more
than 10,000 items the false positive rate will be higher.

_
            schema => 'num*',
            default => 8*10000,
            cmdline_aliases => {m=>{}},
        },
        num_hashes => {
            schema => 'num*',
            cmdline_aliases => {k=>{}},
            default => 5.7,
        },
    },
    'cmdline.skip_format' => 1,
    links => [
        {url=>'prog:bloom-filter-calculator'},
    ],
};
sub gen_bloom_filter {
    require Algorithm::BloomFilter;

    my %args = @_;

    my $m = $args{num_bits};
    my $k = $args{num_hashes};

    my $bf = Algorithm::BloomFilter->new($m, $k);
    while (defined(my $line = <STDIN>)) {
        chomp $line;
        $bf->add($line);
    }

    print $bf->serialize;

    [200];
}

$SPEC{check_with_bloom_filter} = {
    v => 1.1,
    summary => 'Check with bloom filter',
    description => <<'_',

You supply the bloom filter in STDIN, items to check as arguments, and this
utility will print lines containing 0 or 1 depending on whether items in the
arguments are tested to be, respectively, not in the set (0) or probably in the
set (1).

_
    args => {
        items => {
            summary => 'Items to check',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
    'cmdline.skip_format' => 1,
    links => [
    ],
};
sub check_with_bloom_filter {
    require Algorithm::BloomFilter;

    my %args = @_;

    my $bf_str = "";
    while (read(STDIN, my $block, 8192)) {
        $bf_str .= $block;
    }

    my $bf = Algorithm::BloomFilter->deserialize($bf_str);

    for (@{ $args{items} }) {
        say $bf->test($_) ? 1:0;
    }

    [200];
}

$SPEC{bloom_filter_calculator} = {
    v => 1.1,
    summary => 'Help calculate num_bits (m) and num_hashes (k)',
    description => <<'_',

Bloom filter is setup using two parameters: `num_bits` (`m`) which is the size
of the bloom filter (in bits) and `num_hashes` (`k`) which is the number of hash
functions to use which will determine the write and lookup speed.

Some rules of thumb:

* One byte per item in the input set gives about a 2% false positive rate. So if
  you expect two have 1024 elements, create a 1KB bloom filter with about 2%
  false positive rate. For other false positive rates:

    1%    -  9.6 bits per item
    0.1%  - 14.4 bits per item
    0.01% - 19.2 bits per item

* Optimal number of hash functions is 0.7 times number of bits per item.

* What is an acceptable false positive rate? This depends on your needs.

Ref: https://corte.si/posts/code/bloom-filter-rules-of-thumb/index.html

_
    args => {
        num_items => {
            summary => 'Expected number of items to add to bloom filter',
            schema => 'posint*',
            pos => 0,
            req => 1,
            cmdline_aliases => {n=>{}},
        },
        false_positive_rate => {
            schema => 'num*',
            default => 0.02,
            cmdline_aliases => {
                fp_rate => {},
                p => {},
            },
        },
        num_hashes => {
            schema => 'num*',
            cmdline_aliases => {k=>{}},
        },
        num_hashes_to_bits_per_item_ratio => {
            summary => '0.7 (the default) is optimal',
            schema => 'num*',
            default => 0.7,
        },
    },
    args_rels => {
        choose_one => [qw/num_hashes/],
    },
};
sub bloom_filter_calculator {
    my %args = @_;

    my $num_items = $args{num_items};
    my $fp_rate   = $args{false_positive_rate};

    my $num_bits = $num_items * log(1/$fp_rate)/ log(2)**2;
    my $num_hashes = $args{num_hashes} // ($num_bits / $num_items * log(2));

    [200, "OK", {
        num_bits   => $num_bits,
        m          => $num_bits,
        num_items  => $num_items,
        n          => $num_items,
        num_hashes => $num_hashes,
        k          => $num_hashes,
        fp_rate    => $fp_rate,
        p          => $fp_rate,
        num_bits_per_item => $num_bits / $num_items,
        'm/n'             => $num_bits / $num_items,
    }];
}


1;
# ABSTRACT: Utilities related to bloom filters

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BloomUtils - Utilities related to bloom filters

=head1 VERSION

This document describes version 0.002 of App::BloomUtils (from Perl distribution App-BloomUtils), released on 2018-03-23.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<bloom-filter-calculator>

=item * L<check-with-bloom-filter>

=item * L<gen-bloom-filter>

=back

=head1 FUNCTIONS


=head2 bloom_filter_calculator

Usage:

 bloom_filter_calculator(%args) -> [status, msg, result, meta]

Help calculate num_bits (m) and num_hashes (k).

Bloom filter is setup using two parameters: C<num_bits> (C<m>) which is the size
of the bloom filter (in bits) and C<num_hashes> (C<k>) which is the number of hash
functions to use which will determine the write and lookup speed.

Some rules of thumb:

=over

=item * One byte per item in the input set gives about a 2% false positive rate. So if
you expect two have 1024 elements, create a 1KB bloom filter with about 2%
false positive rate. For other false positive rates:

1%    -  9.6 bits per item
0.1%  - 14.4 bits per item
0.01% - 19.2 bits per item

=item * Optimal number of hash functions is 0.7 times number of bits per item.

=item * What is an acceptable false positive rate? This depends on your needs.

=back

Ref: https://corte.si/posts/code/bloom-filter-rules-of-thumb/index.html

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<false_positive_rate> => I<num> (default: 0.02)

=item * B<num_hashes> => I<num>

=item * B<num_hashes_to_bits_per_item_ratio> => I<num> (default: 0.7)

0.7 (the default) is optimal.

=item * B<num_items>* => I<posint>

Expected number of items to add to bloom filter.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 check_with_bloom_filter

Usage:

 check_with_bloom_filter(%args) -> [status, msg, result, meta]

Check with bloom filter.

You supply the bloom filter in STDIN, items to check as arguments, and this
utility will print lines containing 0 or 1 depending on whether items in the
arguments are tested to be, respectively, not in the set (0) or probably in the
set (1).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<items>* => I<array[str]>

Items to check.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 gen_bloom_filter

Usage:

 gen_bloom_filter(%args) -> [status, msg, result, meta]

Generate bloom filter.

You supply lines of text from STDIN and it will output the bloom filter bits on
STDOUT. You can also customize C<num_bits> (C<m>) and C<num_hashes> (C<k>). Some
rules of thumb to remember:

=over

=item * One byte per item in the input set gives about a 2% false positive rate. So if
you expect two have 1024 elements, create a 1KB bloom filter with about 2%
false positive rate. For other false positive rates:

1%    -  9.6 bits per item
0.1%  - 14.4 bits per item
0.01% - 19.2 bits per item

=item * Optimal number of hash functions is 0.7 times number of bits per item.

=item * What is an acceptable false positive rate? This depends on your needs.

=back

Ref: https://corte.si/posts/code/bloom-filter-rules-of-thumb/index.html

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num_bits> => I<num> (default: 80000)

The default is 80000 (generates a ~10KB bloom filter). If you supply 10,000 items
(meaning 1 byte per 1 item) then the false positive rate will be ~2%. If you
supply fewer items the false positive rate is smaller and if you supply more
than 10,000 items the false positive rate will be higher.

=item * B<num_hashes> => I<num> (default: 5.7)

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-BloomUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BloomUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BloomUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<bloom-filter-calculator>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
