package Data::Unixish::ltrim;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $VERSION = '1.570'; # VERSION

our %SPEC;

$SPEC{ltrim} = {
    v => 1.1,
    summary => 'Strip whitespace at the beginning of each line of text',
    description => <<'_',

_
    args => {
        %common_args,
        strip_newline => {
            summary => 'Whether to strip newlines at the beginning of text',
            schema =>[bool => {default=>0}],
            cmdline_aliases => { nl=>{} },
        },
    },
    tags => [qw/text itemfunc/],
};
sub ltrim {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    while (my ($index, $item) = each @$in) {
        push @$out, _ltrim_item($item, \%args);
    }

    [200, "OK"];
}

sub _ltrim_item {
    my ($item, $args) = @_;

    if (defined($item) && !ref($item)) {
        $item =~ s/\A[\r\n]+// if $args->{strip_newline};
        $item =~ s/^[ \t]+//mg;
    }
    return $item;
}

1;
# ABSTRACT: Strip whitespace at the beginning of each line of text

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::ltrim - Strip whitespace at the beginning of each line of text

=head1 VERSION

This document describes version 1.570 of Data::Unixish::ltrim (from Perl distribution Data-Unixish), released on 2019-01-06.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl('ltrim', "x", "   a", "  b\n   c\n", undef, [" d"]);
 # => ("x", "a", "b\nc\n", undef, [" d"])

In command line:

 % echo -e "x\n  a" | dux ltrim
 x
 a

=head1 FUNCTIONS


=head2 ltrim

Usage:

 ltrim(%args) -> [status, msg, payload, meta]

Strip whitespace at the beginning of each line of text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<strip_newline> => I<bool> (default: 0)

Whether to strip newlines at the beginning of text.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
