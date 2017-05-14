package Bio::Gonzales::Seq;

use Mouse;

use overload '""' => 'all';
use Carp;
use Data::Dumper;
use Bio::Gonzales::Seq::IO;

our $VERSION = '0.0546'; # VERSION

has id     => ( is => 'rw', required   => 1 );
has desc   => ( is => 'rw', default    => '' );
has seq    => ( is => 'rw', required   => 1 );
has delim  => ( is => 'rw', default    => " " );
has info   => ( is => 'rw', default    => sub { {} } );
has gaps   => ( is => 'rw', lazy_build => 1 );
has length => ( is => 'rw', lazy_build => 1 );

sub _build_gaps {
  my $gaps = ( shift->seq() =~ tr/-.// );
  return $gaps;
}

sub _build_length {
  return CORE::length( shift->seq() );
}

sub BUILDARGS {
  my $class = shift;

  my %a;
  if ( scalar @_ == 1 ) {
    ( ref( $_[0] ) eq 'HASH' )
      || $class->meta->throw_error("Single parameters to new() must be a HASH ref");
    %a = %{ $_[0] };
  } else {
    %a = @_;
  }

  delete $a{delim}
    if ( exists( $a{delim} ) && !defined( $a{delim} ) );
  delete $a{desc}
    if ( exists( $a{desc} ) && !defined( $a{desc} ) );

  $a{seq} = _filter_seq( $a{seq} );

  return \%a;
}

sub def {
  my ($self) = @_;

  return join( $self->delim, $self->id, $self->desc );
}

before 'desc' => sub {
  my $self = shift;

  if ( @_ == 1 && $_[0] eq '' ) {
    $self->delim('');
  }
};

sub _filter_seq {
  my ($seq) = @_;

  $seq = join( "", @$seq )
    if ( ref($seq) eq 'ARRAY' );
  $seq =~ y/ \t\n\r\f//d;

  return $seq;
}

around 'seq' => sub {
  my $orig = shift;
  my $self = shift;

  return $self->$orig()
    unless @_;

  return $self->$orig( _filter_seq(@_) );
};

sub gapless_seq {
  my ($self) = @_;

  my $seq = $self->seq;
  $seq =~ tr/-.//d;
  return $seq;
}

sub rm_gaps {
  my ($self) = @_;
  
  $self->seq($self->gapless_seq);
  return $self;
}

sub clone {
  my ($self) = @_;

  return __PACKAGE__->new( id => $self->id, desc => $self->desc, seq => $self->seq, delim => $self->delim );
  #shift->clone_object(@_)
}

sub clone_empty {
  my ($self) = @_;

  return __PACKAGE__->new( id => $self->id, desc => $self->desc, seq => '', delim => $self->delim );
}

sub display_id { shift->id(@_) }

sub ungapped_length {
  my ($self) = @_;

  return $self->length - $self->gaps;
}

sub sequence { shift->seq(@_) }

sub all {
  my ($self) = @_;

  return ">" . $self->id . ( $self->desc ? $self->delim . $self->desc : "" ) . "\n" . $self->seq . "\n";
}

sub all_formatted {
  my ($self) = @_;

  return
      ">"
    . $self->id
    . ( $self->desc ? $self->delim . $self->desc : "" ) . "\n"
    . Bio::Gonzales::Seq::IO::format_seq_string( $self->seq );
}

sub all_pretty { shift->all_formatted(@_) }

sub pretty { shift->all_formatted(@_) }

sub as_primaryseq {
  my ($self) = @_;

  return Bio::PrimarySeq->new(
    -seq      => $self->seq,
    -id       => $self->id,
    -desc     => $self->desc,
    -alphabet => $self->guess_alphabet,
    -direct   => 1,
  );
}

sub guess_alphabet {
  my ($self) = @_;

  my $str = $self->seq();
  $str =~ s/[-.?*]//gi;

  my $alphabet;

  # Check for sequences without valid letters
  my $total = CORE::length($str);

  if ( $str =~ m/[EFIJLOPQXZ]/i ) {
    # Start with a safe method to find proteins.
    # Unambiguous IUPAC letters for proteins are: E,F,I,J,L,O,P,Q,X,Z
    $alphabet = 'protein';
  } else {
    # Alphabet is unsure, could still be DNA, RNA or protein.
    # DNA and RNA contain mostly A, T, U, G, C and N, but the other letters
    # they use are also among the 15 valid letters that a protein sequence
    # can contain at this stage. Make our best guess based on sequence
    # composition. If it contains over 70% of ACGTUN, it is likely nucleic.
    if ( ( $str =~ tr/ATUGCNatugcn// ) / $total > 0.7 ) {
      if ( $str =~ m/U/i ) {
        $alphabet = 'rna';
      } else {
        $alphabet = 'dna';
      }
    } else {
      $alphabet = 'protein';
    }
  }
  return $alphabet;
}

sub revcom {
  my ($self) = @_;

  $self->seq( _revcom_from_string( $self->seq, $self->guess_alphabet ) );

  return $self;
}

sub subseq {
  my ( $self, $range, $c ) = @_;

  my ( $seq, $corrected_range ) = $self->subseq_as_string( $range, $c );
  my ( $b, $e, $strand, @rest ) = @$corrected_range;

  my $keep_original_id = $c->{keep_id};

  my $new_seq = $self->clone_empty;
  $new_seq->seq($seq);

  if ( $c->{attach_details} ) {
    my $info = $new_seq->info;
    $info->{subseq} = { from => $b + 1, to => $e };
    $info->{subseq}{strand} = ( $strand < 0 ? '-' : ( $strand > 0 ? '+' : '.' ) );
    $info->{subseq}{rest} = \@rest if ( @rest > 0 );
  }

  unless ($keep_original_id) {
    $new_seq->id( $new_seq->id . "|" . ( $b + 1 ) . "..$e" );
    $new_seq->id( $new_seq->id . "|" . ( $strand < 0 ? '-' : ( $strand > 0 ? '+' : '.' ) ) )
      if ( defined($strand) );    #print also nothing if strand == 0
    $new_seq->id( $new_seq->id . "|" . join( "|", @rest ) ) if ( @rest > 0 );
  }
  return $new_seq;
}

sub subseq_as_string {
  my ( $self, $range, $c ) = @_;

  confess "you use the deprecated version of subseq" if ( defined($c) && ref $c ne 'HASH' );

  my ( $b, $e, $strand, @rest ) = @$range;
  if ( $c->{relaxed_range} ) {
    #if b or e are not defined, just take the beginning and end as given
    #warn "requested invalid subseq range ($b,$e;$strand) from " . $self->id . ", using relaxed boundaries."
      #unless ( $b && $e );
    $b ||= '^';
    $e ||= '$';
  }

  confess "requested invalied subseq range ($b,$e;$strand) from "
    . $self->id . "\n"
    . Dumper($range)
    . Dumper( $self->clone_empty )
    unless ( $b && $e );

  my $seq_len = $self->length;

  $b = 1        if ( $b eq '^' );
  $b = $seq_len if ( $b eq '$' );

  $e = 1        if ( $e eq '^' );
  $e = $seq_len if ( $e eq '$' );

  croak "subseq range error: $b > $e" if ( $b > $e && $b > 0 && $e > 0 );

  #count from the end,
  if ( $b < 0 ) {
    $b = $c->{wrap} ? $seq_len + $b + 1 : 1;
  }
  if ( $e < 0 ) {
    $e = $c->{wrap} ? $seq_len + $e + 1 : $seq_len;
  }

  #get the index right for substr.
  $b--;

  my $seq = substr( $self->{seq}, $b, $e - $b );

  if ( $strand && $strand < 0 ) {
    if ( $c->{relaxed_revcom} ) {
      $seq =~ y/AGCTNagctn/N/c;
    } else {
      confess "cannot create reverse complement, sequence contains non-AGCTN characters"
        if ( $seq =~ /[^AGCTN]/i );
    }

    $seq = _revcom_from_string($seq, $self->_guess_alphabet);
  }

  return wantarray ? ( $seq, [ $b, $e, $strand, @rest ] ) : $seq;
}

sub _revcom_from_string {
   my ($string, $alphabet) = @_;

   # Check that reverse-complementing makes sense
   if( $alphabet eq 'protein' ) {
       confess("Sequence is a protein. Cannot revcom.");
   }
   if( $alphabet ne 'dna' && $alphabet ne 'rna' ) {
      carp "Sequence is not dna or rna, but [$alphabet]. Attempting to revcom, ".
                "but unsure if this is right.";
   }

   # If sequence is RNA, map to DNA (then map back later)
   if( $alphabet eq 'rna' ) {
       $string =~ tr/uU/tT/;
   }

   # Reverse-complement now
   $string =~ tr/acgtrymkswhbvdnxACGTRYMKSWHBVDNX/tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX/;
   $string = CORE::reverse $string;

   # Map back RNA to DNA
   if( $alphabet eq 'rna' ) {
       $string =~ tr/tT/uU/;
   }

   return $string;
}

1;

__END__

=head1 NAME

Bio::Gonzales::Seq - Gonzales Sequence Object

=head1 SYNOPSIS

    my $seq = Bio::Gonzales::Seq->new(id => $id, seq => $seq, desc? => '', delim? => ' ');

    print $seq->def;
    print $seq->desc;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<< $seq->id >>

=item B<< $seq->desc >>

The description of a sequence object. In case of FASTA-files, this corresponds
to the text after the first space.

=item B<< $seq->seq >>

=item B<< $seq->delim >>

=item B<< $seq->info >>

An hash of additional stuff you can store about the sequence

=item B<< $seq->gaps >>

=item B<< $seq->length >>

=item B<< $seq->def >>

The definition also known as the FASTA header line w/o ">"

=item B<< $seq->clone >>

Clone the sequence

=item B<< $seq->clone_empty >>

Clone the sequence properties, do not clone the sequence string.

=item B<< $seq->display_id >>

Same as C<$seq->id>

=item B<< $seq->ungapped_length >>

=item B<< $seq->all >>

=item B<< "$seq" >>

The complete sequence in fasta format, ready to be written.

=item B<< $seq->all_formatted >>

=item B<< $seq->all_pretty >>

The complete sequence in I<pretty> fasta format, ready to be written.

=item B<< $seq->as_primaryseq >>

Return a Bio::PrimarySeqI compatible object, so you can use it in BioPerl.

=item B<< $seq_string = $seq->gapless_seq >>

=item B<< $seq->rm_gaps! >>

=item B<< $seq->revcom >>

Create the reverse complement of the sequence. B<THIS FUNCTION ALTERS THE SEQUENCE OBJECT>.

=item B<< $seq->subseq( [ $begin, $end, $strand , @rest ], \%c ) >>

Gets a subseq from C<$seq>. Config options can be:

    %c = (
        keep_id => 1, # keeps the original id of the sequence
        attach_details => 1, # keeps the original range and strand in $seq->info->{subseq}
        wrap => 1, # see further down
        relaxed_range => 1, # substitute 0 or undef for $begin with '^' and for $end with '$'
        relaxed_revcom => 1, # substitute N for all characters that are non-AGCTN before doing a reverse complement
    );

There are several possibilities for C<$begin> and C<$end>:

    GGCAAAGGA ATGATGGTGT GCAGGCTTGG CATGGGAGAC
    ^..........^                                (1,11) OR ('^', 11)
       ^.....................................^  (4,'$')
                          ^..............^      (21,35) { with wrap on: OR (-19,35) OR (-19, -5) }
                          ^..................^  (21,35) { with wrap on: OR (-19,'$') }
    
=over 4

=item C<wrap>

The default is to limit all negative
values to the sequence boundaries, so a negative begin would be equal to 1 or
'^' and a negative end would be equal to '$'.

=back

See also L<Bio::Gonzales::Seq::IO/fasubseq>.

=back

=over 4

=item B<< my $reverse_complement_string = Bio::Gonzales::Seq::_revcom_from_string($seq_string, $alphabet) >>

Stolen from L<Bio::Perl>. Alphabet can be 'rna' or 'dna';

=back

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
