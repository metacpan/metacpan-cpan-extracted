package Bio::Gonzales::Seq::IO;

use warnings;
use strict;
use Carp qw/cluck confess croak carp/;

use Bio::Gonzales::Seq::IO::Fasta;

use Data::Dumper;
use Bio::Gonzales::Util::File qw/open_on_demand/;
use Bio::Gonzales::Util qw/flatten/;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw(faslurp faspew fasubseq faiterate);
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(fahash);

our $WIDTH = 80;

our $SEQ_FORMAT = 'all';

sub faslurp {
  my ($src) = @_;

  my @fa;

  my ( $fh, $fh_was_open ) = open_on_demand( $src, '<' );

  my $fasta = Bio::Gonzales::Seq::IO::Fasta->new($fh);
  while ( my $entry = $fasta->next_seq ) {
    confess unless ($entry);
    push @fa, $entry;
  }

  $fh->close unless ($fh_was_open);

  return wantarray ? @fa : \@fa;
}

sub fasubseq {
  my ( $src, $ids_with_ranges, $c ) = @_;

  my $ids;
  if ( ref $ids_with_ranges eq 'ARRAY' ) {
    return unless (@$ids_with_ranges);

    if ( ref $ids_with_ranges->[0] eq 'ARRAY' ) {
      #array of array with id and range
      $ids = {};

      for my $idrange (@$ids_with_ranges) {
        my ( $id, @range ) = @$idrange;
        $ids->{$id} = [] unless defined $ids->{$id};
        push @{ $ids->{$id} }, \@range;
      }

    } else {
      #just plain ids
      $ids = { map { $_ => [] } @$ids_with_ranges };
    }
  }

  my ( $fh, $fh_was_open ) = open_on_demand( $src, '<' );

  my $fasta = Bio::Gonzales::Seq::IO::Fasta->new($fh);
  my @fa;
  while ( my $entry = $fasta->next_seq ) {
    if ( exists( $ids->{ $entry->id } ) ) {
      my $ranges = $ids->{ $entry->id };
      for my $range (@$ranges) {

        eval { push @fa, $entry->subseq( $range, $c ) };
        if ($@) {
          carp Dumper $entry->clone_empty;
          croak $@;
        }
      }

      #empty ranges array
      push @fa, $entry unless (@$ranges);
    }
  }
  $fh->close unless ($fh_was_open);

  return wantarray ? @fa : \@fa;
}

sub fahash {
  my $faraw = faslurp(@_);
  my %fa;
  for my $s (@$faraw) {
    confess "Dupicate entry: " . $s->id if ( exists( $fa{ $s->id } ) );
    $fa{ $s->id } = $s;
  }
  return wantarray ? %fa : \%fa;
}

sub faiterate {
  my @srcs = flatten(@_);

  confess "no arguments supplied" unless ( @srcs > 0 );
  my ( $fh, $fh_was_open ) = open_on_demand( shift(@srcs), '<' );
  my $fasta = Bio::Gonzales::Seq::IO::Fasta->new($fh);

  return sub {
    my $entry = $fasta->next_seq;
    unless ( defined($entry) ) {
      $fh->close unless ($fh_was_open);

      if ( my $src = shift @srcs ) {
        ( $fh, $fh_was_open ) = open_on_demand( $src, '<' );
        $fasta = Bio::Gonzales::Seq::IO::Fasta->new($fh);
      } else {
        return;
      }
    }
    return $entry;
  };
}

sub faspew {
  my ( $dest, @data ) = @_;

  #open destination, if necessary
  my ( $fh, $fh_was_open ) = open_on_demand( $dest, '>' );

  carp "no sequences supplied" unless ( @data > 0 );
  # take appropriate steps for the sequence objects
  for my $d (@data) {
    if ( ref $d eq 'HASH' ) {
      for my $e ( values %{$d} ) {
        print $fh $e->$SEQ_FORMAT;
      }
    } elsif ( ref $d eq 'ARRAY' ) {
      for my $e ( @{$d} ) {
        print $fh $e->$SEQ_FORMAT;
      }
    } elsif ( ref($d) eq 'Bio::Gonzales::Seq' ) {
      print $fh $d->$SEQ_FORMAT;
    } else {
      unless ($d) {
        cluck "Undefined argument supplied";
        next;
      }
      confess "error";
    }
  }
  $fh->close
    unless ($fh_was_open);
  return;
}

sub format_seq_string {
  my ($str) = @_;

  if ( defined $str && length($str) > 0 ) {
    $str =~ tr/ \t\n\r//d;            # Remove whitespace and numbers
    $str =~ s/\d+//g;
    $str =~ s/(.{1,$WIDTH})/$1\n/g;
    return $str;
  }
}


1;
__END__

=head1 NAME

Bio::Gonzales::Seq::IO - fast utility functions for sequence IO

=head1 SYNOPSIS

    use Bio::Gonzales::Seq::IO qw( faslurp faspew fahash fasubseq faiterate )

=head1 DESCRIPTION

=head1 SUBROUTINES

=over 4

=item B<< @seqs = faslurp(@filenames) >>

=item B<< $seqsref = faslurp(@filenames) >>

C<faslurp> reads in all sequences from C<@filenames> and returns an array in
list or an arrayref in scalar context of the read sequences. The sequences are
stored as FAlite2::Entry objects.

=item B<< $iterator = faiterate($filename) >>

Allows you to create an iterator for the fasta file C<$filename>. This
iterator can be used to loop over the sequence file w/o reading in all content
at once. Iterator usage:

    while(my $sequence_object = $iterator->()) {
        #do something with the sequence object
    }


=item B<< $seqs = fasubseq($file, \@ids_with_locations, \%c) >>

=item B<< $seqs = fasubseq($file, \@id_list, \%c) >>

    #ARRAY OF ARRAYS
    @ids_with_locations = (
        [ $id, $begin, $end, $strand ],
        ...
    );

Config options can be:

    %c = (
        keep_id => 1, # keeps the original id of the sequence
        wrap => 1, # see further down
        relaxed_range => 1, # substitute 0 or undef for $begin with '^' and for $end with '$'
    );


There are several possibilities for C<$begin> and C<$end>:

    GGCAAAGGA ATGATGGTGT GCAGGCTTGG CATGGGAGAC
    ^..........^                                (1,11) OR ('^', 11)
       ^.....................................^  (4,'$')
                          ^..............^      (21,35) { with wrap on: OR (-19,35) OR (-19, -5) }
                          ^..................^  (21,35) { with wrap on: OR (-19,'$') }
    
C<wrap>: The default is to limit all negative
values to the sequence boundaries, so a negative begin would be equal to 1 or
'^' and a negative end would be equal to '$'.

=item B<< $sref = fahash(@filenames) >>

=item B<< %seqs = fahash(@filenames) >>

Does the same as L<faslurp>, but returns an hash with the sequence ids as keys
and the sequence objects as values.

=item B<< faspew($file, $seq1, $seq2, ...) >>

"spew" out the given sequences to a file. Every C<$seqN> argument can be an
hash reference with L<FAlite2::Entry> objects as values or an array reference
of L<FAlite2::Entry> objects or just plain L<FAlite2::Entry> objects.
    
=item B<< $iterator = faspew_iterate($filename) >>

=item B<< $iterator = faspew_iterate($fh) >>

Creates an iterator that writes the sequences to the given C<$filename> or C<$fh>.

    for my $sequence_object (@sequences) {
        $iterator->($sequence_object)
    }
    #DO NOT FORGET THIS, THIS CALL WILL CLOSE THE FILEHANDLE
    $iterator->();

    #this is equal to:

    $iterator->(@sequences);
    $iterator->();
    #or
    $iterator->(\@sequences);
    $iterator->();


    #DO NOT DO THIS:

    $iterator->();

The filehandle will not be closed in case one supplies not a C<$filename> but a C<$fh> handle.

=back

=head1 ADVANCED

=over 4

=item B<< change the output format >>

    $Bio::Gonzales::Seq::IO::WIDTH = 60; #sequence width in fasta output

    #but only if set to 'all_pretty' ('all' is default)
    $Bio::Gonzales::Seq::IO::SEQ_FORMAT = 'all_pretty'; 

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
