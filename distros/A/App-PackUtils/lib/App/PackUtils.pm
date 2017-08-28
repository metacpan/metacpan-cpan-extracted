package App::PackUtils;

our $DATE = '2017-08-27'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our %SPEC;

$SPEC{perl_pack} = {
    v => 1.1,
    summary => 'Pack() data',
    args => {
        template => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        data => {
            schema => 'array*',
            req => 1,
            pos => 1,
            greedy => 1
        },
    },
    'cmdline.default_format' => 'perl',
    result_naked => 1,
};
sub perl_pack {
    my %args = @_;

    pack($args{template}, @{ $args{data} });
}

$SPEC{perl_unpack} = {
    v => 1.1,
    summary => 'Unpack() string',
    args => {
        template => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        string => {
            schema => 'str*',
            pos => 1,
        },
        escaped_string => {
            schema => 'str*',
            cmdline_aliases => {e=>{}},
        },
    },
    args_rels => {
        req_one => ['string', 'escaped_string'],
    },
    'cmdline.default_format' => 'perl',
    result_naked => 1,
};
sub perl_unpack {
    my %args = @_;

    [unpack($args{template}, @{ exists $args{string} ? $args{string} : eval($args{escaped_string}) })];
}

$SPEC{perl_pack_template_is_fixed_size} = {
    v => 1.1,
    summary => 'Check if a Perl pack() template specifies a fixed-size data',
    args => {
        template => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    'cmdline.default_format' => 'perl',
    result_naked => 1,
};
sub perl_pack_template_is_fixed_size {
    #require Pack::Util;

    my %args = @_;

    Pack::Util::template_is_fixed_size($args{template}) ? 1:0;
}

$SPEC{perl_pack_template_data_size} = {
    v => 1.1,
    summary => 'Show Perl pack() template data size in bytes if fixed, or -1 if arbitrary',
    args => {
        template => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    'cmdline.default_format' => 'perl',
    result_naked => 1,
};
sub perl_pack_template_data_size {
    #require Pack::Util;

    my %args = @_;

    Pack::Util::template_data_size($args{template});
}

1;
# ABSTRACT: Command-line utilities related to Perl pack() and unpack()

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PackUtils - Command-line utilities related to Perl pack() and unpack()

=head1 VERSION

This document describes version 0.001 of App::PackUtils (from Perl distribution App-PackUtils), released on 2017-08-27.

=head1 SYNOPSIS

This distribution provides tha following command-line utilities related to Perl
C<pack()> and C<unpack()> functions:

=over

=item * L<perl-pack>

=item * L<perl-unpack>

=back

=head1 FUNCTIONS


=head2 perl_pack

Usage:

 perl_pack(%args) -> any

Pack() data.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<data>* => I<array>

=item * B<template>* => I<str>

=back

Return value:  (any)


=head2 perl_pack_template_data_size

Usage:

 perl_pack_template_data_size(%args) -> any

Show Perl pack() template data size in bytes if fixed, or -1 if arbitrary.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<template>* => I<str>

=back

Return value:  (any)


=head2 perl_pack_template_is_fixed_size

Usage:

 perl_pack_template_is_fixed_size(%args) -> any

Check if a Perl pack() template specifies a fixed-size data.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<template>* => I<str>

=back

Return value:  (any)


=head2 perl_unpack

Usage:

 perl_unpack(%args) -> any

Unpack() string.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escaped_string> => I<str>

=item * B<string> => I<str>

=item * B<template>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PackUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PackUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PackUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
