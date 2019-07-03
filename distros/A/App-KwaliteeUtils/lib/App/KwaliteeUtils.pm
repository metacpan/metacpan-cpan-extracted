package App::KwaliteeUtils;

our $DATE = '2019-07-03'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Module::CPANTS::Analyse;

our %SPEC;

$SPEC{calc_kwalitee} = {
    v => 1.1,
    summary => 'Calculate kwalitee of a local distribution',
    args => {
        dist => {
            summary => 'Distribution archive file (e.g. tarball) or directory',
            schema => 'pathname*',
            default => '.',
            pos => 0,
            description => <<'_',

Although a directory (top-level directory of an extracted Perl distribution) can
be analyzed, distribution Kwalitee is supposed to be calculated on a
distribution archive file (e.g. tarball) because there are metrics like
`extractable`, `extracts_nicely`, `no_pax_headers` which can only be tested on a
distribution archive file. Running this on a directory will result in a
less-than-full score.

_
        },
        raw => {
            schema => 'true*',
        },
    },
};
sub calc_kwalitee {
    my %args = @_;

    my $mca = Module::CPANTS::Analyse->new({dist => $args{dist}});
    my $res = $mca->run;

    if ($args{raw}) {
        return [200, "OK", $res];
    } else {
        my $kw = $res->{kwalitee};
        my $num_indicators = %$kw - 1;
        $kw->{'00kwalitee_score'} =
            sprintf("%.2f", ($kw->{kwalitee} / $num_indicators)*100);
        return [200, "OK", $kw];
    }
}

1;
# ABSTRACT: Utilities related to Kwalitee

__END__

=pod

=encoding UTF-8

=head1 NAME

App::KwaliteeUtils - Utilities related to Kwalitee

=head1 VERSION

This document describes version 0.002 of App::KwaliteeUtils (from Perl distribution App-KwaliteeUtils), released on 2019-07-03.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<calc-kwalitee>

=back

=head1 FUNCTIONS


=head2 calc_kwalitee

Usage:

 calc_kwalitee(%args) -> [status, msg, payload, meta]

Calculate kwalitee of a local distribution.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dist> => I<pathname> (default: ".")

Distribution archive file (e.g. tarball) or directory.

Although a directory (top-level directory of an extracted Perl distribution) can
be analyzed, distribution Kwalitee is supposed to be calculated on a
distribution archive file (e.g. tarball) because there are metrics like
C<extractable>, C<extracts_nicely>, C<no_pax_headers> which can only be tested on a
distribution archive file. Running this on a directory will result in a
less-than-full score.

=item * B<raw> => I<true>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-KwaliteeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-KwaliteeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-KwaliteeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Alternative to L<calc-kwalitee>: L<cpants_lint.pl> from L<App::CPANTS::Lint>,
the "official" script, which again I only found after writing C<calc-kwalitee>.

L<Module::CPANTS::Kwalitee>

L<https://cpants.cpanauthors.org/kwalitee/>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
