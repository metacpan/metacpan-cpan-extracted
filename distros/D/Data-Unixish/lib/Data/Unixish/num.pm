package Data::Unixish::num;

use 5.010;
use locale;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);
use Number::Format;
use Number::Format::Metric qw(format_metric);
use POSIX qw(locale_h);
use Scalar::Util 'looks_like_number';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-23'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.573'; # VERSION

our %SPEC;

my %styles = (
    general    => 'General formatting, e.g. 1, 2.345',
    fixed      => 'Fixed number of decimal digits, e.g. 1.00, default decimal digits=2',
    scientific => 'Scientific notation, e.g. 1.23e+21',
    kilo       => 'Use K/M/G/etc suffix with base-2, e.g. 1.2M',
    kibi       => 'Use Ki/Mi/GiB/etc suffix with base-10 [1000], e.g. 1.2Mi',
    percent    => 'Percentage, e.g. 10.00%',
    # XXX fraction
    # XXX currency?
);

# XXX negative number -X or (X)
# XXX colorize negative number?
# XXX leading zeros/spaces

$SPEC{num} = {
    v => 1.1,
    summary => 'Format number',
    description => <<'_',

Observe locale environment variable settings.

Undef and non-numbers are ignored.

_
    args => {
        %common_args,
        style => {
            schema=>['str*', in=>[keys %styles], default=>'general'],
            cmdline_aliases => { s=>{} },
            pos => 0,
            description => "Available styles:\n\n".
                join("", map {" * $_  ($styles{$_})\n"} sort keys %styles),
        },
        decimal_digits => {
            schema => ['int*'],
            summary => 'Number of digits to the right of decimal point',
        },
        thousands_sep => {
            summary => 'Use a custom thousand separator character',
            description => <<'_',

Default is from locale (e.g. dot "." for en_US, etc).

Use empty string "" if you want to disable printing thousands separator.

_
            schema => ['str*'],
        },
        prefix => {
            summary => 'Add some string at the beginning (e.g. for currency)',
            schema => ['str*'],
        },
        suffix => {
            summary => 'Add some string at the end (e.g. for unit)',
            schema => ['str*'],
        },
    },
    tags => [qw/formatting itemfunc datatype:num/],
};
sub num {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    my $orig_locale = _num_begin(\%args);
    while (my ($index, $item) = each @$in) {
        push @$out, _num_item($item, \%args);
    }
    _num_end(\%args, $orig_locale);

    [200, "OK"];
}

sub _num_begin {
    my $args = shift;

    $args->{style} //= 'general';
    $args->{style} = 'general' if !$styles{$args->{style}};

    $args->{prefix} //= "";
    $args->{suffix} //= "";
    $args->{decimal_digits} //=
        ($args->{style} eq 'kilo' || $args->{style} eq 'kibi' ? 1 : 2);

    my $orig_locale = setlocale(LC_ALL);
    if ($ENV{LC_NUMERIC}) {
        setlocale(LC_NUMERIC, $ENV{LC_NUMERIC});
    } elsif ($ENV{LC_ALL}) {
        setlocale(LC_ALL, $ENV{LC_ALL});
    } elsif ($ENV{LANG}) {
        setlocale(LC_ALL, $ENV{LANG});
    }

    # args abused to store object/state
    my %nfargs;
    if (defined $args->{thousands_sep}) {
        $nfargs{THOUSANDS_SEP} = $args->{thousands_sep};
    }
    $args->{_nf} = Number::Format->new(%nfargs);

    return $orig_locale;
}

sub _num_item {
    my ($item, $args) = @_;

    {
        last if !defined($item) || !looks_like_number($item);
        my $nf      = $args->{_nf};
        my $style   = $args->{style};
        my $decdigs = $args->{decimal_digits};

        if ($style eq 'fixed') {
            $item = $nf->format_number($item, $decdigs, $decdigs);
        } elsif ($style eq 'scientific') {
            $item = sprintf("%.${decdigs}e", $item);
        } elsif ($style eq 'kilo') {
            my $res = format_metric($item, {base=>2, return_array=>1});
            $item = $nf->format_number($res->[0], $decdigs, $decdigs) .
                $res->[1];
        } elsif ($style eq 'kibi') {
            my $res = format_metric(
                $item, {base=>10, return_array=>1});
            $item = $nf->format_number($res->[0], $decdigs, $decdigs) .
                $res->[1];
        } elsif ($style eq 'percent') {
            $item = sprintf("%.${decdigs}f%%", $item*100);
        } else {
            # general
            $item = $nf->format_number($item);
        }
        $item = "$args->{prefix}$item$args->{suffix}";
    }
    return $item;
}

sub _num_end {
    my ($args, $orig_locale) = @_;
    setlocale(LC_ALL, $orig_locale);
}

1;
# ABSTRACT: Format number

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::num - Format number

=head1 VERSION

This document describes version 1.573 of Data::Unixish::num (from Perl distribution Data-Unixish), released on 2023-09-23.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([num => {style=>"fixed"}], 0, 10, -2, 34.5, [2], {}, "", undef);
 # => ("0.00", "10.00", "-2.00", "34.50", [2], {}, "", undef)

In command line:

 % echo -e "1\n-2\n" | LANG=id_ID dux num -s fixed --format=text-simple
 1,00
 -2,00

=head1 FUNCTIONS


=head2 num

Usage:

 num(%args) -> [$status_code, $reason, $payload, \%result_meta]

Format number.

Observe locale environment variable settings.

Undef and non-numbers are ignored.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<decimal_digits> => I<int>

Number of digits to the right of decimal point.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<prefix> => I<str>

Add some string at the beginning (e.g. for currency).

=item * B<style> => I<str> (default: "general")

Available styles:

=over

=item * fixed  (Fixed number of decimal digits, e.g. 1.00, default decimal digits=2)

=item * general  (General formatting, e.g. 1, 2.345)

=item * kibi  (Use Ki/Mi/GiB/etc suffix with base-10 [1000], e.g. 1.2Mi)

=item * kilo  (Use K/M/G/etc suffix with base-2, e.g. 1.2M)

=item * percent  (Percentage, e.g. 10.00%)

=item * scientific  (Scientific notation, e.g. 1.23e+21)

=back

=item * B<suffix> => I<str>

Add some string at the end (e.g. for unit).

=item * B<thousands_sep> => I<str>

Use a custom thousand separator character.

Default is from locale (e.g. dot "." for en_US, etc).

Use empty string "" if you want to disable printing thousands separator.


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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

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

This software is copyright (c) 2023, 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
