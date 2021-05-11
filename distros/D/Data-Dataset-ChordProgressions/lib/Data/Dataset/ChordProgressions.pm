package Data::Dataset::ChordProgressions;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Provide access to hundreds of possible chord progressions

our $VERSION = '0.0103';

use strict;
use warnings;

use Text::CSV_XS;
use File::ShareDir qw(dist_dir);



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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dataset::ChordProgressions - Provide access to hundreds of possible chord progressions

=head1 VERSION

version 0.0103

=head1 SYNOPSIS

  use Data::Dataset::ChordProgressions;

  my $filename = Data::Dataset::ChordProgressions::as_file();

  my @data = Data::Dataset::ChordProgressions::as_list();

  my %data = Data::Dataset::ChordProgressions::as_hash();

=head1 DESCRIPTION

C<Data::Dataset::ChordProgressions> provides access to hundreds of
possible musical chord progressions in five genres: C<blues>,
C<country>, C<jazz>, C<pop> and C<rock>.  Each has progressions in
keys of C<C major> and C<C minor>.

Each of these is divided into a C<type> of progression, depending on
song position.  Take these types with a grain of salt.  They may or
may not be meaningful...

Each of these is a list of possible chord progressions by named chords
and by Roman numeral notation.

The named chords are meant to match the known chords of
L<Music::Chord::Note> (listed in the source).

=head1 FUNCTIONS

=head2 as_file

  $filename = Data::Dataset::ChordProgressions::as_file();

Return the data filename location.

=head2 as_list

  @data = Data::Dataset::ChordProgressions::as_list();

Return the data as an array.

=head2 as_hash

  %data = Data::Dataset::ChordProgressions::as_hash();

Return the data as a hash.

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
