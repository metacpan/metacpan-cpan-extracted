package App::CrockfordBase32Utils;

use 5.010001;
use strict 'subs', 'vars';
use utf8;
use warnings;
use Log::ger;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-01-19'; # DATE
our $DIST = 'App-CrockfordBase32Utils'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(
                       num_to_cfbase32
                       cfbase32_to_num
                       cfbase32_encode
                       cfbase32_decode
                       cfbase32_rand
               );

our %SPEC;

$SPEC{num_to_cfbase32} = {
    v => 1.1,
    summary => "Convert integer decimal number(s) to Crockford's Base 32 encoding",
    args => {
        nums => {
            schema => ['array*', of=>'int*'],
            pos => 0,
            slurpy => 1,
        },
    },
};
sub num_to_cfbase32 {
    require Encode::Base32::Crockford;

    my %args = @_;
    my $nums;
    defined($nums = $args{nums}) && @$nums or return [400, "Please specify one or more numbers"];

    my @res;
    for my $num (@{ $nums }) {
        $num = int($num);
        push @res, Encode::Base32::Crockford::base32_encode($num);
    }
    [200, "OK", \@res];
}

$SPEC{cfbase32_to_num} = {
    v => 1.1,
    summary => "Convert Crockford's Base 32 encoding to integer decimal number",
    args => {
        strs => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            slurpy => 1,
        },
    },
};
sub cfbase32_to_num {
    require Encode::Base32::Crockford;

    my %args = @_;
    my $strs;
    defined($strs = $args{strs}) && @$strs or return [400, "Please specify one or more Base32 encoded strings"];

    my @res;
    for my $str (@{ $strs }) {
        push @res, Encode::Base32::Crockford::base32_decode($str);
    }
    [200, "OK", \@res];
}

$SPEC{cfbase32_encode} = {
    v => 1.1,
    summary => "Encode string to Crockford's Base32 encoding",
    args => {
        str => {
            schema => 'str*',
            pos => 0,
            cmdline_src => 'stdin_or_files',
        },
    },
};
sub cfbase32_encode {
    require Convert::Base32::Crockford;

    my %args = @_;
    my $str = $args{str};

    [200, "OK", Convert::Base32::Crockford::encode_base32($str)];
}

$SPEC{cfbase32_decode} = {
    v => 1.1,
    summary => "Decode Crockford's Base32 encoding",
    args => {
        str => {
            schema => 'str*',
            pos => 0,
            cmdline_src => 'stdin_or_files',
        },
    },
};
sub cfbase32_decode {
    require Convert::Base32::Crockford;

    my %args = @_;
    my $str = $args{str};
    $str =~ s/[^A-TV-Z0-9]+//ig;

    [200, "OK", Convert::Base32::Crockford::decode_base32($str)];
}

my @cfbase32_digits = qw(0 1 2 3 4 5 6 7 8 9
                         A B C D E F G H J K
                         M N P Q R S T V W X Y Z);
my @cfbase32_digits_x0 = qw(1 2 3 4 5 6 7 8 9
                            A B C D E F G H J K
                            M N P Q R S T V W X Y Z);
sub _gen_rand_cfbase32 {
    my ($min_len, $max_len, $zero_prefix) = @_;
    my $len = int($min_len + rand()*($max_len - $min_len + 1));

    my @digits;
    for my $i (1..$len) {
        my $digit;
        if ($i == 1 && !$zero_prefix) {
            $digit = $cfbase32_digits_x0[rand @cfbase32_digits_x0];
        } else {
            $digit = $cfbase32_digits[rand @cfbase32_digits];
        }
        push @digits, $digit;
    }
    join "", @digits;
}

$SPEC{cfbase32_rand} = {
    v => 1.1,
    summary => "Generate one or more Crockford Base 32 numbers",
    args => {
        zero_prefix => {
            schema => 'bool*',
            default => 1,
            summary => 'When generating random number of certain length range, whether the first digit is allowed to be zero',
        },
        min_int => {
            schema => 'int*',
            tags => ['category:range'],
        },
        max_int => {
            schema => 'int*',
            tags => ['category:range'],
        },
        min_base32 => {
            schema => 'str*',
            tags => ['category:range'],
        },
        max_base32 => {
            schema => 'str*',
            tags => ['category:range'],
        },
        min_len => {
            summary => 'Specify how many minimum number of digits to generate',
            description => <<'MARKDOWN',

Note that the first digit can still be 0 unless zero_prefix is set to false.

MARKDOWN
            schema => ['int*', min=>1],
            tags => ['category:range'],
        },
        max_len => {
            summary => 'Specify how many maximum number of digits to generate',
            description => <<'MARKDOWN',

Note that the first digit can still be 0 unless zero_prefix is set to false.

MARKDOWN
            schema => ['int*', min=>1],
            tags => ['category:range'],
        },
        len => {
            summary => 'Specify how many number of digits to generate for a number',
            description => <<'MARKDOWN',

Note that the first digit can still be 0 unless zero_prefix is set to false.

MARKDOWN
            schema => ['int*', min=>1],
            tags => ['category:range'],
        },

        num => {
            summary => 'Specify how many numbers to generate',
            schema => 'uint*',
            default => 1,
            cmdline_aliases => {n=>{}},
            tags => ['category:quantity'],
        },

        unique => {
            schema => 'bool*',
            summary => 'Whether to avoid generating previously generated numbers',
        },
        prev_nums_file => {
            schema => 'filename*',
        },
    },
    args_rels => {
        'choose_all&' => [
            [qw/from_int to_int/],
            [qw/from_base32 to_base32/],
            [qw/from_digits to_digits/],
        ],
        req_one => [
            qw/min_int min_base32 min_len len/,
        ],
    },
    examples => [
        {
            summary => 'Generate 5 random numbers from 12 digits each, first digit(s) can be 0',
            argv => [qw/--len 12 -n35/],
            test => 0,
        },
        {
            summary => 'Generate 5 random numbers from 12 digits each, first digit(s) CANNOT be 0',
            argv => [qw/--len 12 -n35 --nozero-prefix/],
            test => 0,
        },
    ],
};
sub cfbase32_rand {
    require Encode::Base32::Crockford;

    my %args = @_;
    my ($gen, $from, $to, $fmt);
    if ($args{len}) {
        if ($args{len} >= 9) {
            $gen = sub { _gen_rand_cfbase32($args{len}, $args{len}, $args{zero_prefix}) };
        } else {
            $from = 32 ** ($args{len} - 1);
            $to = 32 ** ($args{len}) - 1;
        }
    } elsif (defined($args{min_len})) {
        if ($args{min_len} >= 9 || $args{max_len} >= 9) {
            $gen = sub { _gen_rand_cfbase32($args{min_len}, $args{max_len}, $args{zero_prefix}) };
        } else {
            $from = 32 ** int($args{min_len} - 1);
            $to   = 32 ** int($args{max_len}) - 1;
        }
    } elsif (defined($args{min_int})) {
        $from = int($args{min_int});
        $to   = int($args{max_int});
    } elsif (defined($args{min_base32})) {
        $from = Encode::Base32::Crockford::base32_decode($args{min_base32});
        $to   = Encode::Base32::Crockford::base32_decode($args{max_base32});
    } else {
        return [400, "Please specify range"];
    }
    log_trace "from: %s   to: %s", $from, $to;

    my @res;
    for my $i (1 .. $args{num}) {
        my $enc;
        if ($gen) {
            $enc = $gen->();
        } else {
            my $num = int(rand() * ($to - $from + 1) + $from);
            $enc = Encode::Base32::Crockford::base32_encode($num);
        }
        push @res, $enc;
    }

    [200, "OK", \@res];
}

1;
# ABSTRACT: Utilities related to Crockford's Base 32 encoding

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CrockfordBase32Utils - Utilities related to Crockford's Base 32 encoding

=head1 VERSION

This document describes version 0.002 of App::CrockfordBase32Utils (from Perl distribution App-CrockfordBase32Utils), released on 2026-01-19.

=head1 DESCRIPTION

This distribution contains the following CLIs:

=over

=item * L<cfbase32-decode>

=item * L<cfbase32-encode>

=item * L<cfbase32-rand>

=item * L<cfbase32-to-num>

=item * L<num-to-cfbase32>

=back

Keywords: base32, base 32, crockford's base 32

=head1 FUNCTIONS


=head2 cfbase32_decode

Usage:

 cfbase32_decode(%args) -> [$status_code, $reason, $payload, \%result_meta]

Decode Crockford's Base32 encoding.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<str> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 cfbase32_encode

Usage:

 cfbase32_encode(%args) -> [$status_code, $reason, $payload, \%result_meta]

Encode string to Crockford's Base32 encoding.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<str> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 cfbase32_rand

Usage:

 cfbase32_rand(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate one or more Crockford Base 32 numbers.

Examples:

=over

=item * Generate 5 random numbers from 12 digits each, first digit(s) can be 0:

 cfbase32_rand(len => 12, num => 35);

Result:

 [
   200,
   "OK",
   [
     "S19WAC3HG0RW",
     "DBD7KC1Z4R2S",
     "FNJE31GGWXHC",
     "5Y8BTWC4V387",
     "AQK25BFF9J2T",
     "J1X3YT947R2K",
     "3R4GFCKM36CC",
     "SK3X0X75SEMP",
     "15F8XWJ6SK61",
     "9TP7F5TCCJKF",
     "4RWYJX2PKJ3Q",
     "WCP48G44QQ69",
     "XCKAN0WSQ193",
     "EG3SCKG3H7E9",
     "X6NNHSMXHYSP",
     "884AZ0BBZRZ8",
     "GEFT3K6N5Y4P",
     "K8J6DBJG60FF",
     "T4ZPJRFPT8QQ",
     "HPTG7CJ4EZTB",
     "Z3V9PPW27K5Z",
     "YB3MQP9NVTB2",
     "Z04PXT0ZW58Z",
     "19G8YRFPNFBC",
     "03J3DT1813ZR",
     "9RWQVT6F1JXM",
     "EP58YN26H7VY",
     "A892VRX7FR6N",
     "PFAP10YVEM4V",
     "W2EAP0F9SZH4",
     "83P4TPXVEEZF",
     "NEC8VT2S7B78",
     "3RR7D7HWKF6P",
     "VYREC7Q7XT62",
     "C2WHFKM3FYMJ",
   ],
   {},
 ]

=item * Generate 5 random numbers from 12 digits each, first digit(s) CANNOT be 0:

 cfbase32_rand(len => 12, num => 35, zero_prefix => 0);

Result:

 [
   200,
   "OK",
   [
     "1GKRJ5V7GSRS",
     "HNA0SBZYSJRF",
     "YVVNS31GAWSZ",
     "S2G0FGM6HGAB",
     "VZ4M8K2Y6EQD",
     "S2KNNJSBP412",
     "YQSEX35KJ3JR",
     "T0CGK19AXF13",
     "YNDHTFQCH8NB",
     "G1N75MYAC0V8",
     "77N3N0DPB4C2",
     "X874R7QT425Y",
     "Z0YYYK3X9Q6C",
     "Q3GYF41BFRZG",
     "49P8QC6Z28QS",
     "NR700A3SA79M",
     "Q3N82TWHM3H4",
     "92EN559RSSR4",
     "VSDH8B1SQRFF",
     "BR1WQX6GGRK8",
     "C1R69F0K196H",
     "G7AZZVN7DF6A",
     "G9V8BSMF0205",
     "VM6VGG8VMXMK",
     "8W2VBFFN1ZZY",
     "1K6N6Y997XPQ",
     "5H5MWPN8VTEW",
     "3BC87J5W3M1N",
     "3EYXJGFYBCQS",
     "BHR03PMWYZ7Q",
     "K7NT926VG8JV",
     "K4PC04BZ2DPM",
     "J34K0VBWQ3QZ",
     "J24C00NMT8A2",
     "8R3PJ910J6CN",
   ],
   {},
 ]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<len> => I<int>

Specify how many number of digits to generate for a number.

Note that the first digit can still be 0 unless zero_prefix is set to false.

=item * B<max_base32> => I<str>

(No description)

=item * B<max_int> => I<int>

(No description)

=item * B<max_len> => I<int>

Specify how many maximum number of digits to generate.

Note that the first digit can still be 0 unless zero_prefix is set to false.

=item * B<min_base32> => I<str>

(No description)

=item * B<min_int> => I<int>

(No description)

=item * B<min_len> => I<int>

Specify how many minimum number of digits to generate.

Note that the first digit can still be 0 unless zero_prefix is set to false.

=item * B<num> => I<uint> (default: 1)

Specify how many numbers to generate.

=item * B<prev_nums_file> => I<filename>

(No description)

=item * B<unique> => I<bool>

Whether to avoid generating previously generated numbers.

=item * B<zero_prefix> => I<bool> (default: 1)

When generating random number of certain length range, whether the first digit is allowed to be zero.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 cfbase32_to_num

Usage:

 cfbase32_to_num(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert Crockford's Base 32 encoding to integer decimal number.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strs> => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 num_to_cfbase32

Usage:

 num_to_cfbase32(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert integer decimal number(s) to Crockford's Base 32 encoding.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<nums> => I<array[int]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CrockfordBase32Utils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CrockfordBase32Utils>.

=head1 SEE ALSO

L<https://www.crockford.com/base32.html>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CrockfordBase32Utils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
