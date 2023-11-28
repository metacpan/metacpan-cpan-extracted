package App::FileFindUtils;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-20'; # DATE
our $DIST = 'App-FileFindUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{find_wanted} = {
    v => 1.1,
    summary => 'Find files based on some criteria (CLI front-end for File::Find::Wanted)',
    args => {
        wanted => {
            schema => 'code_from_str*',
            req => 1,
            pos => 0,
        },
        dirs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dir',
            schema => ['array*', of=>'dirname*'],
            default => ['.'],
            pos => 1,
            slurpy => 1,
        },
    },
    examples => [
        {
            summary => "Find regular files in lib/",
            src => q{[[prog]] -- '-f' lib},
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => "Find JPEG files in current directory",
            src => q{[[prog]] -- '-f && /\.jpe?g$/i'},
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub find_wanted {
    my %args = @_;

    require File::Find::Wanted;
    [200, "OK", [File::Find::Wanted::find_wanted($args{wanted}, @{ $args{dirs} })]];
}

1;
# ABSTRACT: Utilities related to finding files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileFindUtils - Utilities related to finding files

=head1 VERSION

This document describes version 0.001 of App::FileFindUtils (from Perl distribution App-FileFindUtils), released on 2023-11-20.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item * L<find-wanted>

=back

=head1 FUNCTIONS


=head2 find_wanted

Usage:

 find_wanted(%args) -> [$status_code, $reason, $payload, \%result_meta]

Find files based on some criteria (CLI front-end for File::Find::Wanted).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dirs> => I<array[dirname]> (default: ["."])

(No description)

=item * B<wanted>* => I<code_from_str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FileFindUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileFindUtils>.

=head1 SEE ALSO

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileFindUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
