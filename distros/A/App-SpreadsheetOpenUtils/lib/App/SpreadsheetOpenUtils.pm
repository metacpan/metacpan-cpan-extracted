package App::SpreadsheetOpenUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-19'; # DATE
our $DIST = 'App-SpreadsheetOpenUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{open_spreadsheet} = {
    v => 1.1,
    args => {
        paths_or_urls => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'path_or_url',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        #all => {
        #    schema => 'true*',
        #},
    },
    features => {
        dry_run => 1,
    },
};
sub open_spreadsheet {
    require Spreadsheet::Open;

    my %args = @_;
    for my $path_or_url (@{ $args{paths_or_urls} }) {
        if ($args{-dry_run}) {
        } else {
            log_trace "Opening %s ...", $path_or_url;
            Spreadsheet::Open::open_spreadsheet($path_or_url);
        }
    }
    [200];
}

1;
# ABSTRACT: Utilities related to Spreadsheet::Open

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadsheetOpenUtils - Utilities related to Spreadsheet::Open

=head1 VERSION

This document describes version 0.001 of App::SpreadsheetOpenUtils (from Perl distribution App-SpreadsheetOpenUtils), released on 2023-12-19.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities:

#INSERT_EXECS_LIST

=head1 FUNCTIONS


=head2 open_spreadsheet

Usage:

 open_spreadsheet(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<paths_or_urls>* => I<array[str]>

(No description)


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-SpreadsheetOpenUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SpreadsheetOpenUtils>.

=head1 SEE ALSO

L<Spreadsheet::Open>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SpreadsheetOpenUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
