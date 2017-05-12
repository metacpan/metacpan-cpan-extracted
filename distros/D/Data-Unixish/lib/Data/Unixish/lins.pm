package Data::Unixish::lins;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $VERSION = '1.55'; # VERSION

our %SPEC;

$SPEC{lins} = {
    v => 1.1,
    summary => 'Add some text at the beginning of each line of text',
    description => <<'_',

This is sort of a counterpart for ltrim, which removes whitespace at the
beginning (left) of each line of text.

_
    args => {
        %common_args,
        text => {
            summary => 'The text to add',
            schema  => ['str*'],
            req     => 1,
            pos     => 0,
        },
    },
    tags => [qw/text itemfunc/],
};
sub lins {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    while (my ($index, $item) = each @$in) {
        push @$out, _lins_item($item, \%args);
    }

    [200, "OK"];
}

sub _lins_item {
    my ($item, $args) = @_;

    if (defined($item) && !ref($item)) {
        $item =~ s/^/$args->{text}/mg;
    }
    return $item;
}

1;
# ABSTRACT: Add some text at the beginning of each line of text

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::lins - Add some text at the beginning of each line of text

=head1 VERSION

This document describes version 1.55 of Data::Unixish::lins (from Perl distribution Data-Unixish), released on 2016-03-16.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(aduxa);
 my @res = aduxa([lins => {text=>"xx"}, "a", " b", "", undef, ["c"]);
 # => ("xxa", "xx b", "xx", undef, ["c"])

In command line:

 % echo -e "1\n 2" | dux lins --text xx
 xx1
 xx 2

=head1 FUNCTIONS


=head2 lins(%args) -> [status, msg, result, meta]

Add some text at the beginning of each line of text.

This is sort of a counterpart for ltrim, which removes whitespace at the
beginning (left) of each line of text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<text>* => I<str>

The text to add.

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

indent, rins

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
