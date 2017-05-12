package App::audioinfo;

our $DATE = '2016-12-13'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

#use Perinci::Object;

our %SPEC;

$SPEC{'audioinfo'} = {
    v => 1.1,
    summary => 'Get information from audio files',
    description => <<'_',

This is a CLI front-end for <pm:AudioFile::Info>.

_
    args => {
        filenames => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'filename',
            schema => ['array*', of=>'filename*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
        plugins => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'plugin',
            summary => 'What plugin to use for each file type',
            schema => ['hash*', of=>'str*'],
        },
    },
    features => {
        dry_run => 1,
    },
};
sub audioinfo {
    require AudioFile::Info;

    my %args = @_;

    my $envres = [200, "OK", [], {'table.fields'=>[qw/filename title artist album track year genre/]}];# = envresmulti();
    for my $filename (@{ $args{filenames} }) {
        my $song = AudioFile::Info->new($filename, $args{plugins});
        push @{ $envres->[2] }, {
            filename => $filename,
            title  => $song->title,
            artist => $song->artist,
            album  => $song->album,
            track  => $song->track,
            year   => $song->year,
            genre  => scalar $song->genre, # genre() returns empty list?
        };
        #$envres->add_result(200, "OK", {item_id=>$filename});
    }
    $envres;
}

1;
# ABSTRACT: Get information from audio files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::audioinfo - Get information from audio files

=head1 VERSION

This document describes version 0.001 of App::audioinfo (from Perl distribution App-audioinfo), released on 2016-12-13.

=head1 FUNCTIONS


=head2 audioinfo(%args) -> [status, msg, result, meta]

Get information from audio files.

This is a CLI front-end for L<AudioFile::Info>.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<filenames>* => I<array[filename]>

=item * B<plugins> => I<hash>

What plugin to use for each file type.

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
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-audioinfo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-audioinfo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-audioinfo>

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
