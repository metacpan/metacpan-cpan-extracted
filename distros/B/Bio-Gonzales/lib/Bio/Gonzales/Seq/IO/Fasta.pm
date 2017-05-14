package Bio::Gonzales::Seq::IO::Fasta;


use warnings;
use strict;

use Mouse;
with 'Bio::Gonzales::Util::Role::FileIO';

use Bio::Gonzales::Seq;
use Bio::Gonzales::Util::File;

use Carp;

our $VERSION = '0.0546'; # VERSION

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && Bio::Gonzales::Util::File::is_fh( $_[0] ) ) {
    return $class->$orig( fh => $_[0] );
  } else {
    return $class->$orig(@_);
  }
};

sub BUILD {
  my ($self) = @_;

  my $fhi = $self->_fhi;

  my $line;
  while ( $line = $fhi->() ) { last if $line =~ /\S/ }    # not supposed to have blanks, but...

  my $firstline = $line;

  if ( not defined $firstline ) { carp "FASTA file is empty\n"; return $self }

  if ( $firstline !~ s/^>// ) { confess "Not FASTA formatted: >>$firstline<<\n"; }

  push @{ $self->_cached_records }, $firstline;
}

my $i = 0;

sub next_seq {
  my ($self) = @_;

  my $fhi = $self->_fhi;
  my $def = $fhi->();
  unless ($def) {
    $self->close;
    return;
  }

  my @seq;
  my $lines_read = 0;
  while ( defined( my $line = $fhi->() ) ) {
    $lines_read++;
    if ( $line =~ s/^>// ) {
      push @{ $self->_cached_records }, $line;
      last;
    }
    push @seq, $line;
  }
  if ( $lines_read == 0 ) {
    $self->close;
    return;

  }

  my ( $id, $delim, $desc ) = split( /(\s+)/, $def, 2 );
  my $entry = Bio::Gonzales::Seq->new( id => $id, delim => $delim, desc => $desc, seq => \@seq );
  return $entry;
}

1;
