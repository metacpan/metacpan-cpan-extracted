package Stone::GB_Sequence;

use strict;
use Carp;
use vars '@ISA';

=head1 NAME

Stone::GB_Sequence - Specialized Access to GenBank Records

=head1 SYNOPSIS

  use Boulder::Genbank;  # No need to use Stone::GB_Sequence directly
  $gb = Boulder::Genbank->newFh qw(M57939 M28274 L36028);

  while ($entry = <$gb>) {
    print "Entry's length is ",$entry->length,"\n";
    @cds   = $entry->match_features(-type=>'CDS');
    @exons = $entry->match_features(-type=>'Exon',-start=>100,-end=>300);
  }
}

=head1 DESCRIPTION

Stone::GB_Sequence provides several specialized access methods to the
various fields in a GenBank flat file record.  You can return the
sequence as a Bio::Seq object, or query the sequence for features that
match positional or descriptional criteria that you provide.

=head1 CONSTRUCTORS

This class is not intended to be created directly, but via a
L<Boulder::Genbank> stream.

=head1 METHODS

In addition to the standard L<Stone> methods and accessors, the
following methods are provided.  In the synopses, the variable
C<$entry> refers to a previously-created Stone::GB_Sequence object.

=head2 $length = $entry->length

Get the length of the sequence.

=head2 $start = $entry->start

Get the start position of the sequence, currently always "1".

=head2 $end = $entry->end

Get the end position of the sequence, currently always the same as the
length.

=head2 @feature_list = $entry->features(-pos=>[50,450],-type=>['CDS','Exon'])

features() will search the entry feature list for those features that
meet certain criteria.  The criteria are specified using the B<-pos>
and/or B<-type> argument names, as shown below.

=over 4

=item -pos

Provide a position or range of positions which the feature must
B<overlap>.  A single position is specified in this way:

   -pos => 1500;         # feature must overlap postion 1500

or a range of positions in this way:

   -pos => [1000,1500];  # 1000 to 1500 inclusive

If no criteria are provided, then features() returns all the features,
and is equivalent to calling the Features() accessor.

=item -type, -types

Filter the list of features by type or a set of types.  Matches are
case-insensitive, so "exon", "Exon" and "EXON" are all equivalent.
You may call with a single type as in:

   -type => 'Exon'

or with a list of types, as in

   -types => ['Exon','CDS']

The names "-type" and "-types" can be used interchangeably.

=head2 $seqObj = $entry->bioSeq;

Returns a L<Bio::Seq> object from the Bioperl project.  Dies with an
error message unless the Bio::Seq module is installed.

=back

=head1 AUTHOR

Lincoln D. Stein <lstein@cshl.org>.

=head1 COPYRIGHT

Copyright 1997-1999, Cold Spring Harbor Laboratory, Cold Spring Harbor
NY.  This module can be used and distributed on the same terms as Perl
itself.

=head1 SEE ALSO

L<Boulder>, L<Boulder:Genbank>, L<Stone>

=cut

@ISA = 'Stone';

# -------------------- h'mmmmm, bogus alert! --------------------
# Return list of all features that overlap a particular range
#
# Example:
#    @features = $gb->grab_features(-pos=>[50,450],-types=>['CDS','Exon'])
#
sub features {
  my $self = shift;
  my %param = @_;
  my %p;
  @p{map {s/^-//; s/s$//; lc $_} keys %param} = values %param;

  my $f = $self->Features;

  # regularize coordinates
  my $pos = $p{po};
  my ($left,$right) = ref($pos) ? @$pos : $pos;
  $left  ||= 0;
  $right ||= $left;
  ($left,$right) = ($right,$left) if $left > $right;

  # regularize types
  my @types = ref $p{type} ? @{$p{type}} : $p{type} if $p{type};
  @types = $f->tags unless @types;
  
  # flatten into a list of all features of the specified type(s)
  my @features;
  for my $t (@types) {
    my @f = $f->get("\u\L$t");
    foreach (@f) { $_->insert(Type=>$t) unless $_->get('Type'); }
    push @features,@f;
  }

  
  @features =  grep { _overlap_filter($_,$left,$right) } @features 
    if $left > 0 || $right > 0;

  return @features;
}

sub length {
  my $self = shift;
  return length $self->Sequence;
}

sub start { 1; }

sub end { $_[0]->length }

sub bioSeq {
  my $self = shift;
  my $id   = $self->Accession;
  my $seq  = $self->Sequence;
  my $desc = $self->Definition;

  eval { require Bio::Seq } || croak "Bio::Seq module not installed";
  return Bio::Seq->new(-id=>$id,-sequence=>$seq,-desc=>$desc);
}

sub _feature_filter {
  my $f = shift;
  my $types = shift;
  foreach (@$types) {
    return 1 if $f->get("\u\L$_");
  }
  return;
}

sub _overlap_filter {  # assumes left and right are numerically sorted
  my $f = shift;
  my ($left,$right) = @_;
  return unless my $p = $f->Position;

  # simplest case -- single position
  if ($p =~ /^(\d+)$/) {  
    return 1 if $1 >= $left and $1 <= $right;
  }

  # another simple case -- either/or
  if ($p =~ /^(\d+)[.^](\d+)$/) {  
    return 1 if $1 == $left || $2 == $left || $1 == $right || $2 == $right;
  }

  # next simplest case -- a range
  if ($p =~ /^<?(\d+)\.\.>?(\d+)$/) { 
    ($2,$1) = ($1,$2) if $1 > $2;
    return 1 if ($left >= $1 and $left <= $2) or ($right >= $1 and $left <= $2);
  }
  
  # complex case, a join(), order() or group()
  # not sure this is handled correctly in all the crazy combos
  if ($p =~ /^(?:join|order|group)/) {

    $p =~ s/\((\d)+\.\d+\)\.\./$1../g;   # (1.10)..  => 1..
    $p =~ s/\.\.\(\d+\.(\d+)\)/..$1/g;   # ..(1.10) => ..10

    my @ranges = $p =~ /[(),](<?\d+\.\.>?\d+)/g;
    foreach (@ranges) {
      next unless /<?(\d+)\.\.>?(\d+)/;
      ($2,$1) = ($1,$2) if $1 > $2;
      return 1 if ($left >= $1 and $left <= $2) or ($right >= $1 and $left <= $2);
    }
  }

  return;
}

1;

__END__
