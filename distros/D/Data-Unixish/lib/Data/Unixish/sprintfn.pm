package Data::Unixish::sprintfn;

use 5.010;
use locale;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);
use POSIX qw(locale_h);
use Scalar::Util 'looks_like_number';
use Text::sprintfn ();

our $VERSION = '1.570'; # VERSION

our %SPEC;

$SPEC{sprintfn} = {
    v => 1.1,
    summary => 'Like sprintf, but use sprintfn() from Text::sprintfn',
    description => <<'_',

Unlike in *sprintf*, with this function, hash will also be processed.

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
        skip_hash => {
            schema=>[bool => default=>0],
        },
    },
    tags => [qw/formatting itemfunc text/],
};
sub sprintfn {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    my $orig_locale = _sprintfn_begin(\%args);
    while (my ($index, $item) = each @$in) {
        push @$out, _sprintfn_item($item, \%args);
    }
    _sprintfn_end(\%args, $orig_locale);

    [200, "OK"];
}

sub _sprintfn_begin {
    my $args = shift;

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

sub _sprintfn_item {
    my ($item, $args) = @_;

    {
        last unless defined($item);
        my $r = ref($item);
        if ($r eq 'ARRAY' && !$args->{skip_array}) {
            no warnings;
            $item = Text::sprintfn::sprintfn($args->{format}, @$item);
            last;
        }
        if ($r eq 'HASH' && !$args->{skip_hash}) {
            no warnings;
            $item = Text::sprintfn::sprintfn($args->{format}, $item);
            last;
        }
        last if $r;
        last if $item eq '';
        last if !looks_like_number($item) && $args->{skip_non_number};
        {
            no warnings;
            $item = Text::sprintfn::sprintfn($args->{format}, $item);
        }
    }
    return $item;
}

sub _sprintfn_end {
    my ($args, $orig_locale) = @_;
    setlocale(LC_ALL, $orig_locale);
}

1;
# ABSTRACT: Like sprintf, but use sprintfn() from Text::sprintfn

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::sprintfn - Like sprintf, but use sprintfn() from Text::sprintfn

=head1 VERSION

This document describes version 1.570 of Data::Unixish::sprintfn (from Perl distribution Data-Unixish), released on 2019-01-06.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([sprintfn => {format=>"%(n).1f"}], {n=>1}, {n=>2}, "", undef);
 # => ("1.0", "2.0", "", undef)

=head1 FUNCTIONS


=head2 sprintfn

Usage:

 sprintfn(%args) -> [status, msg, payload, meta]

Like sprintf, but use sprintfn() from Text::sprintfn.

Unlike in I<sprintf>, with this function, hash will also be processed.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<format>* => I<str>

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<skip_array> => I<bool> (default: 0)

=item * B<skip_hash> => I<bool> (default: 0)

=item * B<skip_non_number> => I<bool> (default: 0)

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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Unixish::sprintf>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
