package App::IPUtils;

our $DATE = '2016-10-18'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to IP address',
};

my %common_args = (
    args => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'arg',
        schema => ['array*', of=>'str*'],
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

$SPEC{is_ipv4} = {
    v => 1.1,
    summary => "Check if arguments are IPv4 addresses",
    args => {
        %common_args,
    },
    examples => [
        {
            summary => 'Single argument',
            args => {args=>['127.0.0.1']},
        },
        {
            summary => 'Single argument (2)',
            args => {args=>['255.255.255.256']},
        },
        {
            summary => 'Multiple arguments',
            args => {args=>['127.0.0.1', '255.255.255.256']},
        },
    ],
};
sub is_ipv4 {
    require Regexp::IPv4;

    my %args = @_;
    my $args = $args{args};

    my $re = qr/\A$Regexp::IPv4::IPv4_re\z/;

    my @rows;
    for my $arg (@$args) {
        push @rows, {
            arg => $arg,
            is_ipv4 => $arg =~ $re ? 1:0,
        };
    }

    if (@rows > 1) {
        [200, "OK", \@rows, {'table.fields' => [qw/arg is_ipv4/]}];
    } else {
        [200, "OK", $rows[0]{is_ipv4},
         {'cmdline.exit_code' => $rows[0]{is_ipv4} ? 0:1}];
    }
}

$SPEC{is_ipv6} = {
    v => 1.1,
    summary => "Check if arguments are IPv6 addresses",
    args => {
        %common_args,
    },
    examples => [
        {
            summary => 'Single argument',
            args => {args=>['::1']},
        },
        {
            summary => 'Single argument (2)',
            args => {args=>['x']},
        },
        {
            summary => 'Multiple arguments',
            args => {args=>['::1', '127.0.0.1', 'x']},
        },
    ],
};
sub is_ipv6 {
    require Regexp::IPv6;

    my %args = @_;
    my $args = $args{args};

    my $re = qr/\A$Regexp::IPv6::IPv6_re\z/;

    my @rows;
    for my $arg (@$args) {
        push @rows, {
            arg => $arg,
            is_ipv6 => $arg =~ $re ? 1:0,
        };
    }

    if (@rows > 1) {
        [200, "OK", \@rows, {'table.fields' => [qw/arg is_ipv6/]}];
    } else {
        [200, "OK", $rows[0]{is_ipv6},
         {'cmdline.exit_code' => $rows[0]{is_ipv6} ? 0:1}];
    }
}

$SPEC{is_ip} = {
    v => 1.1,
    summary => "Check if arguments are IP (v4 or v6) addresses",
    args => {
        %common_args,
    },
    examples => [
        {
            summary => 'Single argument',
            args => {args=>['::1']},
        },
        {
            summary => 'Single argument (2)',
            args => {args=>['x']},
        },
        {
            summary => 'Multiple arguments',
            args => {args=>['::1', '127.0.0.1', 'x']},
        },
    ],
};
sub is_ip {
    require Regexp::IPv4;
    require Regexp::IPv6;

    my %args = @_;
    my $args = $args{args};

    my $re_v4 = qr/\A$Regexp::IPv4::IPv4_re\z/;
    my $re_v6 = qr/\A$Regexp::IPv6::IPv6_re\z/;

    my @rows;
    for my $arg (@$args) {
        my $is_ipv4 = $arg =~ $re_v4 ? 1:0;
        my $is_ipv6 = $arg =~ $re_v6 ? 1:0;
        push @rows, {
            arg => $arg,
            is_ipv4 => $is_ipv4,
            is_ipv6 => $is_ipv6,
            is_ip   => $is_ipv4 || $is_ipv6 ? 1:0,
        };
    }

    if (@rows > 1) {
        [200, "OK", \@rows,
         {'table.fields' => [qw/arg is_ipv4 is_ipv6 is_ip/]}];
    } else {
        [200, "OK", $rows[0]{is_ip},
         {'cmdline.exit_code' => $rows[0]{is_ip} ? 0:1}];
    }
}

1;
# ABSTRACT: Utilities related to IP address

__END__

=pod

=encoding UTF-8

=head1 NAME

App::IPUtils - Utilities related to IP address

=head1 VERSION

This document describes version 0.001 of App::IPUtils (from Perl distribution App-IPUtils), released on 2016-10-18.

=head1 DESCRIPTION

This distribution includes several utilities:

=over

=item * L<is-ip>

=item * L<is-ipv4>

=item * L<is-ipv6>

=back

=head1 FUNCTIONS


=head2 is_ip(%args) -> [status, msg, result, meta]

Check if arguments are IP (v4 or v6) addresses.

Examples:

=over

=item * Single argument:

 is_ip(args => ["::1"]); # -> [200, "OK", 1, { "cmdline.exit_code" => 0 }]

=item * Single argument (2):

 is_ip(args => ["x"]); # -> [200, "OK", 0, { "cmdline.exit_code" => 1 }]

=item * Multiple arguments:

 is_ip(args => ["::1", "127.0.0.1", "x"]);

Result:

 [
   200,
   "OK",
   [
     { arg => "::1", is_ipv4 => 0, is_ipv6 => 1, is_ip => 1 },
     { arg => "127.0.0.1", is_ipv4 => 1, is_ipv6 => 0, is_ip => 1 },
     { arg => "x", is_ipv4 => 0, is_ipv6 => 0, is_ip => 0 },
   ],
   { "table.fields" => ["arg", "is_ipv4", "is_ipv6", "is_ip"] },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 is_ipv4(%args) -> [status, msg, result, meta]

Check if arguments are IPv4 addresses.

Examples:

=over

=item * Single argument:

 is_ipv4(args => ["127.0.0.1"]); # -> [200, "OK", 1, { "cmdline.exit_code" => 0 }]

=item * Single argument (2):

 is_ipv4(args => ["255.255.255.256"]); # -> [200, "OK", 0, { "cmdline.exit_code" => 1 }]

=item * Multiple arguments:

 is_ipv4(args => ["127.0.0.1", "255.255.255.256"]);

Result:

 [
   200,
   "OK",
   [
     { arg => "127.0.0.1", is_ipv4 => 1 },
     { arg => "255.255.255.256", is_ipv4 => 0 },
   ],
   { "table.fields" => ["arg", "is_ipv4"] },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 is_ipv6(%args) -> [status, msg, result, meta]

Check if arguments are IPv6 addresses.

Examples:

=over

=item * Single argument:

 is_ipv6(args => ["::1"]); # -> [200, "OK", 1, { "cmdline.exit_code" => 0 }]

=item * Single argument (2):

 is_ipv6(args => ["x"]); # -> [200, "OK", 0, { "cmdline.exit_code" => 1 }]

=item * Multiple arguments:

 is_ipv6(args => ["::1", "127.0.0.1", "x"]);

Result:

 [
   200,
   "OK",
   [
     { arg => "::1", is_ipv6 => 1 },
     { arg => "127.0.0.1", is_ipv6 => 0 },
     { arg => "x", is_ipv6 => 0 },
   ],
   { "table.fields" => ["arg", "is_ipv6"] },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args>* => I<array[str]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-IPUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-IPUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-IPUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
