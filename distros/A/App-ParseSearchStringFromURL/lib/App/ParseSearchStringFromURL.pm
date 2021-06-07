package App::ParseSearchStringFromURL;

our $DATE = '2021-05-26'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

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

    if ($mod =~ /^URI::ParseSearchString(?:::More)?$/) {
        my $uparse = $mod->new;
        return [
            200,
            "OK",
            sub {
                my $url = $urls->();
                return undef unless defined $url;
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

This document describes version 0.003 of App::ParseSearchStringFromURL (from Perl distribution App-ParseSearchStringFromURL), released on 2021-05-26.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-ParseSearchStringFromURL/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
