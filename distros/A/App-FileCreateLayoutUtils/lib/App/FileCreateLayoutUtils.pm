package App::FileCreateLayoutUtils;

our $DATE = '2019-04-16'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our %SPEC;

$SPEC{parse_file_create_layout} = {
    v => 1.1,
    summary => 'Parse layout for File::Create::Layout',
    args => {
        layout => {
            schema => 'str*',
            cmdline_src => 'stdin_or_files',
            pos => 0,
            req => 1,
        },
    },
};
sub parse_file_create_layout {
    require File::Create::Layout;
    my %args = @_;

    [200, "OK", File::Create::Layout::_parse_layout($args{layout})];
}

$SPEC{create_files_using_layout} = {
    v => 1.1,
    summary => 'Create files according to layout using File::Create::Layout',
    args => {
        layout => {
            schema => 'str*',
            cmdline_src => 'stdin_or_files',
            pos => 0,
            req => 1,
        },
        prefix => {
            schema => 'str*',
        },
    },
};
sub create_files_using_layout {
    require File::Create::Layout;
    my %args = @_;

    File::Create::Layout::create_files_using_layout(%args);
}

1;
# ABSTRACT: CLIs for File::Create::Layout

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileCreateLayoutUtils - CLIs for File::Create::Layout

=head1 VERSION

This document describes version 0.001 of App::FileCreateLayoutUtils (from Perl distribution App-FileCreateLayoutUtils), released on 2019-04-16.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities:

=over

=item * L<create-files-using-layout>

=item * L<parse-file-create-layout>

=back

=head1 FUNCTIONS


=head2 create_files_using_layout

Usage:

 create_files_using_layout(%args) -> [status, msg, payload, meta]

Create files according to layout using File::Create::Layout.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<layout>* => I<str>

=item * B<prefix> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_file_create_layout

Usage:

 parse_file_create_layout(%args) -> [status, msg, payload, meta]

Parse layout for File::Create::Layout.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<layout>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FileCreateLayoutUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileCreateLayoutUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileCreateLayoutUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
