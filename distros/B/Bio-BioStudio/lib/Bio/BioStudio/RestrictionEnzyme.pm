#
# BioStudio module for sequence segmentation
#

=head1 NAME

Bio::BioStudio::RestrictionEnzyme

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio object that represents a restriction enzyme - inherits from
L<Bio::GeneDesign::RestrictionEnzyme> and adds attributes for feature annotation
awareness. This object is heavily used in chromosome segmentation - for other
uses the GeneDesign object should be sufficient.

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::BioStudio::RestrictionEnzyme;

use strict;
use warnings;

use base qw(Bio::GeneDesign::RestrictionEnzyme);

our $VERSION = 2.10;

=head1 CONSTRUCTORS

=head2 new

When this object is created it is also subject to the requirements of the
ancestor L<Bio::GeneDesign::RestrictionEnzyme> object. Use the ancestor flag
-enzyme with a GeneDesign RestrictionEnzyme object, allowing the ancestral
object to "clone" itself to create a new BioStudio RestrictionEnzyme object:

  my $newfeat = Bio::BioStudio::RestrictionEnzyme->new(
          -enzyme => $BamHI_Bio::GeneDesign::RestrictionEnzyme_object,
          -name => "BamHI_56781",
          -presence => "potential");
         
There are two required arguments:

    -name       the name of the enzyme
    
    -presence   (p)otential, (i)ntergenic, (e)xisting, or (a)ppended, the status
                of the enzyme
 
The other arguments are optional:

    -eligible   whether or not to ignore this enzyme when selecting segmentation
                enzymes; usually gets set automatically when the
                L<Bio::BioStudio::RestrictionEnzyme::Store> object is created.
                May only be undefined (omitted) or "no".
    
    -end        The stop coordinate of the enzyme
    
    -feature    The L<Bio::DB::SeqFeature> object associated with the enzyme -
                usually a gene; sometimes an intergenic region
    
    -featureid  The name of the feature associated with the enzyme - this is set
                automatically if -feature is used
    
    -overhangs  A comma separated list of overhangs that this enzyme can legally
                leave. This will be parsed into a hash reference.

    -strand     [1 or -1] If 1, the object is either oriented 5 prime to 3 prime
                on the Watson strand or is symmetric and therefore on both
                strands. If -1, the object is on the Crick strand.
    
    -peptide    The peptide sequence associated with the enzymes recognition
                site. Should only be supplied if the feature object associated
                with the enzyme is a gene, mRNA, or CDS object.
    
    -offset     This number indicates how far away from the recognition site
                the actual cut site is.
    
    -dbid       The primary key of this enzyme in the database; usually set by
                L<Bio::BioStudio::RestrictionEnzyme::Store> at the time of
                database creation
    
    -phang      The preferred overhang for use when committing this enzyme to
                sequence.
    
=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  bless $self, $class;

  my ($name, $presence, $eligible, $end, $feature, $featureid, $overhangs,
      $strand, $peptide, $offset, $dbid, $phang) =
     $self->_rearrange([qw(NAME PRESENCE ELIGIBLE END FEATURE FEATUREID
       OVERHANGS STRAND PEPTIDE OFFSET DBID PHANG)], @args);

  $self->throw("No name defined") unless ($name);
  $self->{name} = $name;

  $self->throw("No presence defined") unless ($presence);
  if ($presence =~ m{\Ap}msix)
  {
    $self->{presence} = 'potential';
  }
  if ($presence =~ m{\Ai}msix)
  {
    $self->{presence} = 'intergenic';
  }
  if ($presence =~ m{\Ae}msix)
  {
    $self->{presence} = 'existing';
  }
  if ($presence =~ m{\Aa}msix)
  {
    $self->{presence} = 'appended';
  }

  $eligible && $self->eligible($eligible);

  $end && $self->end($end);

  if ($feature)
  {
    $self->{featureid} = $feature->id;
  }
  elsif ($featureid)
  {
    $self->{featureid} = $featureid;
  }
  else
  {
    $self->{featureid} = q{};
  }

  $overhangs && $self->overhangs($overhangs);

  $strand && $self->strand($strand);

  $peptide = $peptide || q{};
  $self->{peptide} = $peptide;

  $offset = $offset || '0';
  $self->{offset} = $offset;

  $dbid && $self->dbid($dbid);

  $phang && $self->phang($phang);

  return $self;
}

=head1 FUNCTIONS

=head2 line_report

This function outputs the restriction enzyme object in a format that is suitable
for quickloading into a MySQL database - this is how the
L<Bio::RestrictionEnzyme::Store> database becomes populated.

=cut

sub line_report
{
  my ($self, $fieldterm, $lineterm) = @_;
  my $pep = $self->{peptide} ?  $self->peptide  : 'NULL';
  my $line = $self->{name} . $fieldterm;
  $line .= $self->{presence} . $fieldterm;
  $line .= $self->{start} . $fieldterm;
  $line .= $self->{end} . $fieldterm;
  $line .= $self->{id} . $fieldterm;
  $line .= $self->{featureid} . $fieldterm;
  $line .= $self->{peptide} . $fieldterm;
  $line .= join(q{,}, keys %{$self->{overhangs}}) . $fieldterm;
  $line .= $self->{strand} . $fieldterm;
  $line .= $self->{offset} . $lineterm;
  return $line;
}

=head1 ACCESSORS

=head2 name

The name of the enzyme; current BioStudio custom is that the name of an enzyme
is its id (ie, the name of the protein), underscore, start coordinate. That is,
BamHI_54671, or SacII_4689. But this is entirely arbitrary and will not impact
processing.

=cut

sub name
{
  my ($self) = @_;
  return $self->{name};
}

=head2 presence

Enzymes can be any one of the following:

  (p)otential  : can be introduced into exonic sequence without changing protein
                 sequence - but does not exist now
                
  (i)ntergenic : exists in a non-exonic region. Most BioStudio algorithms do not
                 support editing such an enzyme.

  (e)xisting   : or exonic, this site is in a gene region and can be edited or
                 removed.
                 
  (a)ppended   : this site doesn't exist but will be appended to the sequence
                 
=cut

sub presence
{
  my ($self) = @_;
  return $self->{presence};
}

=head2 end

L<Bio::GeneDesign::RestrictionEnzyme> objects have a start attribute, but not an
end attribute.

=cut

sub end
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->{end} = $value;
  }
  return $self->{end};
}

=head2 eligible

Should this enzyme be considered for landmark status or not? This flag is
usually set when the L<Bio::BioStudio::RestrictionEnzyme::Store> database is
created and populated. Enzymes whose presence is potential and whose eligibility
is null are usually deleted rather than marked ineligible.

The only argument this accessor accepts is a string value of "no".

=cut

sub eligible
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw("eligibility should be undefined or \"no\"; not $value ")
	    unless ($value eq "no");
	  $self->{eligible} = $value;
  }
  return $self->{eligible};
}

=head2 featureid

The id of the feature associated with the enzyme; this is a string and is useful
when pulling objects out of the MySQL database, which currently doesn't store
an actual Bio::DB::SeqFeature object, but only its id. Given the id, the feature
can be looked up from a L<Bio::DB::SeqFeature::Store> object.

=cut

sub featureid
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{featureid} = $value;
  }
  return $self->{featureid};
}

=head2 overhangs

A hash reference where the keys are possible overhangs that may be left by the
enzyme should it be edite into sequence.

=cut

sub overhangs
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->{overhangs} = $value;
  }
  return $self->{overhangs};
}

=head2 strand

Is the recognition site on the Watson (1) or Crick (-1) strand?

If 1, the object is either oriented 5 prime to 3 prime on the Watson strand or
is symmetric and therefore on both strands. If -1, the object is on the Crick
strand.

=cut

sub strand
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw("strand value must be 1 or -1; $value not understood")
		  unless ($value == 1 || $value == -1);
	  $self->{strand} = $value;
  }
  return $self->{strand};
}

=head2 peptide

IF the enzyme occurs in a gene, what peptide sequence (in the first frame of
translation) covers the recognition site? Should only be defined if the
associated feature is a CDS.

=cut

sub peptide
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->{peptide} = $value;
  }
  return $self->{peptide};
}

=head2 offset

How far away the overhang is from the recognition site, in bases (if there is an
overhang).

=cut

sub offset
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->{offset} = $value;
  }
  return $self->{offset};
}

=head2 movers

If this enzyme is introduced or edited into sequence, which other restriction
enzyme recognition sites must be removed to make it a unique landmark?

Takes and returns an array reference, where each entry in the array is the name
of a BioStudio restriction enzyme object.

=cut

sub movers
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->{movers} = $value;
  }
  return $self->{movers};
}

=head2 creates

If this enzyme is introduced or edited into sequence, which other restriction
enzyme recognition sites will it create?

Takes and returns an array reference, where each entry in the array is the id of
a GeneDesign restriction enzyme object.

=cut

sub creates
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw("$value is not an array reference")
		  unless (ref $value eq "ARRAY");
	  $self->{creates} = $value;
  }
  return $self->{creates};
}

=head2 dbid

The entry in the primary key column of the MySQL database underlying the
L<Bio::BioStudio::RestrictionEnzyme::Store> object; this is usually used during
database creation and culling and is unneccesary otherwise.

=cut

sub dbid
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->{dbid} = $value;
  }
  return $self->{dbid};
}

=head2 phang

If this enzyme is to be introduced or edited into sequence, which of its
possible overhangs should be used? The argument must be a key that exists in the
overhangs hash reference.

=cut

sub phang
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw("$value does not exist in the possible overhang list")
		  unless (exists $self->overhangs->{$value});
	  $self->{phang} = $value;
  }
  return $self->{phang};
}

1;

__END__

=head2

COPYRIGHT AND LICENSE

Copyright (c) 2014, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the BioStudio developers may
not be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
