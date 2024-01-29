package Data::Unixish::bool;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use utf8;
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-23'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.573'; # VERSION

our %SPEC;

sub _is_true {
    my ($val, $notion) = @_;

    if ($notion =~ /^n1/) {
        return undef unless defined($val); ## no critic: Subroutines::ProhibitExplicitReturnUndef
        return 0 if ref($val) eq 'ARRAY' && !@$val;
        return 0 if ref($val) eq 'HASH'  && !keys(%$val);
        if ($notion =~ /\+.*en(\z|_)/) {
            return undef if $val =~ /^(undef|undefined|null|)$/i; ## no critic: Subroutines::ProhibitExplicitReturnUndef
            return 0 if $val =~ /^(no|n|false|f)$/i;
            return 1;
        } elsif ($notion =~ /\+.*id(\z|_)/) {
            return undef if $val =~ /^(null|kosong|)$/i; ## no critic: Subroutines::ProhibitExplicitReturnUndef
            return 0 if $val =~ /^(tidak|tdk|t|salah|s|bukan)$/i;
            return 1;
        } else {
            return $val ? 1:0;
        }
    } else {
        # perl
        return undef unless defined($val); ## no critic: Subroutines::ProhibitExplicitReturnUndef
        return $val ? 1:0;
    }
}

my %styles = (
    one_zero          => ['1', '0'],
    t_f               => ['t', 'f'],
    true_false        => ['true', 'false'],
    y_n               => ['y', 'n'],
    Y_N               => ['Y', 'N'],
    yes_no            => ['yes', 'no'],
    v_X               => ['v', 'X'],
    check             => ['✓', ' ', 'uses Unicode'],
    check_cross       => ['✓', '✕', 'uses Unicode'],
    heavy_check_cross => ['✔', '✘', 'uses Unicode'],
    dot               => ['●', ' ', 'uses Unicode'],
    dot_cross         => ['●', '✘', 'uses Unicode'],

);

$SPEC{bool} = {
    v => 1.1,
    summary => 'Format boolean',
    description => <<'_',

_
    args => {
        %common_args,
        style => {
            schema=>[str => in=>[keys %styles], default=>'one_zero'],
            description => "Available styles:\n\n".
                join("", map {" * $_" . ($styles{$_}[2] ? " ($styles{$_}[2])":"").": $styles{$_}[1] $styles{$_}[0]\n"} sort keys %styles),
            cmdline_aliases => { s=>{} },
        },
        true_char => {
            summary => 'Instead of style, you can also specify character for true value',
            schema=>['str*'],
            cmdline_aliases => { t => {} },
        },
        false_char => {
            summary => 'Instead of style, you can also specify character for true value',
            schema=>['str*'],
            cmdline_aliases => { f => {} },
        },
        notion => {
            summary => 'What notion to use to determine true/false',
            schema => [str => in=>[qw/perl n1 n1+en n1+id n1+en_id/], default => 'n1+en_id'],
            description => <<'_',

`perl` uses Perl notion.

`n1` (for lack of better name) is just like Perl notion, but empty array and
empty hash is considered false.

`n1+en_id` is like `n1` but also handle 'Yes', 'No', 'true', 'false', etc
(English) and 'ya', 'tidak', etc (Indonesian).

TODO: add Ruby, Python, PHP, JavaScript, etc notion.

_
        },
        # XXX: flag to ignore references
    },
    tags => [qw/datatype:bool itemfunc formatting/],
};
sub bool {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    _bool_begin(\%args);
    while (my ($index, $item) = each @$in) {
        push @$out, _bool_item($item, \%args);
    }

    [200, "OK"];
}

sub _bool_begin {
    my $args = shift;

    $args->{notion} //= 'n1+en_id';
    $args->{style}  //= 'one_zero';
    $args->{style} = 'one_zero' if !$styles{$args->{style}};

    $args->{true_char}  //= $styles{$args->{style}}[0];
    $args->{false_char} //= $styles{$args->{style}}[1];
}

sub _bool_item {
    my ($item, $args) = @_;

    my $t = _is_true($item, $args->{notion});
    $t ? $args->{true_char} : defined($t) ? $args->{false_char} : undef;
}

1;
# ABSTRACT: Format boolean

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::bool - Format boolean

=head1 VERSION

This document describes version 1.573 of Data::Unixish::bool (from Perl distribution Data-Unixish), released on 2023-09-23.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([bool => {style=>"check_cross"}], [0, "one", 2, ""])
 # => ("✕","✓","✓","✕")

In command line:

 % echo -e "0\none\n2\n\n" | dux bool -s y_n --format=text-simple
 n
 y
 y
 n

=head1 FUNCTIONS


=head2 bool

Usage:

 bool(%args) -> [$status_code, $reason, $payload, \%result_meta]

Format boolean.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<false_char> => I<str>

Instead of style, you can also specify character for true value.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<notion> => I<str> (default: "n1+en_id")

What notion to use to determine trueE<sol>false.

C<perl> uses Perl notion.

C<n1> (for lack of better name) is just like Perl notion, but empty array and
empty hash is considered false.

C<n1+en_id> is like C<n1> but also handle 'Yes', 'No', 'true', 'false', etc
(English) and 'ya', 'tidak', etc (Indonesian).

TODO: add Ruby, Python, PHP, JavaScript, etc notion.

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<style> => I<str> (default: "one_zero")

Available styles:

=over

=item * Y_N: N Y

=item * check (uses Unicode):   ✓

=item * check_cross (uses Unicode): ✕ ✓

=item * dot (uses Unicode):   ●

=item * dot_cross (uses Unicode): ✘ ●

=item * heavy_check_cross (uses Unicode): ✘ ✔

=item * one_zero: 0 1

=item * t_f: f t

=item * true_false: false true

=item * v_X: X v

=item * y_n: n y

=item * yes_no: no yes

=back

=item * B<true_char> => I<str>

Instead of style, you can also specify character for true value.


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
