package App::BrowserOpenUtils;

our $DATE = '2019-05-28'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{open_browser} = {
    v => 1.1,
    args => {
        urls => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'url',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        all => {
            schema => 'true*',
        },
    },
    features => {
        dry_run => 1,
    },
};
sub open_browser {
    require Browser::Open;

    my %args = @_;
    for my $url (@{ $args{urls} }) {
        if ($args{-dry_run}) {
            my $cmd = $args{all} ?
                Browser::Open::open_browser_cmd_all() :
                Browser::Open::open_browser_cmd();
            log_info "[DRY_RUN] Opening %s in browser with: %s ...", $url, $cmd;
        } else {
            log_trace "Opening %s in browser ...", $url;
            Browser::Open::open_browser($url, $args{all});
        }
    }
    [200];
}

1;
# ABSTRACT: Utilities related to Browser::Open

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BrowserOpenUtils - Utilities related to Browser::Open

=head1 VERSION

This document describes version 0.002 of App::BrowserOpenUtils (from Perl distribution App-BrowserOpenUtils), released on 2019-05-28.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities:

#INSERT_EXECS_LIST

=head1 FUNCTIONS


=head2 open_browser

Usage:

 open_browser(%args) -> [status, msg, payload, meta]

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

=item * B<urls>* => I<array[str]>

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-BrowserOpenUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BrowserOpenUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BrowserOpenUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
