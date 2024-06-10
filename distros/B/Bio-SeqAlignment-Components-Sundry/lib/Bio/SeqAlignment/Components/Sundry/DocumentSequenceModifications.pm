package Bio::SeqAlignment::Components::Sundry::DocumentSequenceModifications;
$Bio::SeqAlignment::Components::Sundry::DocumentSequenceModifications::VERSION = '0.01';
use strict;
use warnings;

use Carp;
use Data::MessagePack;
use File::Basename;
use File::Spec;
use JSON qw (encode_json decode_json);
use YAML::Tiny;

use Exporter qw(import);
our @EXPORT_OK = qw(store_modifications retrieve_modifications);

our %serialization_formats = (
    yaml => {
        decode => sub {
            my ($mod_fname) = @_;
            my $infile = YAML::Tiny->read($mod_fname);
            return $infile->[0];
        },
        encode => sub {
            my ( $mod_HoH_ref, $mod_fname ) = @_;
            my $outfile = YAML::Tiny->new;
            $outfile->[0] = $mod_HoH_ref;
            $outfile->write($mod_fname);
        }
    },
    json => {
        decode => sub {
            my ($mod_fname) = @_;
            open my $infile_fh, '<', $mod_fname
              or die "Could not open file: $!";
            my $json = do { local $/; <$infile_fh> };
            close $infile_fh;
            return decode_json($json);
        
        },
        encode => sub {
            my ( $mod_HoH_ref, $mod_fname ) = @_;
            open my $outfile_fh, '>', $mod_fname
              or die "Could not open file: $!";
            my $json = encode_json($mod_HoH_ref);
            print $outfile_fh $json;
            close $outfile_fh;
        }
    },
    msgpack => {
        decode => sub {
            my ($mod_fname) = @_;
            open my $infile_fh, '<', $mod_fname
              or die "Could not open file: $!";
            binmode $infile_fh;
            my $msgpack = do { local $/; <$infile_fh> };
            close $infile_fh;
            return Data::MessagePack->unpack($msgpack);
        
        },
        encode => sub {
            my ( $mod_HoH_ref, $mod_fname ) = @_;
            open my $outfile_fh, '>', $mod_fname
              or die "Could not open file: $!";
            binmode $outfile_fh;
            print $outfile_fh Data::MessagePack->pack($mod_HoH_ref);
            close $outfile_fh;
        
        }
    }
);

sub store_modifications {
    my %args = (
        mods        => undef,
        format      => 'YAML',
        bioseq_file => undef,
        @_
    );

    die "Error: mods is required\n"        unless defined $args{mods};
    die "Error: bioseq_file is required\n" unless defined $args{bioseq_file};
    $args{format} = uc $args{format};
    my $extension =
        $args{format} eq 'YAML'        ? 'yaml'
      : $args{format} eq 'JSON'        ? 'json'
      : $args{format} eq 'MESSAGEPACK' ? 'msgpack'
      :                                  'unknown';
    die "Error: unknown format $args{format}\n" if $extension eq 'unknown';
    my $outfile   = dirname( $args{bioseq_file} );
    my $mod_fname = basename( $args{bioseq_file} );
    $mod_fname =~ s/(.+)\.fasta$/$1_mods.$extension/;
    $mod_fname = File::Spec->catfile( $outfile, $mod_fname );
    $serialization_formats{$extension}{encode}->( $args{mods}, $mod_fname );

    return $mod_fname;
}

sub retrieve_modifications {
    my %args = (
        format    => 'YAML',
        mod_fname => undef,
        @_
    );

    die "Error: mod_fname is required\n" unless defined $args{mod_fname};
    $args{format} = uc $args{format};
    my $extension =
        $args{format} eq 'YAML'        ? 'yaml'
      : $args{format} eq 'JSON'        ? 'json'
      : $args{format} eq 'MESSAGEPACK' ? 'msgpack'
      :                                  'unknown';
    die "Error: unknown format $args{format}\n" if $extension eq 'unknown';

    return $serialization_formats{$extension}{decode}->( $args{mod_fname} );
}

1;
__END__

=head1 NAME

Bio::SeqAlignment::Components::Sundry::DocumentSequenceModifications - Store and retrieve sequence modifications

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Bio::SeqAlignment::Components::Sundry::DocumentSequenceModifications qw(store_modifications);

  my $modifications = {
      'seq1' => {
          'mod1' => 'A->G',
          'mod2' => 'C->T'
      },
      'seq2' => {
          'mod1' => 'G->A',
          'mod2' => 'T->C'
      }
  };

  my $mod_fname = store_modifications(
      mods      => $modifications,
      format    => 'YAML',
      bioseq_file => 'sequences.fasta',
      outdir    => '.'
  );

  my $modifications_ref = retrieve_modifications(
      format    => 'YAML',
      mod_fname => $mod_fname
  );

=head1 DESCRIPTION

This module provides functions to store and retrieve sequence modifications in
various formats. These modifications provide a meta-data layer to fasta files
(and down the road to fastq files) that can be used to track changes made to
the sequences in the file. While there are many ways to store such information,
this module provides a simple way to store and retrieve it in common serialization
formats (e.g. JSON/YAML/MessagePack). Storing this information in this manner
allows for easy retrieval and use in downstream analyses and avoids the use of
the rather heavyweight BioPerl modules.

=head1 EXPORT

store_modifications, retrieve_modifications

=head1 SUBROUTINES

=head2 store_modifications

  my $mod_fname = store_modifications(
      mods      => $modifications,
      format    => 'YAML',
      bioseq_file => 'sequences.fasta',
      outdir    => '.'
  );

Stores the sequence modifications in the specified format. The modifications
are stored in a file with the same name as the fasta file but with a '_mods'
suffix and the appropriate extension (e.g. 'sequences_mods.yaml'). The file is
written to the specified output directory. The function returns the full path
to the file where the modifications are stored.

=head2 retrieve_modifications

  my $modifications_ref = retrieve_modifications(
      format    => 'YAML',
      mod_fname => $mod_fname
  );

Retrieves the sequence modifications from the specified file in the specified
format. The function returns a reference to the hash containing the modifications.

=head1 AUTHOR

Christos Argyropoulos <chrisarg *at* cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
