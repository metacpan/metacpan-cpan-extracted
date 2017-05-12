package App::xsum;

our $DATE = '2016-11-23'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{xsum} = {
    v => 1.1,
    args => {
        tag => {
            summary => 'Create a BSD-style checksum',
            schema => ['bool', is=>1],
        },
        check => {
            summary => 'Read checksum from files and check them',
            schema => ['bool', is=>1],
        },
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
        algorithm => {
            schema => ['str*', in=>[qw/crc32 md5 sha1 sha224 sha256 sha384 sha512 sha512224 sha512256/]],
            default => 'md5',
            cmdline_aliases => {a=>{}},
        },
    },
    links => [
        {
            url => 'prog:shasum',
            summary => 'Script which comes with the perl distribution',
        },
        {
            url => 'prog:md5sum',
            summary => 'Unix utility',
        },
        {
            url => 'prog:sha1sum',
            summary => 'Unix utility',
        },
        {
            url => 'prog:sha256sum',
            summary => 'Unix utility',
        },
    ],
    'cmdline.skip_format' => 1,
};
sub xsum {
    require File::Digest;
    require Parse::Sums;

    my %args = @_;

    my $num_success;
    my $envres;
    for my $file (@{ $args{files} }) {
        if ($args{check}) {
            my $res = Parse::Sums::parse_sums(filename => $file);
            unless ($res->[0] == 200) {
                $envres //= [
                    500, "Some checksums files cannot be parsed"];
                warn "Can't parse checksums from $file: $res->[1]\n";
                next;
            }
            unless (@{ $res->[2] }) {
                $envres //= [
                    500, "Some checksums files don't contain any checksums"];
                warn "No checksums found in $file".($res->[3]{'func.warning'} ? ": ".$res->[3]{'func.warning'} : "")."\n";
                next;
            }
            warn "$file: ".$res->[3]{'func.warning'}."\n" if $res->[3]{'func.warning'};
          ENTRY:
            for my $entry (@{ $res->[2] }) {
                my $digest_res = File::Digest::digest_file(
                    file => $entry->{file}, algorithm => $entry->{algorithm});
                unless ($digest_res) {
                    $envres //= [
                        500, "Some files' checksums cannot be checked"];
                    warn "$entry->{file}: Cannot compute digest: $digest_res->[1]\n";
                    next ENTRY;
                }
                if ($digest_res->[2] eq $entry->{digest}) {
                    print "$entry->{file}: OK\n";
                    $num_success++;
                } else {
                    $envres //= [
                        500, "Some files did NOT match computed checksums"];
                    print "$entry->{file}: FAILED\n";
                }
            }
        } else {
            my $res = File::Digest::digest_file(
                file => $file, algorithm => $args{algorithm});
            unless ($res->[0] == 200) {
                warn "Can't checksum $file: $res->[1]\n";
                next;
            }
            $num_success++;
            if ($args{tag}) {
                printf "%s (%s) = %s\n", uc($args{algorithm}), $file, $res->[2];
            } else {
                printf "%s  %s\n", $res->[2], $file;
            }
        }
    }

    return $envres if $envres;
    $num_success ? [200] : [500, "All files failed"];
}

1;
# ABSTRACT: Compute and check file checksums/digests

__END__

=pod

=encoding UTF-8

=head1 NAME

App::xsum - Compute and check file checksums/digests

=head1 VERSION

This document describes version 0.001 of App::xsum (from Perl distribution App-xsum), released on 2016-11-23.

=head1 SYNOPSIS

See L<xsum>.

=head1 FUNCTIONS


=head2 xsum(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<algorithm> => I<str> (default: "md5")

=item * B<check> => I<bool>

Read checksum from files and check them.

=item * B<files>* => I<array[filename]>

=item * B<tag> => I<bool>

Create a BSD-style checksum.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-xsum>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-xsum>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-xsum>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<shasum>. Script which comes with the perl distribution.

L<md5sum>. Unix utility.

L<sha1sum>. Unix utility.

L<sha256sum>. Unix utility.

Backend module: L<File::Digest>, which in turn uses L<Digest::CRC>,
L<Digest::MD5>, and L<Digest::SHA>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
