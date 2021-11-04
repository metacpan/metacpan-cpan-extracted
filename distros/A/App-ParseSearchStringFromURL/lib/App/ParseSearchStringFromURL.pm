package App::ParseSearchStringFromURL;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-17'; # DATE
our $DIST = 'App-ParseSearchStringFromURL'; # DIST
our $VERSION = '0.004'; # VERSION

our %SPEC;

$SPEC{parse_search_string_from_url} = {
    v => 1.1,
    summary => 'Parse search string from URL',
    args => {
        urls => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'url',
            schema => ['array*', of=>'url*'],
            req => 1,
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
            stream => 1,
        },
        detail => {
            summary => 'If set to true, will also output other '.
                'components aside from search string',
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        module => {
            schema => ['str*', in=>[
                'URI::ParseSearchString',
                'URI::ParseSearchString::More',
                'URI::ParseSearchString::PERLANCAR',
            ]],
            default => 'URI::ParseSearchString',
        },
    },
    result => {
        stream => 1,
    },
};
sub parse_search_string_from_url {
    #require Array::Iter;

    my %args = @_;

    my $urls = $args{urls};
    #$urls = Array::Iter::array_iter($urls) unless ref $urls eq 'CODE';
    my $detail = $args{detail};
    my $mod = $args{module};

    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    if ($mod =~ /^URI::ParseSearchString/) {
        my $uparse = $mod->new;
        return [
            200,
            "OK",
            sub {
                my $url = $urls->();
                return undef unless defined $url; ## no critic: Subroutines::ProhibitExplicitReturnUndef
                if ($detail) {
                    return {
                        host          => $uparse->se_host($url),
                        name          => $uparse->se_name($url),
                        search_string => $uparse->se_term($url),
                    };
                } else {
                    return $uparse->se_term($url);
                }
            }];
    } else {
        return [500, "BUG: Unknown module", sub {undef}];
    }
}

1;
# ABSTRACT: Parse search string from URL

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ParseSearchStringFromURL - Parse search string from URL

=head1 VERSION

This document describes version 0.004 of App::ParseSearchStringFromURL (from Perl distribution App-ParseSearchStringFromURL), released on 2021-10-17.

=head1 FUNCTIONS


=head2 parse_search_string_from_url

Usage:

 parse_search_string_from_url(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse search string from URL.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

If set to true, will also output other components aside from search string.

=item * B<module> => I<str> (default: "URI::ParseSearchString")

=item * B<urls>* => I<array[url]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-ParseSearchStringFromURL>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ParseSearchStringFromURL>.

=head1 SEE ALSO

You can choose one of the backends: L<URI::ParseSearchString>,
L<URI::ParseSearchString::More>, L<URI::ParseSearchString::PERLANCAR>.

L<uri-info> from L<App::URIInfoUtils>, which is based on L<URI::Info>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ParseSearchStringFromURL>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
