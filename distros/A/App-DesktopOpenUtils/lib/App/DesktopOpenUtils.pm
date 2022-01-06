package App::DesktopOpenUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-01'; # DATE
our $DIST = 'App-DesktopOpenUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{open_desktop} = {
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
sub open_desktop {
    require Desktop::Open;

    my %args = @_;
    for my $path_or_url (@{ $args{paths_or_urls} }) {
        if ($args{-dry_run}) {
            #my $cmd = $args{all} ?
            #    Browser::Open::open_browser_cmd_all() :
            #    Browser::Open::open_browser_cmd();
            #log_info "[DRY_RUN] Opening %s in browser with: %s ...", $url, $cmd;
            #log_info "[DRY_RUN] Opening %s ...", $path_or_url;
        } else {
            log_trace "Opening %s ...", $path_or_url;
            #Desktop::Open::open_desktop($url, $args{all});
            Desktop::Open::open_desktop($path_or_url);
        }
    }
    [200];
}

1;
# ABSTRACT: Utilities related to Desktop::Open

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DesktopOpenUtils - Utilities related to Desktop::Open

=head1 VERSION

This document describes version 0.002 of App::DesktopOpenUtils (from Perl distribution App-DesktopOpenUtils), released on 2021-08-01.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities:

#INSERT_EXECS_LIST

=head1 FUNCTIONS


=head2 open_desktop

Usage:

 open_desktop(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<paths_or_urls>* => I<array[str]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-DesktopOpenUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DesktopOpenUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DesktopOpenUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Desktop::Open>

L<App::BrowserOpenUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
