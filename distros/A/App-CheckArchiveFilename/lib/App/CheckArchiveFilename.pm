package App::CheckArchiveFilename;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-27'; # DATE
our $DIST = 'App-CheckArchiveFilename'; # DIST
our $VERSION = '0.007'; # VERSION

our %SPEC;

$SPEC{check_archive_filename} = {
    v => 1.1,
    summary => 'Return information about archive & compressor types from filenames',
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
sub check_archive_filename {
    require Filename::Archive;
    require Filename::Compressed;

    my %args = @_;
    my $filenames = $args{filenames};

    my @res;
    for my $filename (@$filenames) {
        my $rec = {filename => $filename};
        my $ares = Filename::Archive::check_archive_filename(
            filename => $filename);
        if ($ares) {
            $rec->{is_archive} = 1;
            $rec->{archive_name} = $ares->{archive_name};
            $rec->{archive_suffix} = $ares->{archive_suffix};
            $rec->{filename_without_suffix} = $ares->{filename_without_suffix};
            if ($ares->{compressor_info}) {
                $rec->{is_compressed} = 1;
                # we'll just display the outermost compressor (e.g. compressor
                # for file.tar.gz.bz2 is bzip2). this is rare though.
                $rec->{compressor_name}   = $ares->{compressor_info}[0]{compressor_name};
                $rec->{compressor_suffix} = $ares->{compressor_info}[0]{compressor_suffix};
            }
        } else {
            $rec->{is_archive} = 0;
            my $cres = Filename::Compressed::check_compressed_filename(
                filename => $filename);
            if ($cres) {
                $rec->{is_compressed} = 1;
                $rec->{compressor_name}   = $cres->{compressor_name};
                $rec->{compressor_suffix} = $cres->{compressor_suffix};
            }
        }
        push @res, $rec;
    }

    [200, "OK", \@res, {
        'table.fields' => [qw/filename is_archive is_compressed
                             archive_name compressor_name compressor_suffix/],
    }];
}

1;
# ABSTRACT: Return information about archive & compressor types from filenames

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CheckArchiveFilename - Return information about archive & compressor types from filenames

=head1 VERSION

This document describes version 0.007 of App::CheckArchiveFilename (from Perl distribution App-CheckArchiveFilename), released on 2023-08-27.

=head1 FUNCTIONS


=head2 check_archive_filename

Usage:

 check_archive_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return information about archive & compressor types from filenames.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CheckArchiveFilename>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CheckArchiveFilename>.

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

This software is copyright (c) 2023, 2021, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CheckArchiveFilename>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
