package Data::Unixish::sprintf;

use 5.010;
use locale;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);
use POSIX qw(locale_h);
use Scalar::Util 'looks_like_number';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-23'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.573'; # VERSION

our %SPEC;

$SPEC{sprintf} = {
    v => 1.1,
    summary => 'Apply sprintf() on input',
    description => <<'_',

Array will also be processed (all the elements are fed to sprintf(), the result
is a single string), unless `skip_array` is set to true.

Non-numbers can be skipped if you use `skip_non_number`.

Undef, hashes, and other non-scalars are ignored.

_
    args => {
        %common_args,
        format => {
            schema=>['str*'],
            cmdline_aliases => { f=>{} },
            req => 1,
            pos => 0,
        },
        skip_non_number => {
            schema=>[bool => default=>0],
        },
        skip_array => {
            schema=>[bool => default=>0],
        },
    },
    tags => [qw/formatting itemfunc text/],
};
sub sprintf {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});
    my $format = $args{format};

    my $orig_locale = _sprintf_begin();

    while (my ($index, $item) = each @$in) {
        push @$out, _sprintf_item($item, \%args);
    }

    _sprintf_end(\%args, $orig_locale);

    [200, "OK"];
}

sub _sprintf_begin {
    my $orig_locale = setlocale(LC_ALL);
    if ($ENV{LC_NUMERIC}) {
        setlocale(LC_NUMERIC, $ENV{LC_NUMERIC});
    } elsif ($ENV{LC_ALL}) {
        setlocale(LC_ALL, $ENV{LC_ALL});
    } elsif ($ENV{LANG}) {
        setlocale(LC_ALL, $ENV{LANG});
    }
    return $orig_locale;
}

sub _sprintf_end {
    my ($args, $orig_locale) = @_;
    setlocale(LC_ALL, $orig_locale);
}

sub _sprintf_item {
    my ($item, $args) = @_;

    {
        last unless defined($item);

        my $r = ref($item);
        if ($r eq 'ARRAY' && !$args->{skip_array}) {
            no warnings;
            $item = CORE::sprintf($args->{format}, @$item);
            last;
        }
        last if $r;
        last if $item eq '';
        last if !looks_like_number($item) && $args->{skip_non_number};
        {
            no warnings;
            $item = CORE::sprintf($args->{format}, $item);
        }
    }
    return $item;
}

1;
# ABSTRACT: Apply sprintf() on input

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::sprintf - Apply sprintf() on input

=head1 VERSION

This document describes version 1.573 of Data::Unixish::sprintf (from Perl distribution Data-Unixish), released on 2023-09-23.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([sprintf => {format=>"%.1f"}], 0, 1, [2], {}, "", undef);
 # => ("0.0", "1.0", "2.0", {}, "", undef)

In command line:

 % echo -e "0\n1\n\nx\n" | dux sprintf -f "%.1f" --skip-non-number --format=text-simple
 0.0
 1.0

 x

=head1 FUNCTIONS


=head2 sprintf

Usage:

 sprintf(%args) -> [$status_code, $reason, $payload, \%result_meta]

Apply sprintf() on input.

Array will also be processed (all the elements are fed to sprintf(), the result
is a single string), unless C<skip_array> is set to true.

Non-numbers can be skipped if you use C<skip_non_number>.

Undef, hashes, and other non-scalars are ignored.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<format>* => I<str>

(No description)

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<skip_array> => I<bool> (default: 0)

(No description)

=item * B<skip_non_number> => I<bool> (default: 0)

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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

=head1 SEE ALSO

printf(1)

L<Data::Unixish::sprintfn>

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
