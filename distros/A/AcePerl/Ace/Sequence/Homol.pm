# Ace::Sequence::Homol is just like Ace::Object, but has start() and end() methods
package Ace::Sequence::Homol;

use vars '@ISA';
@ISA = 'Ace::Object';


# this was a mistake!
# use overload '""' => 'asString';

# *stop = \&end;

sub new_homol {
  my ($pack,$tclass,$tname,$db,$start,$end) = @_;
  return unless my $obj = $db->class->new($tclass,$tname,$db,1);
  @$obj{'start','end'} = ($start,$end);
  return bless $obj,$pack;
}

sub start  {  return $_[0]->{'start'};  }

sub end    {  return $_[0]->{'end'};    }

sub stop   {  return $_[0]->{'end'};    }

# sub _clone {
#     my $self = shift;
#     my $pack = ref($self);
#     return $pack->new($self->db,$self->class,$self->name,$self->start,$self->end);
# }

#sub asString { 
#  my $n = $_[0]->name;
#  "$n/$_[0]->{'start'}-$_[0]->{'end'}";
#}

1;

=head1 NAME

Ace::Sequence::Homol - Temporary Sequence Homology Class

=head1 SYNOPSIS

    # Get all similarity features from an Ace::Sequence
    @homol = $seq->features('Similarity');

    # sort by score
    @sorted = sort { $a->score <=> $b->score } @homol;

    # the last one has the highest score
    $best = $sorted[$#sorted];

    # fetch its associated Ace::Sequence::Homol
    $homol = $best->target;

    # print out the sequence name, DNA, start and end
    print $homol->name,' ',$homol->start,'-',$homol->end,"\n";
    print $homol->asDNA;

=head1 DESCRIPTION

I<Ace::Sequence::Homol> is a subclass of L<Ace::Object> (B<not>
L<Ace::Sequence>) which is specialized for returning information about
a DNA or protein homology.  This is a temporary placeholder for a more
sophisticated homology class which will include support for
alignments.

=head1 OBJECT CREATION

You will not ordinarily create an I<Ace::Sequence::Homol> object
directly.  Instead, objects will be created in response to an info()
or group() method call on a similarity feature in an
I<Ace::Sequence::Feature> object.  If you wish to create an
I<Ace::Sequence::Homol> object directly, please consult the source
code for the I<new()> method.

=head1 OBJECT METHODS

Most methods are inherited from I<Ace::Object>.  The following
methods are also supported:

=over 4

=item start()

  $start = $homol->start;

Returns the start of the area that is similar to the
I<Ace::Sequence::Feature> from which his homology was derived.
Coordinates are relative to the target homology.

=item end()

  $end = $homol->end;

Returns the end of the area that is similar to the
I<Ace::Sequence::Feature> from which his homology was derived.
Coordinates are relative to the target homology.

=item asString()

  $label = $homol->asString;

Returns a human-readable identifier describing the nature of the
feature.  The format is:

 $name/$start-$end

for example:

 HUMGEN13/1-67

This method is also called automatically when the object is treated in
a string context.

=back

=head1 SEE ALSO

L<Ace>, L<Ace::Object>,
L<Ace::Sequence>,L<Ace::Sequence::FeatureList>,
L<Ace::Sequence::Feature>, L<GFF>

=head1 AUTHOR

Lincoln Stein <lstein@w3.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Copyright (c) 1999, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

