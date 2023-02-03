package Data::Dataset::ChordProgressions;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Provide access to hundreds of possible chord progressions

our $VERSION = '0.0303';

use strict;
use warnings;

use Text::CSV_XS ();
use File::ShareDir qw(dist_dir);
use Music::Scales qw(get_scale_notes);
use Exporter 'import';

our @EXPORT = qw(
    as_file
    as_list
    as_hash
    transpose
);



sub as_file {
    my $file = eval { dist_dir('Data-Dataset-ChordProgressions') . '/Chord-Progressions.csv' };

    $file = 'share/Chord-Progressions.csv'
        unless $file && -e $file;

    return $file;
}


sub as_list {
    my $file = as_file();

    my @data;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    while (my $row = $csv->getline($fh)) {
        push @data, $row;
    }

    close $fh;

    return @data;
}


sub as_hash {
    my $file = as_file();

    my %data;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    while (my $row = $csv->getline($fh)) {
        # Row = Genre, Key, Type, Chords, Roman
        push @{ $data{ $row->[0] }{ $row->[1] }{ $row->[2] } }, [ $row->[3], $row->[4] ];
    }

    close $fh;

    return %data;
}


sub transpose {
    my ($note, $scale, $progression) = @_;

    my %note_map;
    @note_map{ get_scale_notes('C', $scale) } = get_scale_notes($note, $scale);

    # transpose the progression chords from C
    $progression =~ s/([A-G][#b]?)/$note_map{$1}/g;

    return $progression;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dataset::ChordProgressions - Provide access to hundreds of possible chord progressions

=head1 VERSION

version 0.0303

=head1 SYNOPSIS

  use Data::Dataset::ChordProgressions qw(as_file as_list as_hash transpose);

  my $filename = as_file();
  my @data = as_list();
  my %data = as_hash();

  my $named = transpose('A', 'major', 'C-F-Am-F');

=head1 DESCRIPTION

C<Data::Dataset::ChordProgressions> provides access to hundreds of
possible musical chord progressions in five genres: C<blues>,
C<country>, C<jazz>, C<pop> and C<rock>.  Each has progressions in
keys of C<C major> and C<C minor>.

Each of these is divided into a named C<type> of progression. Take
these types with a grain of salt. They may or may not be meaningful...

The named chords are meant to match the known chords of
L<Music::Chord::Note> (listed in the source of that module).

There are a few odd chord "progressions" like
C<"Eb7-Eb7-Eb7-Eb7","III-III-III-III">. Strange...

I stumbled across this list, saved it on my hard-drive for a long
time, and then forgot where it came from!  Also the documentation in
the original list said nothing about who made it or how. :\

=head1 FUNCTIONS

=head2 as_file

  $filename = as_file();

Return the chord progression data filename location.

=head2 as_list

  @data = as_list();

Return the chord progression data as an array.

=head2 as_hash

  %data = as_hash();

Return the chord progression data as a hash.

=head2 transpose

  $named = transpose($note, $scale, $progression);

Transpose a B<progression> in the key of C<C> to the given B<note> and
B<scale>.

The progression must be a string of hyphen-separated chord names. For
example: C<'C-F-Am-F'>

=head1 SEE ALSO

The F<t/01-functions.t> and F<eg/*> files

L<Exporter>

L<File::ShareDir>

L<Music::Scales>

L<Text::CSV_XS>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
