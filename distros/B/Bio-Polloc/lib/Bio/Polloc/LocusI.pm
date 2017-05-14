=head1 NAME

Bio::Polloc::LocusI - Interface of C<Bio::Polloc::Locus::*> objects

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::Polloc::Root>

=back

=cut

package Bio::Polloc::LocusI;
use strict;
use base qw(Bio::Polloc::Polloc::Root);
use Bio::Polloc::RuleI;
use Bio::Polloc::Polloc::IO;
use List::Util qw(min max);
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   if($class !~ m/Bio::Polloc::Locus::(\S+)/){
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      my($type) = $bme->_rearrange([qw(TYPE)], @args);
      
      if($type){
         $type = Bio::Polloc::LocusI->_qualify_type($type);
         $class = "Bio::Polloc::Locus::" . $type if $type;
      }
   }

   if($class =~ m/Bio::Polloc::Locus::(\S+)/){
      my $load = 0;
      if(Bio::Polloc::RuleI->_load_module($class)){
         $load = $class;
      }elsif(Bio::Polloc::RuleI->_load_module("Bio::Polloc::Locus::generic")){
         $load = "Bio::Polloc::Locus::generic";
      }
      
      if($load){
         my $self = $load->SUPER::new(@args);
	 $self->debug("Got the LocusI class $load");
	 my($from,$to,$strand,$name,$rule,$seq,
	 	$id,$family,$source,$comments,$genome,$seqname) =
	 	$self->_rearrange(
	 	[qw(FROM TO STRAND NAME RULE SEQ ID FAMILY SOURCE COMMENTS GENOME SEQNAME)],
		@args);
	 $self->from($from);
	 $self->to($to);
	 $self->strand($strand);
	 $self->name($name);
	 $self->rule($rule);
	 $self->seq($seq);
	 $self->id($id);
	 $self->family($family);
	 $self->source($source);
	 $self->comments($comments);
	 $self->genome($genome);
	 $self->seq_name($seqname);
         $self->_initialize(@args);
         return $self;
         
      }
      
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   }
   my $bme = Bio::Polloc::Polloc::Root->new(@args);
   $bme->throw("Impossible to load the proper Bio::Polloc::LocusI class with ".
   		"[".join("; ",@args)."]", $class);
}

=head2 type

Gets/sets the type of rule

B<Arguments>

Value (str).  Can be: pattern, profile, repeat, similarity, coding. composition, crispr
Some variations can be introduced, like case variations or short versions like B<patt>
or B<rep>.

B<Return>

Value (str).  The type of the rule, or null if undefined.  The value returned is undef
or a string from the above list, regardless of the input variations.

B<Throws>

L<Bio::Polloc::Polloc::Error> if an unsupported type is received.

=cut

sub type {
   my($self,$value) = @_;
   if($value){
      my $v = $self->_qualify_type($value);
      $self->throw("Attempting to set an invalid type of locus",$value) unless $v;
      $self->{'_type'} = $v;
   }
   return $self->{'_type'};
}

=head2 genome

Sets/gets the source genome as a L<Bio::Polloc::Genome> object.

B<Throws>

L<Bio::Polloc::Polloc::Error> if unexpected type.

=cut

sub genome {
   my($self,$value) = @_;
   $self->{'_genome'} = $value if defined $value;
   return unless defined $self->{'_genome'};
   $self->throw("Unexpected type of genome", $self->{'_genome'})
   	unless UNIVERSAL::can($self->{'_genome'},'isa')
	and $self->{'_genome'}->isa('Bio::Polloc::Genome');
   return $self->{'_genome'};
}

=head2 name

Sets/gets the name of the locus

B<Arguments>

Name (str), the name to set

B<Returns>

The name (str or undef)

=cut

sub name {
   my($self,$value) = @_;
   $self->{'_name'} = $value if defined $value;
   return $self->{'_name'};
}


=head2 aliases

Gets the alias names

B<Returns>

Aliases (arr reference or undef)

=cut

sub aliases { return shift->{'_aliases'}; }


=head2 add_alias

B<Arguments>

One or more alias names (str)

=cut

sub add_alias {
   my($self,@values) = @_;
   $self->{'_aliases'} ||= [];
   push(@{$self->{'_aliases'}}, @values);
}

=head2 parents

Gets the parent features or loci

B<Returns>

Parents (arr reference or undef)

=cut

sub parents { return shift->{'_parents'}; }

=head2 add_parent

B<Arguments>

One or more parent object (C<Bio::Polloc::LocusI>)

B<Throws>

L<Bio::Polloc::Polloc::Error> if some argument is not L<Bio::Polloc::LocusI>

=cut

sub add_parent {
   my($self,@values) = @_;
   $self->{'_parents'} ||= [];
   for(@values){ $self->throw("Illegal parent class '".ref($_)."'",$_)
   	unless $_->isa('Bio::Polloc::LocusI') }
   push(@{$self->{'_aliases'}}, @values);
}

=head2 target

Gets/sets the target of the alignment, if the feature is some alignment

B<Arguments>

=over

=item -id

The ID of the target sequence

=item -from

The start on the target sequence

=item -to

The end on the target sequence

=item -strand

The strand of the target sequence

=back

B<Returns>

A hash reference like C<{B<id>=E<gt>id, B<from>=E<gt>from, B<to>=E<gt>to,
B<strand>=E<gt>strand}>

=cut

sub target {
   my($self,@args) = @_;
   if($#args>=0){
      my($id,$from,$to,$strand) = $self->_rearrange([qw(ID FROM TO STRAND)], @args);
      $self->{'_target'} = {'id'=>$id, 'from'=>$from, 'to'=>$to, 'strand'=>$strand};
   }
   return $self->{'_target'};
}

=head2 comments

Gets/sets the comments on the locus, newline-separated

B<Arguments>

New comments to add (str)

B<Returns>

Comments (str)

=cut

sub comments {
   my($self,@comments) = @_;
   if($#comments>=0){
      $self->{'_comments'} ||= "";
      for(@comments) { $self->{'_comments'} .= "\n" . $_ if defined $_ }
      $self->{'_comments'} =~ s/^\n+//;
      $self->{'_comments'} =~ s/\n+$//; #<- Just in case it gets an empty comment
   }
   return $self->{'_comments'};
}

=head2 xrefs

Gets the cross references of the locus

B<Returns>

Array reference or undef

=cut

sub xrefs { return shift->{'_xrefs'} }

=head2 add_xref

Adds a cross reference

B<Arguments>

One or more cross references in GFF3 format

=cut

sub add_xref {
   my $self = shift;
   $self->{'_xrefs'} ||= [];
   push @{$self->{'_xrefs'}}, @_ if $#_>=0;
}

=head2 ontology_terms_str

Gets the ontology terms as explicit strings

B<Returns>

Array reference or undef

=cut

sub ontology_terms_str{ return shift->{'_ontology_terms_str'} }

=head2 add_ontology_term_str

Adds an ontology term by string

B<Arguments>

One or more strings

=cut

sub add_ontology_term_str {
   my $self = shift;
   push @{$self->{'_ontology_terms_str'}}, @_ if $#_>=0;
}


=head2 from

Gets/sets the B<from> position

B<Arguments>

Position (int, optional)

B<Returns>

The B<from> position (int, -1 if undefined)

=cut

sub from {
   my($self,$value) = @_;
   $self->{'_from'} ||= -1;
   $self->{'_from'} = $value+0 if defined $value;
   return $self->{'_from'};
}


=head2 to

Gets/sets the B<to> position

B<Arguments>

Position (int, optional)

B<Returns>

The B<to> position (int, -1 if undefined)

=cut

sub to {
   my($self,$value) = @_;
   $self->{'_to'} ||= -1;
   $self->{'_to'} = $value+0 if defined $value;
   return $self->{'_to'};
}

=head2 length

Gets the length of the locus.

B<Returns>

I<int> or C<undef>.

=cut

sub length {
   my $self = shift;
   return unless defined $self->from and defined $self->to;
   return abs($self->to - $self->from);
}

=head2 id

Gets/sets the ID of the locus

B<Arguments>

ID (str)

B<Returns>

ID (str)

=cut

sub id {
   my($self,$value) = @_;
   $self->{'_id'} = $value if defined $value;
   return $self->{'_id'};
}


=head2 family

Sets/gets the family of features.  I<I.e.>, a name identifying the type of locus.
A common family is B<CDS>, but other families can be defined.  Note that the family
is not qualified by the software used for the prediction (use C<source()> for that).

B<Arguments>

The family (str, optional)

B<Returns>

The family (str)

B<Note>

This method tries to locate the family by looking (in that order) at:

=over

=item 1

The explicitly defined family.

=item 2

The prefix of the ID (asuming it was produced by some L<Bio::Polloc::RuleI> object).

=item 3

The type of the rule (if the rule is defined).

=item 4

If any of the former options work, returns B<unknown>.

=back

=cut

sub family {
   my($self,$value) = @_;
   $self->{'_family'} = $value if defined $value;
   unless(defined $self->{'_family'} or not defined $self->id){
      if($self->id =~ m/(.*):\d+\.\d+/){
         $self->{'_family'} = $1;
      }
   }
   $self->{'_family'} = $self->rule->type if not defined $self->{'_family'} and defined $self->rule;
   return 'unknown' unless defined $self->{'_family'};
   return $self->{'_family'};
}

=head2 source

Sets/gets the source of the feature.  For example, the software used.

B<Arguments>

The source (str, optional).

B<Returns>

The source (str).

B<Note>

This method tries to locate the source looking (in that order) at:

=over

=item 1

The explicitly defined value.

=item 2

The source of the rule (if defined).

=item 3

If any of the above, returns B<polloc>.

=back

=cut

sub source {
   my($self,$value) = @_;
   $self->{'_source'} = $value if defined $value;
   $self->{'_source'} = $self->rule->source
   	if not defined $self->{'_source'} and defined $self->rule;
   return 'polloc' if not defined $self->{'_source'};
   return $self->{'_source'};
}

=head2 strand

Gets/sets the strand

B<Arguments>

Strand (str: B<+>, B<-> or B<.>)

B<Returns>

The strand (str)

=cut

sub strand {
   my($self,$value) = @_;
   $self->{'_strand'} ||= '.';
   $self->{'_strand'} = $value if defined $value;
   return $self->{'_strand'};
}

=head2 rule

Gets/sets the origin rule

B<Arguments>

A L<Bio::Polloc::RuleI> object

B<Returns>

A L<Bio::Polloc::RuleI> object

B<Throws>

L<Bio::Polloc::Polloc::Error> if the argument is not of the proper class

=cut

sub rule {
   my($self,$value) = @_;
   if(defined $value){
      $self->throw("Unexpected class of argument '".ref($value)."'",$value)
      		unless $value->isa('Bio::Polloc::RuleI');
      $self->{'_rule'} = $value;
   }
   return $self->{'_rule'};
}


=head2 score

Sets/gets the score of the feature.  Most loci implement
different score functions, and it's often read-only.

B<Returns>

The score (float)

B<Throws>

L<Bio::Polloc::Polloc::NotImplementedException> if not implemented

=cut

sub score {
   my($self,$value) = @_;
   my $k = '_score';
   $self->{$k} = $value if defined $value;
   return $self->{$k};
}

=head2 seq

Sets/gets the sequence

B<Arguments>

The sequence (Bio::Seq object, optional)

B<Returns>

The sequence (Bio::Seq object or undef)

B<Throws>

L<Bio::Polloc::Polloc::Error> if the sequence is not Bio::Seq

B<Note>

This method returns the full original sequence, not the piece of sequence with the target

=cut
sub seq {
   my($self,$seq) = @_;
   if(defined $seq){
      $self->throw("Illegal type of sequence", $seq)
      		unless UNIVERSAL::can($seq, 'isa') and $seq->isa('Bio::Seq');
      $self->{'_seq'} = $seq;
   }
   if(not defined $self->{'_seq'} and defined $self->{'_seq_name'} and defined $self->genome){
      $self->{'_seq'} = $self->genome->search_sequence($self->seq_name);
   }
   return $self->{'_seq'};
}

=head2 seq_name

Gets/sets the name of the sequence

B<Arguments>

The name of the sequence (str, optional).

B<Returns>

The name of the sequence (str or C<undef>).

=cut

sub seq_name {
   my($self, $value) = @_;
   $self->{'_seq_name'} = $value if defined $value;
   if(not defined $self->{'_seq_name'} and defined $self->seq){
      $self->{'_seq_name'} = $self->seq->display_id;
   }
   return $self->{'_seq_name'};
}

=head2 stringify

B<Purpose>

To provide an easy method for the (str) description of any L<Bio::Polloc::LocusI> object.

B<Returns>

The stringified object (str, off course)

=cut

sub stringify {
   my($self,@args) = @_;
   my $out = ucfirst $self->type;
   $out.= " '" . $self->id . "'" if defined $self->id;
   $out.= " at [". $self->from. "..". $self->to . $self->strand ."]";
   return $out;
}

=head2 context_seq

Extracts a sequence from the context of the locus

B<Arguments>

All the following arguments are mandatory, and must be passed in that order:

=over

=item *

ref I<int> :
  -1 to use the start as reference (useful for upstream sequences),
  +1 to use the end as reference (useful for downstream sequences),
   0 to use the start as start reference and the end as end reference

=item *

from I<int> : The relative start position.

=item *

to I<int> : The relative end position.

=back

B<Returns>

A L<Bio::Seq> object.

=cut

sub context_seq {
   my ($self, $ref, $from, $to) = @_;
   $self->_load_module('Bio::Polloc::GroupCriteria');
   return unless defined $self->seq and defined $self->from and defined $self->to;
   my $seq;
   my ($start, $end);
   my $revcom = 0;
   if($ref < 0){
      if($self->strand eq '?' or $self->strand eq '+'){
	 # (500..0)--------------->*[* >> ft >> ]
	 $start = $self->from - $from;	$end = $self->from - $to;
      }else{
	 # [ << ft << *]*<-----------------(500..0)
	 $start = $self->to + $to;	$end = $self->to + $from;	$revcom = !$revcom;
      }
   }elsif($ref > 0){
      if($self->strand eq '?' or $self->strand eq '+'){
	 # [ >> ft >> *]*<-----------------(500..0)
	 $start = $self->to + $to;	$end = $self->to + $from;	$revcom = !$revcom;
      }else{
	 # (500..0)--------------->*[* << ft << ]
	 $start = $self->from - $from;		$end = $self->from - $to;
      }
   }else{
      if($self->strand eq '?' or $self->strand eq '+'){
	 $start = $self->from + $from;	$end = $self->to + $from;
      }else{
	 $start = $self->to - $from;	$end = $self->from - $to;
      }
   }
   $start = max(1, $start);
   $end = min($self->seq->length, $end);
   $self->debug("Extracting context ".
   		(defined $self->seq->display_id?$self->seq->display_id:'').
		"[$start..$end] ".($revcom?"-":"+"));
   $seq = Bio::Polloc::GroupCriteria->_build_subseq($self->seq, $start, $end);
   return unless defined $seq;
   $seq = $seq->revcom if $revcom;
   return $seq;
}

=head2 distance

Calculates the distance (referring to diversity, not genomic position) with the
given locus.

B<Arguments>

=over

=item -locus I<Bio::Polloc::LocusI object>

The locus to compare with.  Most of the locus types require this locus to be of
the same type.

=item -locusref I<Bio::Polloc::LocusI object>

The reference locus.  If set, replaces the loaded object as reference.

=back

B<Returns>

Float.  The distance with the given locus.  Most types will return a distance ranging
from one to zero.

B<Note>

See the documentation for additional arguments and precisions.

B<Throws>

L<Bio::Polloc::Polloc::NotImplementedException> if not implemented by the correspondig class.

=cut

sub distance { $_[0]->throw("score",$_[0],"Bio::Polloc::Polloc::NotImplementedException") }


=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _qualify_type

Uniformizes the distinct names that every type can receive

B<Arguments>

The requested type (str)

B<Returns>

The qualified type (str or undef)

=cut

sub _qualify_type {
   my($self,$value) = @_;
   return unless $value;
   $value = lc $value;
   $value = "pattern" if $value=~/^(patt(ern)?)$/;
   $value = "profile" if $value=~/^(prof(ile)?)$/;
   $value = "repeat" if $value=~/^(rep(eat)?)$/;
   $value = "similarity" if $value=~/^((sequence)?sim(ilarity)?|homology|ident(ity)?)$/;
   $value = "coding" if $value=~/^(cod|cds)$/;
   $value = "composition" if $value=~/^(comp(osition)?|content)$/;
   return $value;
   # TRUST IT! if $value =~ /^(pattern|profile|repeat|similarity|coding|composition|crispr)$/;
}

=head2 _initialize

=cut

sub _initialize {
   my $self = shift;
   $self->throw("_initialize", $self, "Bio::Polloc::Polloc::NotImplementedException");
}

1;
