package Data::Unixish::indent;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $VERSION = '1.56'; # VERSION

our %SPEC;

$SPEC{indent} = {
    v => 1.1,
    summary => 'Add spaces or tabs to the beginnning of each line of text',
    args => {
        %common_args,
        num => {
            summary => 'Number of spaces to add',
            schema  => ['int*', default=>4],
            cmdline_aliases => {
                n => {},
            },
        },
        tab => {
            summary => 'Number of spaces to add',
            schema  => ['bool' => default => 0],
            cmdline_aliases => {
                t => {},
            },
        },
    },
    tags => [qw/text itemfunc/],
};
sub indent {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    _indent_begin(\%args);
    while (my ($index, $item) = each @$in) {
        push @$out, _indent_item($item, \%args);
    }

    [200, "OK"];
}

sub _indent_begin {
    my $args = shift;

    # args abused to store state
    $args->{_indent} = ($args->{tab} ? "\t" : " ") x ($args->{num} // 4);
}

sub _indent_item {
    my ($item, $args) = @_;

    if (defined($item) && !ref($item)) {
        $item =~ s/^/$args->{_indent}/mg;
    }
    return $item;
}

1;
# ABSTRACT: Add spaces or tabs to the beginnning of each line of text

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::indent - Add spaces or tabs to the beginnning of each line of text

=head1 VERSION

This document describes version 1.56 of Data::Unixish::indent (from Perl distribution Data-Unixish), released on 2017-07-10.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(aduxa);
 my @res = aduxa('indent', "a", " b", "", undef, ["c"]);
 # => ("    a", "     b", "    ", undef, ["c"])

In command line:

 % echo -e "1\n 2" | dux indent -n 2
   1
    2

=head1 FUNCTIONS


=head2 indent

Usage:

 indent(%args) -> [status, msg, result, meta]

Add spaces or tabs to the beginnning of each line of text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<num> => I<int> (default: 4)

Number of spaces to add.

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<tab> => I<bool> (default: 0)

Number of spaces to add.

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

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

lins, rins

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
