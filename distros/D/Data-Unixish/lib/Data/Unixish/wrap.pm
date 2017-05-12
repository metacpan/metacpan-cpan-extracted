package Data::Unixish::wrap;

our $DATE = '2016-03-16'; # DATE
our $VERSION = '1.55'; # VERSION

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);
use Text::ANSI::Util qw(ta_wrap);
use Text::ANSI::WideUtil qw(ta_mbwrap);
use Text::WideChar::Util qw(mbwrap);

our %SPEC;

$SPEC{wrap} = {
    v => 1.1,
    summary => 'Wrap text',
    args => {
        %common_args,
        width => {
            summary => 'Target column width',
            schema =>[int => {default=>80, min=>1}],
            cmdline_aliases => { c=>{} },
            pos => 0,
        },
        ansi => {
            summary => 'Whether to handle ANSI escape codes',
            schema => ['bool', default => 0],
        },
        mb => {
            summary => 'Whether to handle wide characters',
            schema => ['bool', default => 0],
        },
    },
    tags => [qw/text itemfunc/],
};
sub wrap {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    _wrap_begin(\%args);
    while (my ($index, $item) = each @$in) {
        push @$out, _wrap_item($item, \%args);
    }

    [200, "OK"];
}

sub _wrap_begin {
    my $args = shift;
    $args->{width} //= 80;
}

sub _wrap_item {
    my ($item, $args) = @_;
    {
        last if !defined($item) || ref($item);
        if ($args->{ansi}) {
            if ($args->{mb}) {
                $item = ta_mbwrap($item, $args->{width});
            } else {
                $item = ta_wrap  ($item, $args->{width});
            }
        } elsif ($args->{mb}) {
            $item = mbwrap($item, $args->{width});
        } else {
            $item = Text::WideChar::Util::wrap($item, $args->{width});
        }
    }
    return $item;
}

1;
# ABSTRACT: Wrap text

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::wrap - Wrap text

=head1 VERSION

This document describes version 1.55 of Data::Unixish::wrap (from Perl distribution Data-Unixish), released on 2016-03-16.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 $wrapped = lduxl([wrap => {width=>20}], "xxxx xxxx xxxx xxxx xxxx"); # "xxxx xxxx xxxx xxxx\nxxxx"

In command line:

 % echo -e "xxxx xxxx xxxx xxxx xxxx" | dux wrap -c 20
 xxxx xxxx xxxx xxxx
 xxxx

=head1 FUNCTIONS


=head2 wrap(%args) -> [status, msg, result, meta]

Wrap text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ansi> => I<bool> (default: 0)

Whether to handle ANSI escape codes.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<mb> => I<bool> (default: 0)

Whether to handle wide characters.

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<width> => I<int> (default: 80)

Target column width.

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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Data-Unixish>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

fmt(1)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
