package App::BloomUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'App-BloomUtils'; # DIST
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use POSIX qw(ceil);

our %SPEC;

my $desc1 = <<'_';

You supply lines of text from STDIN and it will output the bloom filter bits on
STDOUT. You can also customize `num_bits` (`m`) and `num_hashes` (`k`), or, more
easily, `num_items` and `fp_rate`. Some rules of thumb to remember:

* One byte per item in the input set gives about a 2% false positive rate. So if
  you expect two have 1024 elements, create a 1KB bloom filter with about 2%
  false positive rate. For other false positive rates:

    10%    -  4.8 bits per item
     1%    -  9.6 bits per item
     0.1%  - 14.4 bits per item
     0.01% - 19.2 bits per item

* Optimal number of hash functions is 0.7 times number of bits per item. Note
  that the number of hashes dominate performance. If you want higher
  performance, pick a smaller number of hashes. But for most cases, use the the
  optimal number of hash functions.

* What is an acceptable false positive rate? This depends on your needs. 1% (1
  in 100) or 0.1% (1 in 1,000) is a good start. If you want to make sure that
  user's chosen password is not in a known wordlist, a higher false positive
  rates will annoy your user more by rejecting her password more often, while
  lower false positive rates will require a higher memory usage.

Ref: https://corte.si/posts/code/bloom-filter-rules-of-thumb/index.html

**FAQ**

* Why does two different false positive rates (e.g. 1% and 0.1%) give the same bloom filter size?

  The parameter `m` is rounded upwards to the nearest power of 2 (e.g. 1024*8
  bits becomes 1024*8 bits but 1025*8 becomes 2048*8 bits), so sometimes two
  false positive rates with different `m` get rounded to the same value of `m`.
  Use the `bloom_filter_calculator` routine to see the `actual_m` and `actual_p`
  (actual false-positive rate).

_

$SPEC{gen_bloom_filter} = {
    v => 1.1,
    summary => 'Generate bloom filter',
    description => $desc1,
    args => {
        num_bits => {
            description => <<'_',

The default is 16384*8 bits (generates a ~16KB bloom filter). If you supply 16k
items (meaning 1 byte per 1 item) then the false positive rate will be ~2%. If
you supply fewer items the false positive rate is smaller and if you supply more
than 16k items the false positive rate will be higher.

_
            schema => 'posint*',
            #default => 8*16384,
            cmdline_aliases => {m=>{}},
        },
        num_hashes => {
            schema => 'posint*',
            cmdline_aliases => {k=>{}},
            #default => 6,
        },
        num_items => {
            schema => 'posint*',
            cmdline_aliases => {n=>{}},
        },
        false_positive_rate => {
            schema => ['float*', max=>0.5],
            cmdline_aliases => {
                fp_rate => {},
                p => {},
            },
        },
    },
    'cmdline.skip_format' => 1,
    args_rels => {
    },
    examples => [
        {
            summary => 'Create a bloom filter for 100k items and 0.1% maximum false-positive rate '.
                '(actual bloom size and false-positive rate will be shown on stderr)',
            argv => [qw/--num-items 100000 --fp-rate 0.1%/],
            'x.doc.show_result' => 0,
            test => 0,
        },
    ],
    links => [
        {url=>'prog:bloom-filter-calculator'},
    ],
};
sub gen_bloom_filter {
    require Algorithm::BloomFilter;

    my %args = @_;

    my $res;
    if (defined $args{num_items}) {
        $res = bloom_filter_calculator(
            num_items => $args{num_items},
            num_bits => $args{num_bits},
            num_hashes => $args{num_hashes},
            false_positive_rate => $args{false_positive_rate},
            num_hashes_to_bits_per_item_ratio => 0.7,
        );
    } else {
        $res = bloom_filter_calculator(
            num_bits => $args{num_bits} // 16384*8,
            num_hashes => $args{num_hashes} // 6,

            num_items => int($args{num_bits} / 8),
        );
    }
    return $res unless $res->[0] == 200;
    my $m = $args{num_bits} // $res->[2]{actual_m};
    my $k = $args{num_hashes} // $res->[2]{actual_k};
    log_info "Will be creating bloom filter with num_bits (m)=%d (actual %d), num_hashes (k)=%d, actual false-positive rate=%.5f%% (when num_items=%d), actual bloom filter size=%d bytes",
        $m, $res->[2]{actual_m}, $k, $res->[2]{actual_p}*100, $res->[2]{n}, $res->[2]{actual_bloom_size};

    my $bf = Algorithm::BloomFilter->new($m, $k);
    my $i = 0;
    while (defined(my $line = <STDIN>)) {
        chomp $line;
        $bf->add($line);
        $i++;
        if (defined $args{num_items} && $i == $args{num_items}+1) {
            log_warn "You created bloom filter for num_items=%d, but now have added more than that", $args{num_items};
        }
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
    description => $desc1,
    args => {
        num_items => {
            summary => 'Expected number of items to add to bloom filter',
            schema => 'posint*',
            pos => 0,
            req => 1,
            cmdline_aliases => {n=>{}},
        },
        num_bits => {
            summary => 'Number of bits to set for the bloom filter',
            schema => 'posint*',
            cmdline_aliases => {m=>{}},
        },
        false_positive_rate => {
            schema => ['float*', max=>0.5],
            default => 0.02,
            cmdline_aliases => {
                fp_rate => {},
                p => {},
            },
        },
        num_hashes => {
            schema => 'posint*',
            cmdline_aliases => {k=>{}},
        },
        num_hashes_to_bits_per_item_ratio => {
            summary => '0.7 (the default) is optimal',
            schema => 'num*',
        },
    },
    args_rels => {
        'choose_one&' => [
            [qw/num_hashes num_hashes_to_bits_per_item_ratio/],
        ],
    },
};
sub bloom_filter_calculator {
    require Algorithm::BloomFilter;

    my %args = @_;

    my $num_hashes_to_bits_per_item_ratio = $args{num_hashes_to_bits_per_item_ratio};
    $num_hashes_to_bits_per_item_ratio //= 0.7 unless defined($args{num_bits}) && defined($args{num_items});

    my $num_items = $args{num_items};
    my $fp_rate   = $args{false_positive_rate} // 0.02;
    my $num_bits = $args{num_bits} // ($num_items * log(1/$fp_rate)/ log(2)**2);

    my $num_bits_per_item = $num_bits / $num_items;
    my $num_hashes = $args{num_hashes} //
        (defined $num_hashes_to_bits_per_item_ratio ? $num_hashes_to_bits_per_item_ratio*$num_bits_per_item : undef) //
        ($num_bits / $num_items * log(2));
    $num_hashes_to_bits_per_item_ratio //= $num_hashes / $num_bits_per_item;

    my $actual_num_hashes = ceil($num_hashes);

    my $bloom = Algorithm::BloomFilter->new($num_bits, $actual_num_hashes);
    my $actual_bloom_size = length($bloom->serialize);
    my $actual_num_bits = ($actual_bloom_size - 3)*8;
    my $actual_fp_rate = (1 - exp(-$actual_num_hashes*$num_items/$actual_num_bits))**$actual_num_hashes;

    [200, "OK", {
        num_bits   => $num_bits,
        m          => $num_bits,

        num_items  => $num_items,
        n          => $num_items,

        num_hashes => $num_hashes,
        k          => $num_hashes,

        num_hashes_to_bits_per_item_ratio => $num_hashes_to_bits_per_item_ratio,

        fp_rate    => $fp_rate,
        p          => $fp_rate,

        num_bits_per_item => $num_bits / $num_items,
        'm/n'             => $num_bits / $num_items,

        actual_num_bits   => $actual_num_bits,
        actual_m          => $actual_num_bits,
        actual_num_hashes => ceil($num_hashes),
        actual_k          => ceil($num_hashes),
        actual_fp_rate    => $actual_fp_rate,
        actual_p          => $actual_fp_rate,
        actual_bloom_size => $actual_bloom_size,
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

This document describes version 0.007 of App::BloomUtils (from Perl distribution App-BloomUtils), released on 2020-05-24.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<bloom-filter-calculator>

=item * L<bloomcalc>

=item * L<bloomchk>

=item * L<bloomgen>

=item * L<check-with-bloom-filter>

=item * L<gen-bloom-filter>

=back

=head1 FUNCTIONS


=head2 bloom_filter_calculator

Usage:

 bloom_filter_calculator(%args) -> [status, msg, payload, meta]

Help calculate num_bits (m) and num_hashes (k).

You supply lines of text from STDIN and it will output the bloom filter bits on
STDOUT. You can also customize C<num_bits> (C<m>) and C<num_hashes> (C<k>), or, more
easily, C<num_items> and C<fp_rate>. Some rules of thumb to remember:

=over

=item * One byte per item in the input set gives about a 2% false positive rate. So if
you expect two have 1024 elements, create a 1KB bloom filter with about 2%
false positive rate. For other false positive rates:

10%    -  4.8 bits per item
 1%    -  9.6 bits per item
 0.1%  - 14.4 bits per item
 0.01% - 19.2 bits per item

=item * Optimal number of hash functions is 0.7 times number of bits per item. Note
that the number of hashes dominate performance. If you want higher
performance, pick a smaller number of hashes. But for most cases, use the the
optimal number of hash functions.

=item * What is an acceptable false positive rate? This depends on your needs. 1% (1
in 100) or 0.1% (1 in 1,000) is a good start. If you want to make sure that
user's chosen password is not in a known wordlist, a higher false positive
rates will annoy your user more by rejecting her password more often, while
lower false positive rates will require a higher memory usage.

=back

Ref: https://corte.si/posts/code/bloom-filter-rules-of-thumb/index.html

B<FAQ>

=over

=item * Why does two different false positive rates (e.g. 1% and 0.1%) give the same bloom filter size?

The parameter C<m> is rounded upwards to the nearest power of 2 (e.g. 1024*8
bits becomes 1024*8 bits but 1025*8 becomes 2048*8 bits), so sometimes two
false positive rates with different C<m> get rounded to the same value of C<m>.
Use the C<bloom_filter_calculator> routine to see the C<actual_m> and C<actual_p>
(actual false-positive rate).

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<false_positive_rate> => I<float> (default: 0.02)

=item * B<num_bits> => I<posint>

Number of bits to set for the bloom filter.

=item * B<num_hashes> => I<posint>

=item * B<num_hashes_to_bits_per_item_ratio> => I<num>

0.7 (the default) is optimal.

=item * B<num_items>* => I<posint>

Expected number of items to add to bloom filter.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 check_with_bloom_filter

Usage:

 check_with_bloom_filter(%args) -> [status, msg, payload, meta]

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
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 gen_bloom_filter

Usage:

 gen_bloom_filter(%args) -> [status, msg, payload, meta]

Generate bloom filter.

Examples:

=over

=item * Create a bloom filter for 100k items and 0.1% maximum false-positive rate (actual bloom size and false-positive rate will be shown on stderr):

 gen_bloom_filter( false_positive_rate => "0.1%", num_items => 100000);

=back

You supply lines of text from STDIN and it will output the bloom filter bits on
STDOUT. You can also customize C<num_bits> (C<m>) and C<num_hashes> (C<k>), or, more
easily, C<num_items> and C<fp_rate>. Some rules of thumb to remember:

=over

=item * One byte per item in the input set gives about a 2% false positive rate. So if
you expect two have 1024 elements, create a 1KB bloom filter with about 2%
false positive rate. For other false positive rates:

10%    -  4.8 bits per item
 1%    -  9.6 bits per item
 0.1%  - 14.4 bits per item
 0.01% - 19.2 bits per item

=item * Optimal number of hash functions is 0.7 times number of bits per item. Note
that the number of hashes dominate performance. If you want higher
performance, pick a smaller number of hashes. But for most cases, use the the
optimal number of hash functions.

=item * What is an acceptable false positive rate? This depends on your needs. 1% (1
in 100) or 0.1% (1 in 1,000) is a good start. If you want to make sure that
user's chosen password is not in a known wordlist, a higher false positive
rates will annoy your user more by rejecting her password more often, while
lower false positive rates will require a higher memory usage.

=back

Ref: https://corte.si/posts/code/bloom-filter-rules-of-thumb/index.html

B<FAQ>

=over

=item * Why does two different false positive rates (e.g. 1% and 0.1%) give the same bloom filter size?

The parameter C<m> is rounded upwards to the nearest power of 2 (e.g. 1024*8
bits becomes 1024*8 bits but 1025*8 becomes 2048*8 bits), so sometimes two
false positive rates with different C<m> get rounded to the same value of C<m>.
Use the C<bloom_filter_calculator> routine to see the C<actual_m> and C<actual_p>
(actual false-positive rate).

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<false_positive_rate> => I<float>

=item * B<num_bits> => I<posint>

The default is 16384*8 bits (generates a ~16KB bloom filter). If you supply 16k
items (meaning 1 byte per 1 item) then the false positive rate will be ~2%. If
you supply fewer items the false positive rate is smaller and if you supply more
than 16k items the false positive rate will be higher.

=item * B<num_hashes> => I<posint>

=item * B<num_items> => I<posint>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
