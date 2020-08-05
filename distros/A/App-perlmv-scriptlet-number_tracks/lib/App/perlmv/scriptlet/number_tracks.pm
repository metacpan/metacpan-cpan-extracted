package App::perlmv::scriptlet::number_tracks;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-03'; # DATE
our $DIST = 'App-perlmv-scriptlet-number_tracks'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $SCRIPTLET = {
    summary => 'Add track number to filenames',
    args => {
        listing_file => {
            summary => 'File that contains track listing',
            schema => 'filename*',
            req => 1,
        },
    },
    code => sub {
        package
            App::perlmv::code;
        require Text::Similarity::Overlaps;

        use vars qw($ARGS $sim $listing);

        $ARGS && defined $ARGS->{listing_file}
            or die "Please specify listing_file argument (e.g. '-a listing_file=FILENAME.TXT')";

        unless ($sim) {
            $sim = Text::Similarity::Overlaps->new;
        }

        unless ($listing) {
            $listing = [];
            open my $fh, "<", $ARGS->{listing_file}
                or die "Can't open listing file '$ARGS->{listing_file}': $!";
            while (defined(my $line = <$fh>)) {
                chomp $line;
                push @$listing, $line;
            }
        }

        my @scores;
        for my $tracknum (1..@$listing) {
            my (undef, %allscores) = $sim->getSimilarityStrings(
                $_, $listing->[$tracknum-1]);
            $allscores{_trackname} = $listing->[$tracknum-1];
            $allscores{_tracknum} = $tracknum;
            push @scores, \%allscores;
        }
        @scores = sort { $b->{raw}<=>$a->{raw} || $b->{lesk}<=>$a->{lesk} } @scores;
        #use DD; say "$_: "; dd \@scores; say "";
        if ($scores[0]{raw}) {
            my $width = length(scalar @$listing);
            sprintf "%0${width}d-%s", $scores[0]{_tracknum}, $_;
        } else {
            warn "Cannot find matching track for '$_', skipped";
            $_;
        }
    },
};

1;

# ABSTRACT: Add track number to filenames

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::number_tracks - Add track number to filenames

=head1 VERSION

This document describes version 0.001 of App::perlmv::scriptlet::number_tracks (from Perl distribution App-perlmv-scriptlet-number_tracks), released on 2020-08-03.

=head1 SYNOPSIS

In F<tracks.txt>:

 name of first song
 name of second song
 third
 fourth
 the fifth and the last

List of mp4 files in current directory:

 Foo - Fourth.mp4
 Foo - Name Of First Song.mp4
 Foo - Name of Second Song.mp4
 Foo - The Fifth & The Last.mp4
 Foo - Third.mp4

To add number prefix to the files:

 % perlmv number-tracks -a tracks.txt *.mp4

The resulting files:

 01-Foo - Name Of First Song.mp4
 02-Foo - Name of Second Song.mp4
 03-Foo - Third.mp4
 04-Foo - Fourth.mp4
 05-Foo - The Fifth & The Last.mp4

=head1 DESCRIPTION

This scriptlet uses L<Text::Similarity::Overlaps> to match filename with track
name. It then adds the resulting track number as filename's prefix.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv-scriptlet-number_tracks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv-scriptlet-number_tracks>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv-scriptlet-number_tracks>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perlmv>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
