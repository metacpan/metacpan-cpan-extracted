package App::CheckPerlReleaseFilename;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-27'; # DATE
our $DIST = 'App-CheckPerlReleaseFilename'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{check_perl_release_filename} = {
    v => 1.1,
    summary => 'Check whether filenames look like perl module release archive',
    args => {
        filenames => {
            schema => ['array*', of=>'filename*', min_len=>1],
            'x.name.is_plural' => 1,
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
};
sub check_perl_release_filename {
    require Filename::Perl::Release;

    my %args = @_;
    my $filenames = $args{filenames};

    my @res;
    for my $filename (@$filenames) {
        my $rec = {filename => $filename};
        (my $basename = $filename) =~ s!.+/!!;
        my $prres = Filename::Perl::Release::check_perl_release_filename(
            filename => $basename);
        if ($prres) {
            $rec->{is_release} = 1;
            $rec->{distribution}   = $prres->{distribution};
            $rec->{version}        = $prres->{version};
            $rec->{module}         = $prres->{module};
            $rec->{archive_suffix} = $prres->{archive_suffix};
        }
        push @res, $rec;
    }

    [200, "OK", \@res, {
        'table.fields' => [qw/filename is_release/],
    }];
}

1;
# ABSTRACT: Check whether filenames look like perl module release archive

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CheckPerlReleaseFilename - Check whether filenames look like perl module release archive

=head1 VERSION

This document describes version 0.001 of App::CheckPerlReleaseFilename (from Perl distribution App-CheckPerlReleaseFilename), released on 2023-08-27.

=head1 FUNCTIONS


=head2 check_perl_release_filename

Usage:

 check_perl_release_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether filenames look like perl module release archive.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filenames>* => I<array[filename]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CheckPerlReleaseFilename>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CheckPerlReleaseFilename>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CheckPerlReleaseFilename>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
