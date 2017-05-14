package Bio::Gonzales::Align::IO;

use warnings;
use strict;
use Carp;

use Bio::Gonzales::Seq;

use Bio::Gonzales::Util::File qw/open_on_demand/;
use Bio::Gonzales::Util qw/flatten/;
use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(phylip_spew phylip_slurp);

sub phylip_spew {
  my ( $file_or_fh, $mode, @rest ) = @_;
  my @seqs = flatten(@rest);

  my ( $fh, $fh_was_open ) = open_on_demand( $file_or_fh, '>' );
  if ( ref $mode eq 'HASH' ) {
    if ( $mode->{sequential} ) {
      _seq_phylip_spew( $fh, \@seqs, $mode->{relaxed} );
    } else {
      confess 'function not implemented, yet';
    }

  } else {
    my $relaxed = $mode =~ s/^r(?:elax(?:ed)?)?\W//;
    if ( $mode =~ /^s(?:eq(?:uential)?)?$/ ) {
      _seq_phylip_spew( $fh, \@seqs, $relaxed );
    } else {
      croak "you have to supply a mode";
    }
  }

  $fh->close unless ($fh_was_open);
}

sub _seq_phylip_spew {
  my ( $fh, $seqs, $relaxed ) = @_;

  croak "You have to supply an array of Bio::Gonzales::Seq objects"
    unless ( ref $seqs eq 'ARRAY' );

  print $fh scalar(@$seqs) . " " . $seqs->[0]->length, "\n";

  for my $seq (@$seqs) {
    my $id;
    if ($relaxed) {
      ( $id = $seq->id ) =~ s/\s/_/g;
      $id .= " ";
    } else {
      $id = sprintf( "%-10s", substr( $seq->id, 0, 10 ) );
    }
    print $fh $id . $seq->seq, "\n";
  }
}

sub phylip_slurp {
  my ( $file_or_fh, $mode ) = @_;

  my $seqs;
  my ( $fh, $fh_was_open ) = open_on_demand( $file_or_fh, '<' );
  my $relaxed = $mode =~ s/^r(?:elax(?:ed)?)?\W//;
  if ( $mode =~ /^s(?:eq(?:uential)?)?$/ ) { $seqs = _seq_phylip_slurp( $fh, $relaxed ) }
  elsif ( $mode =~ /^i(?:nter(?:leaved)?)?$/ ) { $seqs = _int_phylip_slurp( $fh, $relaxed ) }
  else                                         { croak "you have to supply a mode" }

  $fh->close unless ($fh_was_open);
  return $seqs;
}

sub _seq_phylip_slurp {
  my ( $fh, $relaxed ) = @_;

  my $header = <$fh>;
  $header =~ s/\r\n/\n/;
  chomp $header;
  my ( $taxa, $chars ) = split /\s+/, $header;

  my @seqs;
  while ( my $line = <$fh> ) {
    $line =~ s/\r\n/\n/;
    chomp $line;

    my ( $id, $seq_string );
    if ($relaxed) {
      ( $id, $seq_string ) = split /\s+/, $line, 2;
    } else {
      ( $id, $seq_string ) = unpack( 'A10A*', $line );
      $id =~ s/^\s*//;
      $id =~ s/\s*$//;
    }

    push @seqs, Bio::Gonzales::Seq->new( id => $id, seq => $seq_string );
  }

  return \@seqs;
}

sub _int_phylip_slurp {
  my ( $fh, $relaxed ) = @_;

  my $header = <$fh>;
  $header =~ s/\r\n/\n/;
  chomp $header;
  my ( $taxa, $chars ) = split /\s+/, $header;

  my @idseq_strings;
  my $i = 0;
  while ( my $line = <$fh> ) {
    $line =~ s/\r\n/\n/;
    chomp $line;
    next if ( $line =~ /^\s*$/ );

    my $idx = $i++ % $taxa;

    $idseq_strings[$idx] .= $line;
  }

  my @seqs;
  for my $idseq_string (@idseq_strings) {
    my ( $id, $seq_string );
    if ($relaxed) {
      ( $id, $seq_string ) = split /\s+/, $idseq_string, 2;
    } else {
      ( $id, $seq_string ) = unpack( 'A10A*', $idseq_string );
      $id =~ s/^\s*//;
      $id =~ s/\s*$//;
    }

    push @seqs, Bio::Gonzales::Seq->new( id => $id, seq => $seq_string );
  }

  return \@seqs;
}

1;

__END__

=head1 NAME

Bio::Gonzales::Align::Util - Utility functions for aligment stuff

=head1 SYNOPSIS

    use Bio::Gonzales::Align::Util qw(phylip_spew);

=head1 DESCRIPTION

=head1 OPTIONS

=head1 SUBROUTINES

=over 4

=item B<< phylip_spew($file_or_fh, $mode, $seqs)  >>

Spew out the seqs to a file or file handle. Following modes are available:

=over 4

=item s|seq|sequential

Sequential format, cuts of the ID at 10 characters starting from the beginning

=item r|relax|relaxed s|seq|sequential

The relaxed phylip format.

=back

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
