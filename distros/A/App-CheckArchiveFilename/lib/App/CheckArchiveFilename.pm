package App::CheckArchiveFilename;

our $DATE = '2016-09-09'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

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

This document describes version 0.003 of App::CheckArchiveFilename (from Perl distribution App-CheckArchiveFilename), released on 2016-09-09.

=head1 FUNCTIONS


=head2 check_archive_filename(%args) -> [status, msg, result, meta]

Return information about archive & compressor types from filenames.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filenames>* => I<array[filename]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CheckArchiveFilename>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CheckArchiveFilename>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CheckArchiveFilename>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
