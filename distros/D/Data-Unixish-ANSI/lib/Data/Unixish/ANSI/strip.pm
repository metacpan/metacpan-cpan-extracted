package Data::Unixish::ANSI::strip;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any::IfLOG '$log';

use Data::Unixish::Util qw(%common_args);
use Text::ANSI::Util qw(ta_strip);

our %SPEC;

$SPEC{strip} = {
    v => 1.1,
    summary => 'Strip ANSI codes (colors, etc) from text',
    args => {
        %common_args,
    },
    tags => [qw/text ansi itemfunc/],
};
sub strip {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    while (my ($index, $item) = each @$in) {
        push @$out, _strip_item($item);
    }

    [200, "OK"];
}

sub _strip_item {
    my $item = shift;
    {
        last if !defined($item) || ref($item);
        $item = ta_strip($item);
    }
    return $item;
}

1;
# ABSTRACT: Strip ANSI codes (colors, etc) from text

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::ANSI::strip - Strip ANSI codes (colors, etc) from text

=head1 VERSION

This document describes version 0.08 of Data::Unixish::ANSI::strip (from Perl distribution Data-Unixish-ANSI), released on 2017-07-10.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 $stripped = lduxl('ANSI::strip', "\e[1mblah"); # "blah"

In command line:

 % echo -e "\e[1mHELLO";                   # text will appear in bold
 % echo -e "\e[1mHELLO" | dux ANSI::strip; # text will appear normal
 HELLO

=head1 FUNCTIONS


=head2 strip

Usage:

 strip(%args) -> [status, msg, result, meta]

Strip ANSI codes (colors, etc) from text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish-ANSI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish-ansi>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish-ANSI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
