#
# BioStudio difference object
#

=head1 NAME

Bio::BioStudio::Diff::Difference - holds the difference between two
Bio::DB::SeqFeature objects

=head1 VERSION

Version 1.06

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=head1 FUNCTIONS

=cut

package Bio::BioStudio::Diff::Difference;

use CGI qw(td);

use strict;
use warnings;

use base qw(Bio::Root::Root);

our $VERSION = 2.10;

=head2 new

 Title   : new
 Function:
 Returns : a new Bio::BioStudio::Diff:Difference object
 Args    : -oldfeat     => Bio::DB::SeqFeature object
           -newfeat     => Bio::DB::SeqFeature object
           -oldsubfeat  => Bio::DB::SeqFeature object
           -newsubfeat  => Bio::DB::SeqFeature object
           -subdiff     => Bio::BioStudio::Diff:Difference object
           -oldatt
           -newatt
           -aligns      => Bio::Search::Result::BlastResult factory object
           -code        => integer from 1 to 12
           -basegain
           -baseloss
           -basechange
           -comment
           -display
       
=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  my ($oldfeat, $newfeat, $oldsubfeat, $newsubfeat, $oldatt,
      $newatt, $subdiff, $aligns, $code, $basegain, $baseloss, $basechange,
      $comment, $display) =
     $self->_rearrange([qw(OLDFEAT
                           NEWFEAT
                           OLDSUBFEAT
                           NEWSUBFEAT
                           OLDATT
                           NEWATT
                           SUBDIFF
                           ALIGNS
                           CODE
                           BASEGAIN
                           BASELOSS
                           BASECHANGE
                           COMMENT
                           DISPLAY)], @args);

  $self->throw("No code attribute supplied") unless ($code);
  $self->code($code);
                          
  $oldfeat && $self->oldfeat($oldfeat);
  $newfeat && $self->newfeat($newfeat);
 
  my $id = $oldfeat ? $oldfeat->display_name : $newfeat->display_name;
  my $feature = $newfeat ? $newfeat : $oldfeat;
  $self->feature($feature);
  $self->id($id);
 
  $oldsubfeat && $self->oldsubfeat($oldsubfeat);
  $newsubfeat && $self->newsubfeat($newsubfeat);
   
  my $subid = $oldsubfeat ? $oldsubfeat->Tag_load_id
            : $newsubfeat ? $newsubfeat->Tag_load_id
            : undef;
  $subid && $self->subid($subid);

  if ($subdiff)
  {
    $self->subdiff($subdiff);
    $baseloss = $subdiff->baseloss();
    $basechange = $subdiff->basechange();
    $basegain = $subdiff->basegain();
  }
  $baseloss = $baseloss ? $baseloss : 0;
  $self->baseloss($baseloss);

  $basegain = $basegain ? $basegain : 0;
  $self->basegain($basegain);

  $basechange = $basechange ? $basechange : 0;
  $self->basechange($basechange);

  $oldatt  && $self->oldatt($oldatt);
  $newatt  && $self->newatt($newatt);
  $aligns  && $self->aligns($aligns);
  $comment && $self->comment($comment);

  unless ($display)
  {
    my $type = $feature->primary_tag;
    if ($code <= 4) #feature additions and removals
    {
      if ($code == 1) #Lost features
      {
        $display = "$type $id was removed";
      }
      elsif ($code == 2) #Inserted features
      {
        my $verb = "inserted";
        $verb = 'annotated' if ($type eq 'restriction_enzyme_recognition_site');
        $verb = 'annotated' if ($type eq 'PCR_product');
        $verb = 'annotated' if ($type eq 'chunk');
        $verb = 'annotated' if ($type eq 'megachunk');
        $verb = $feature->has_tag("newseq") ? "added" : $verb;
        $display = "$type $id was $verb";
      }
      elsif ($code == 3) #lost subfeatures
      {
        my $subtype = $oldsubfeat->primary_tag;
        $display = "$type $id lost $subtype $subid";
      }
      elsif ($code == 4) #Inserted subfeatures
      {
        my $subtype = $newsubfeat->primary_tag;
        my $verb = "gained";
        $verb = $newsubfeat->has_tag("newseq") ? "added" : $verb;
        $display = "$type $id $verb $subtype $subid";
      }
    }
    elsif ($code == 5) #Lost sequence
    {
      $display = "$type $id is shorter by $baseloss bases";
    }
    elsif ($code == 6) #gained sequence
    {
      $display = "$type $id is longer by $basegain bases";
    }
    elsif ($code == 7 || $code == 8 ) #sequence change
    {
      if ($code == 7) #change in translation
      {
        $display = "$type $id\'s translation changed";
      }
      elsif ($code == 8) #change in nucleotide sequence
      {
        $display = "$type $id\'s sequence changed";
      }
    }
    if ($code == 9) #Lost annotation
    {
      $display = "$id lost the annotation $oldatt";
    }
    elsif ($code == 10) #gained annotation
    {
      $display = "$id gained the annotation $newatt";
    }
    elsif ($code == 11) #annotation change
    {
      $display = "$type $id\'s $comment changed from $oldatt to $newatt";
    }
    elsif ($code == 12) #subfeature change
    {
      $display = "$type $id\'s " . $self->subdiff->display();
    }
  }
  $display && $self->display($display);
 
  return $self;
}

=head2 newfeat

=cut

sub newfeat
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->throw("object of class " . ref($value) . " does not implement ".
		    "Bio::DB::SeqFeature.") unless $value->isa("Bio::DB::SeqFeature");
	  $obj->{'newfeat'} = $value;
  }
  return $obj->{'newfeat'};
}

=head2 oldfeat

=cut

sub oldfeat
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->throw("object of class " . ref($value) . " does not implement ".
		    "Bio::DB::SeqFeature.") unless $value->isa("Bio::DB::SeqFeature");
	  $obj->{'oldfeat'} = $value;
  }
  return $obj->{'oldfeat'};
}

=head2 newsubfeat

=cut

sub newsubfeat
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->throw("object of class " . ref($value) . " does not implement ".
		    "Bio::DB::SeqFeature.") unless $value->isa("Bio::DB::SeqFeature");
	  $obj->{'newsubfeat'} = $value;
  }
  return $obj->{'newsubfeat'};
}

=head2 oldsubfeat

=cut

sub oldsubfeat
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->throw("object of class " . ref($value) . " does not implement ".
		    "Bio::DB::SeqFeature.") unless $value->isa("Bio::DB::SeqFeature");
	  $obj->{'oldsubfeat'} = $value;
  }
  return $obj->{'oldsubfeat'};
}

=head2 subdiff

=cut

sub subdiff
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->throw("object of class " . ref($value) . " does not implement ".
		    "Bio::BioStudio::Diff::Difference.")
		  unless $value->isa("Bio::BioStudio::Diff::Difference");
	  $obj->{'subdiff'} = $value;
  }
  return $obj->{'subdiff'};
}

=head2 aligns

=cut

sub aligns
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->throw("object of class " . ref($value) . " does not implement ".
		    "Bio::Search::Result::BlastResult.")
		  unless $value->isa("Bio::Search::Result::BlastResult");
	  $obj->{'aligns'} = $value;
  }
  return $obj->{'aligns'};
}

=head2 code

=cut

sub code
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'code'} = $value;
  }
  return $obj->{'code'};
}

=head2 basegain

=cut

sub basegain
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'basegain'} = $value;
  }
  return $obj->{'basegain'};
}

=head2 baseloss

=cut

sub baseloss
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'baseloss'} = $value;
  }
  return $obj->{'baseloss'};
}

=head2 basechange

=cut

sub basechange
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'basechange'} = $value;
  }
  return $obj->{'basechange'};
}

=head2 oldatt

=cut

sub oldatt
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'oldatt'} = $value;
  }
  return $obj->{'oldatt'};
}

=head2 newatt

=cut

sub newatt
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'newatt'} = $value;
  }
  return $obj->{'newatt'};
}

=head2 comment

=cut

sub comment
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'comment'} = $value;
  }
  return $obj->{'comment'};
}

=head2 display

=cut

sub display
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'display'} = $value;
  }
  return $obj->{'display'};
}

=head2 feature

=cut

sub feature
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'feature'} = $value;
  }
  return $obj->{'feature'};
}

=head2 id

=cut

sub id
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'id'} = $value;
  }
  return $obj->{'id'};
}

=head2 subid

=cut

sub subid
{
  my ($obj, $value) = @_;
  if (defined $value)
  {
	  $obj->{'subid'} = $value;
  }
  return $obj->{'subid'};
}

=head2 textline

=cut

sub textline
{
  my ($obj) = @_;
  return         $obj->display()
        . "\t" . $obj->basegain()
        . "\t" . $obj->baseloss()
        . "\t" . $obj->basechange()
        . "\n";
}

=head2 htmlline

=cut

sub htmlline
{
  my ($obj) = @_;
  return    td($obj->display())
          . td($obj->basegain())
          . td($obj->baseloss())
          . td($obj->basechange());
}

1;

__END__


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Joint BioEnergy 
Institute, the Lawrence Berkeley National Laboratory, the Department of Energy, 
and the BioStudio developers may not be used to endorse or promote products 
derived from this software without specific prior written permission.

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

=cut
