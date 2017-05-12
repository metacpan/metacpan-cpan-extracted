package Ace::Sequence::Feature;
use strict;

use Ace qw(:DEFAULT rearrange);
use Ace::Object;
use Ace::Sequence::Homol;
use Carp;
use AutoLoader 'AUTOLOAD';
use vars '@ISA','%REV';
@ISA = 'Ace::Sequence';  # for convenience sake only
%REV = ('+1' => '-1',
	'-1' => '+1');  # war is peace, &c.

use overload 
  '""' => 'asString',
  ;

# parse a line from a sequence list
sub new {
  my $pack = shift;
  my ($parent,$ref,$r_offset,$r_strand,$abs,$gff_line,$db) = @_;
  my ($sourceseq,$method,$type,$start,$end,$score,$strand,$frame,$group) = split "\t",$gff_line;
  if (defined($strand)) {
    $strand = $strand eq '-' ? '-1' : '+1';
  } else {
    $strand = 0;
  }

  # for efficiency/performance, we don't use superclass new() method, but modify directly
  # handling coordinates.  See SCRAPS below for what should be in here
  $strand = '+1' if $strand < 0 && $r_strand < 0;  # two wrongs do make a right
  ($start,$end) = ($end,$start) if $strand < 0;
  my $offset = $start - 1;
  my $length = ($end > $start) ? $end - $offset : $end - $offset - 2;

  # handle negative strands
  $offset ||= 0;
  $offset *= -1 if $r_strand < 0 && $strand != $r_strand;

  my $self= bless {
		   obj      => $ref,
		   offset   => $offset,
		   length   => $length,
		   parent   => $parent,
		   p_offset => $r_offset,
		   refseq   => [$ref,$r_offset,$r_strand],
		   strand   => $r_strand,
		   fstrand  => $strand,
		   absolute => $abs,
		   info     => {
				seqname=> $sourceseq,
				method => $method,
				type   => $type,
				score  => $score,
				frame  => $frame,
				group  => $group,
				db     => $db,
			       }
		  },$pack;
  return $self;
}

sub smapped { 1; }

# $_[0] is field name, $_[1] is self, $_[2] is optional replacement value
sub _field {
  my $self = shift;
  my $field = shift;
  my $v = $self->{info}{$field};
  $self->{info}{$field} = shift if @_;
  return if defined $v && $v eq '.';
  return $v;
}

sub strand { return $_[0]->{fstrand} }

sub seqname   { 
  my $self = shift;
  my $seq = $self->_field('seqname');
  $self->db->fetch(Sequence=>$seq); 
}

sub method    { shift->_field('method',@_) }  # ... I prefer "method"
sub subtype   { shift->_field('method',@_) }  # ... or even "subtype"
sub type      { shift->_field('type',@_)   }  # ... I prefer "type"
sub score     { shift->_field('score',@_)  }  # float indicating some sort of score
sub frame     { shift->_field('frame',@_)  }  # one of 1, 2, 3 or undef
sub info      {                  # returns Ace::Object(s) with info about the feature
  my $self = shift;
  unless ($self->{group}) {
    my $info = $self->{info}{group} || 'Method "'.$self->method.'"';
    $info =~ s/(\"[^\"]*);([^\"]*\")/$1$;$2/g;
    my @data = split(/\s*;\s*/,$info);
    foreach (@data) { s/$;/;/g }
    $self->{group} = [map {$self->toAce($_)} @data];
  }
  return wantarray ? @{$self->{group}} : $self->{group}->[0];
}

# bioperl compatibility
sub primary_tag { shift->type(@_)    }
sub source_tag  { shift->subtype(@_) }

sub db { # database identifier (from Ace::Sequence::Multi)
  my $self = shift;
  my $db = $self->_field('db',@_);
  return $db || $self->SUPER::db;
}

sub group  { $_[0]->info; }
sub target { $_[0]->info; }

sub asString {
  my $self = shift;
  my $name = $self->SUPER::asString;
  my $type = $self->type;
  return "$type:$name";
}

# unique ID
sub id {
  my $self = shift;
  my $source = $self->source->name;
  my $start = $self->start;
  my $end = $self->end;
  return "$source/$start,$end";
}

# map info into a reasonable set of ace objects
sub toAce {
    my $self = shift;
    my $thing = shift;
    my ($tag,@values) = $thing=~/(\"[^\"]+?\"|\S+)/g;
    foreach (@values) { # strip the damn quotes
      s/^\"(.*)\"$/$1/;  # get rid of leading and trailing quotes
    }
    return $self->tag2ace($tag,@values);
}

# synthesize an artificial Ace object based on the tag
sub tag2ace {
    my $self = shift;
    my ($tag,@data) = @_;

    # Special cases, hardcoded in Ace GFF code...
    my $db = $self->db;;
    my $class = $db->class;

    # for Notes we just return a text, no database associated
    return $class->new(Text=>$data[0]) if $tag eq 'Note';

    # for homols, we create the indicated Protein or Sequence object
    # then generate a bogus Homology object (for future compatability??)
    if ($tag eq 'Target') {
	my ($objname,$start,$end) = @data;
	my ($classe,$name) = $objname =~ /^(\w+):(.+)/;
	return Ace::Sequence::Homol->new_homol($classe,$name,$db,$start,$end);
    }

    # General case:
    my $obj = $class->new($tag=>$data[0],$self->db);

    return $obj if defined $obj;

    # Last resort, return a Text
    return $class->new(Text=>$data[0]);
}

sub sub_SeqFeature {
  return wantarray ? () : 0;
}

1;

=head1 NAME

Ace::Sequence::Feature - Examine Sequence Feature Tables

=head1 SYNOPSIS

    # open database connection and get an Ace::Object sequence
    use Ace::Sequence;

    # get a megabase from the middle of chromosome I
    $seq = Ace::Sequence->new(-name   => 'CHROMOSOME_I,
                              -db     => $db,
			      -offset => 3_000_000,
			      -length => 1_000_000);

    # get all the homologies (a list of Ace::Sequence::Feature objs)
    @homol = $seq->features('Similarity');

    # Get information about the first one
    $feature = $homol[0];
    $type    = $feature->type;
    $subtype = $feature->subtype;
    $start   = $feature->start;
    $end     = $feature->end;
    $score   = $feature->score;

    # Follow the target
    $target  = $feature->info;

    # print the target's start and end positions
    print $target->start,'-',$target->end, "\n";

=head1 DESCRIPTION

I<Ace::Sequence::Feature> is a subclass of L<Ace::Sequence::Feature>
specialized for returning information about particular features in a
GFF format feature table.

=head1  OBJECT CREATION

You will not ordinarily create an I<Ace::Sequence::Feature> object
directly.  Instead, objects will be created in response to a feature()
call to an I<Ace::Sequence> object.  If you wish to create an
I<Ace::Sequence::Feature> object directly, please consult the source
code for the I<new()> method.

=head1 OBJECT METHODS

Most methods are inherited from I<Ace::Sequence>.  The following
methods are also supported:

=over 4

=item seqname()

  $object = $feature->seqname;

Return the ACeDB Sequence object that this feature is attached to.
The return value is an I<Ace::Object> of the Sequence class.  This
corresponds to the first field of the GFF format and does not
necessarily correspond to the I<Ace::Sequence> object from which the
feature was obtained (use source_seq() for that).

=item source()

=item method()

=item subtype()

  $source = $feature->source;

These three methods are all synonyms for the same thing.  They return
the second field of the GFF format, called "source" in the
documentation.  This is usually the method or algorithm used to
predict the feature, such as "GeneFinder" or "tRNA" scan.  To avoid
ambiguity and enhance readability, the method() and subtype() synonyms
are also recognized.

=item feature()

=item type()

  $type = $feature->type;

These two methods are also synonyms.  They return the type of the
feature, such as "exon", "similarity" or "Predicted_gene".  In the GFF
documentation this is called the "feature" field.  For readability,
you can also use type() to fetch the field.

=item abs_start()

  $start = $feature->abs_start;

This method returns the absolute start of the feature within the
sequence segment indicated by seqname().  As in the I<Ace::Sequence>
method, use start() to obtain the start of the feature relative to its
source.

=item abs_start()

  $start = $feature->abs_start;

This method returns the start of the feature relative to the sequence
segment indicated by seqname().  As in the I<Ace::Sequence> method,
you will more usually use the inherited start() method to obtain the
start of the feature relative to its source sequence (the
I<Ace::Sequence> from which it was originally derived).

=item abs_end()

  $start = $feature->abs_end;

This method returns the end of the feature relative to the sequence
segment indicated by seqname().  As in the I<Ace::Sequence> method,
you will more usually use the inherited end() method to obtain the end
of the feature relative to the I<Ace::Sequence> from which it was
derived.

=item score()

  $score = $feature->score;

For features that are associated with a numeric score, such as
similarities, this returns that value.  For other features, this
method returns undef.

=item strand()

  $strand = $feature->strand;

Returns the strandedness of this feature, either "+1" or "-1".  For
features that are not stranded, returns 0.

=item reversed()

  $reversed = $feature->reversed;

Returns true if the feature is reversed relative to its source
sequence.

=item frame()

  $frame = $feature->frame;

For features that have a frame, such as a predicted coding sequence,
returns the frame, either 0, 1 or 2.  For other features, returns undef.

=item group()

=item info()

=item target()

  $info = $feature->info;

These methods (synonyms for one another) return an Ace::Object
containing other information about the feature derived from the 8th
field of the GFF format, the so-called "group" field.  The type of the
Ace::Object is dependent on the nature of the feature.  The
possibilities are shown in the table below:

  Feature Type           Value of Group Field
  ------------            --------------------
  
  note                   A Text object containing the note.
  
  similarity             An Ace::Sequence::Homology object containing
                         the target and its start/stop positions.

  intron                 An Ace::Object containing the gene from 
  exon                   which the feature is derived.
  misc_feature

  other                  A Text object containing the group data.

=item asString()

  $label = $feature->asString;

Returns a human-readable identifier describing the nature of the
feature.  The format is:

 $type:$name/$start-$end

for example:

 exon:ZK154.3/1-67

This method is also called automatically when the object is treated in
a string context.

=back

=head1 SEE ALSO

L<Ace>, L<Ace::Object>, L<Ace::Sequence>,L<Ace::Sequence::Homol>,
L<Ace::Sequence::FeatureList>, L<GFF>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Copyright (c) 1999, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut


__END__
# SCRAPS
# the new() code done "right"
# sub new {
#    my $pack = shift;
#    my ($ref,$r_offset,$r_strand,$gff_line) = @_;
#    my ($sourceseq,$method,$type,$start,$end,$score,$strand,$frame,$group) = split "\t";
#    ($start,$end) = ($end,$start) if $strand < 0;
#    my $self = $pack->SUPER::new($source,$start,$end);
#    $self->{info} = {
#  				seqname=> $sourceseq,
#  				method => $method,
#  				type   => $type,
#  				score  => $score,
#  				frame  => $frame,
#  				group  => $group,
#  		  };
#    $self->{fstrand} = $strand;
#    return $self;
#  }

