#
# BioStudio module for comparing normalized SeqFeatures
#

=head1 NAME

Bio::BioStudio::Diff

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

An object that allows the comparison of two Bio::BioStudio::Chromosome objects.

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Diff;

use Bio::BioStudio::Diff::Difference;
use Bio::BioStudio::ConfigData;
use Bio::GeneDesign::Basic qw(_compare_sequences);
use Text::Diff;

use strict;
use warnings;

use base qw(Bio::Root::Root);

our $VERSION = 2.10;

my %CODES = (
      1  => "deleted feature",
      2  => "added feature",
      3  => "lost subfeature",
      4  => "gained subfeature",
      5  => "lost sequence",
      6  => "gained sequence",
      7  => "change in translation",
      8  => "change in sequence",
      9  => "lost attributes",
      10 => "gained attributes",
      11 => "changed annotation",
      12 => "changed subfeature"
);

=head1 CONSTRUCTOR METHOD

=head2 new

=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  my ($oldchr, $newchr, $checktrx, $aligntrx, $checkseq, $alignseq) =
     $self->_rearrange([qw(OLDCHR
                           NEWCHR
                           CHECKTRANSLATION
                           ALIGNTRANSLATION
                           CHECKSEQUENCE
                           ALIGNSEQUENCE)], @args);
                           
   $self->throw("\"Old\" chromosome not supplied") unless ($oldchr);
   $self->oldchr($oldchr);

   $self->throw("\"New\" chromosome not supplied") unless ($newchr);
   $self->newchr($newchr);
   
   if ($aligntrx || $alignseq)
   {
     my $bs = Bio::BioStudio::ConfigData->config('blast_support');
     if ($bs ne 'Y')
     {
       warn "Cannot perform alignments: blast support is not enabled\n";
       $aligntrx = undef;
       $alignseq = undef;
     }
   }
                  
   $self->{checktrx} = $checktrx;
   $self->{aligntrx} = $aligntrx;
   $self->{checkseq} = $checkseq;
   $self->{alignseq} = $alignseq;

   return $self;
}

=head2 DESTROY

=cut

sub DESTROY
{
  my ($self) = @_;
  $self->{BLAST_factory}->cleanup() if (defined $self->{BLAST_factory});
  $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
  return;
}

=head1 COMPARISON METHODS

=head2 compare_dbs

=cut

sub compare_dbs
{
  my ($self) = @_;

  my $olddb = $self->oldchr->db;
  my $newdb = $self->newchr->db;

  my (%feats1, %feats2) = ((), ());

  #PARENTS ONLY! Subfeatures will be dealt with downstream
  my $iterator1 = $olddb->get_seq_stream();
  while (my $feature = $iterator1->next_seq)
  {
    next if ($feature->has_tag('parent_id'));
    $feats1{$feature->display_name} = $feature->primary_id;
  }

  my $iterator2 = $newdb->get_seq_stream();
  while (my $feature = $iterator2->next_seq)
  {
    next if ($feature->has_tag('parent_id'));
    $feats2{$feature->display_name} = $feature->primary_id;
  }

  my @D;

  #
  # Common Features
  #
  my @commons = grep  { exists $feats2{$_} } keys %feats1;
  foreach my $featid (@commons)
  {
    my $oldfeat = $olddb->fetch($feats1{$featid});
    my $newfeat = $newdb->fetch($feats2{$featid});
    $self->throw("Can't find $featid in olddb!") unless ($oldfeat);
    $self->throw("Can't find $featid in newdb!") unless ($newfeat);
    push @D, $self->compare_features($oldfeat, $newfeat);
  }

  #
  # Deleted Features
  #
  my @onlyolds = grep {! exists $feats2{$_} } keys %feats1;
  foreach my $featid (@onlyolds)
  {
    my $feat = $olddb->fetch($feats1{$featid});
    $self->throw("Can't find $featid in olddb!") unless ($feat);
    my $baseloss = $feat->end - $feat->start + 1;
    push @D, Bio::BioStudio::Diff::Difference->new(
        -oldfeat => $feat,
        -code => 1,
        -baseloss => $baseloss
    );
  }

  #
  # Inserted Features
  #
  my @onlynews = grep {! exists $feats1{$_} } keys %feats2;
  foreach my $featid (@onlynews)
  {
    my $feat = $newdb->fetch($feats2{$featid});
    $self->throw("Can't find $featid in newdb!") unless ($feat);
    my $basechange = 0;
    my $basegain = $feat->end - $feat->start + 1;
    if ($feat->has_tag("newseq"))
    {
      my $cthsh = _compare_sequences($feat->Tag_wtseq, $feat->Tag_newseq);
      $basechange = $cthsh->{D};
    }
    push @D, Bio::BioStudio::Diff::Difference->new(
        -newfeat => $feat,
        -code => 2,
        -basegain => $basegain,
        -basechange => $basechange
    );
  }

  return @D;
}

=head2 compare_features

=cut

sub compare_features
{
  my ($self, $feat1, $feat2) = @_;
  my @Changes = ();

  my $oldchr = $self->{oldchr};
  my $GD = $oldchr->GD;

  ##Check for subfeatures and compare
  if (scalar($feat1->get_SeqFeatures) || scalar($feat2->get_SeqFeatures))
  {
    my @allsubs1 = $oldchr->flatten_subfeats($feat1);
    my @allsubs2 = $oldchr->flatten_subfeats($feat2);
    my %types = map {$_->primary_tag() => 1} @allsubs1, @allsubs2;
    foreach my $type (keys %types)
    {
      my @subtype1s = grep {$_->primary_tag eq $type} @allsubs1;
      my %subs1 = map {$_->Tag_load_id => $_} @subtype1s;
      my @subtype2s = grep {$_->primary_tag eq $type} @allsubs2;
      my %subs2 = map {$_->Tag_load_id => $_} @subtype2s;

      #Compare all sub features of type $type
      foreach my $sub1id (grep {exists $subs2{$_}} keys %subs1)
      {
        my $subfeat1 = delete $subs1{$sub1id};
        my $subfeat2 = delete $subs2{$sub1id};
        foreach my $sobj ($self->compare_features($subfeat1, $subfeat2))
        {
          if ($sobj->code() >= 4)
          {
            push @Changes, Bio::BioStudio::Diff::Difference->new(
                      -oldfeat => $feat1,
                      -newfeat => $feat2,
                      -oldsubfeat => $subfeat1,
                      -newsubfeat => $subfeat2,
                      -code => 12,
                      -subdiff => $sobj);
          }
        }
      }
      #Deleted subfeatures of type $type
      foreach (keys %subs1)
      {
        my $subfeat = $subs1{$_};
        my $baseloss = $subfeat->end - $subfeat->start + 1;

        push @Changes, Bio::BioStudio::Diff::Difference->new(
                  -oldfeat => $feat1,
                  -oldsubfeat => $subfeat,
                  -newfeat => $feat2,
                  -baseloss => $baseloss,
                  -code => 3);
      }
      #Inserted subfeatures of type $type
      foreach (keys %subs2)
      {
        my $subfeat = $subs2{$_};
        my $basechange = 0;
        if ($subfeat->has_tag("newseq"))
        {
          my $ct = _compare_sequences($subfeat->Tag_wtseq, $subfeat->Tag_newseq);
          $basechange = $ct->{D};
        }
        push @Changes, Bio::BioStudio::Diff::Difference->new(
                  -oldfeat => $feat1,
                  -newfeat => $feat2,
                  -newsubfeat => $subfeat,
                  -code => 4,
                  -basechange => $basechange);
      }
    }
  }

  ##Check to see if attributes have changed
  my $attarray = $self->compare_feature_attributes($feat1, $feat2);
  push @Changes, @{$attarray} if ($attarray);

  ##Check to see if annotations have changed
  my $annarray = $self->compare_feature_annotations($feat1, $feat2);
  push @Changes, @{$annarray} if ($annarray);

  ##If the translation switch is on, see if translation has changed (CDS ONLY)
  if ($feat1->primary_tag() eq "CDS" && ($self->checktrx || $self->aligntrx))
  {
    my $ch = $self->compare_feature_translations($feat1, $feat2);
    push @Changes, $ch if ($ch);
  }

  ##If check sequence is on, see if the feature sequence has changed
  if ($self->{checkseq} || $self->{alignseq})
  {
    my $ch = $self->compare_feature_sequences($feat1, $feat2);
    push @Changes, $ch if ($ch);
  }
  return @Changes;
}

=head2 compare_feature_sources

=cut

sub compare_feature_sources
{
  my ($self, $feat1, $feat2) = @_;
  return if ($feat1->source() eq $feat2->source());
  return Bio::BioStudio::Diff::Difference->new(
            -oldfeat => $feat1,
            -newfeat => $feat2,
            -oldatt => $feat1->source_tag(),
            -newatt => $feat2->source_tag(),
            -comment => "source",
            -code => 11
  );
}

=head2 compare_feature_types

=cut

sub compare_feature_types
{
  my ($self, $feat1, $feat2) = @_;
  return if ($feat1->primary_tag() eq $feat2->primary_tag());
  return Bio::BioStudio::Diff::Difference->new(
            -oldfeat => $feat1,
            -newfeat => $feat2,
            -oldatt => $feat1->primary_tag(),
            -newatt => $feat2->primary_tag(),
            -comment => "primary_tag",
            -code => 11
  );
}

=head2 compare_feature_lengths

=cut

sub compare_feature_lengths
{
  my ($self, $feat1, $feat2) = @_;
  my $len1 = $feat1->end - $feat1->start + 1;
  my $len2 = $feat2->end - $feat2->start + 1;
  my $difference = abs($len1 - $len2);
  return if ($difference == 0);
  my ($code, $baseloss, $basegain) = (0, 0, 0);
  if ($len1 > $len2)
  {
    $code = 5;
    $baseloss = $difference;
  }
  else
  {
    $code = 6;
    $basegain = $difference;
  }
  return Bio::BioStudio::Diff::Difference->new(
            -oldfeat => $feat1,
            -newfeat => $feat2,
            -oldatt => $len1,
            -newatt => $len2,
            -code => $code,
            -baseloss => $baseloss,
            -basegain => $basegain
  );
}

=head2 compare_feature_orientations

=cut

sub compare_feature_orientations
{
  my ($self, $feat1, $feat2) = @_;
  return if ($feat1->strand() eq $feat2->strand());
  return Bio::BioStudio::Diff::Difference->new(
            -oldfeat => $feat1,
            -newfeat => $feat2,
            -oldatt => $feat1->strand(),
            -newatt => $feat2->strand(),
            -comment => "strand",
            -code => 11
  );
}

=head2 compare_feature_scores

=cut

sub compare_feature_scores
{
  my ($self, $feat1, $feat2) = @_;
  my $f1score = $feat1->score ? $feat1->score : 0;
  my $f2score = $feat2->score ? $feat2->score : 0;
  return if ($f1score eq $f2score);
  return Bio::BioStudio::Diff::Difference->new(
            -oldfeat => $feat1,
            -newfeat => $feat2,
            -oldatt => $f1score,
            -newatt => $f2score,
            -comment => "score",
            -code => 11
  );
}

=head2 compare_feature_phases

=cut

sub compare_feature_phases
{
  my ($self, $feat1, $feat2) = @_;
  my $f1phase = $feat1->phase ? $feat1->phase : 0;
  my $f2phase = $feat2->phase ? $feat2->phase : 0;
  return if ($f1phase eq $f2phase);
  return Bio::BioStudio::Diff::Difference->new(
            -oldfeat => $feat1,
            -newfeat => $feat2,
            -oldatt => $f1phase,
            -newatt => $f2phase,
            -comment => "phase",
            -code => 11
  );
}

=head2 compare_feature_attributes

=cut

sub compare_feature_attributes
{
  my ($self, $feat1, $feat2) = @_;
  my @attChanges;

  ##Check to see if source has changed
  my $sourcechange = $self->compare_feature_sources($feat1, $feat2);
  push @attChanges, $sourcechange if ($sourcechange);

  ##Check to see if type has changed
  my $typechange = $self->compare_feature_types($feat1, $feat2);
  push @attChanges, $typechange if ($typechange);

  ##Check to see if length has changed
  my $lengthchange = $self->compare_feature_lengths($feat1, $feat2);
  push @attChanges, $lengthchange if ($lengthchange);

  ##Check to see if score has changed
  my $scorechange = $self->compare_feature_scores($feat1, $feat2);
  push @attChanges, $scorechange if ($scorechange);

  ##Check to see if orientation has changed
  my $orientchange = $self->compare_feature_orientations($feat1, $feat2);
  push @attChanges, $orientchange if ($orientchange);

  ##Check to see if phase has changed
  my $phasechange = $self->compare_feature_phases($feat1, $feat2);
  push @attChanges, $phasechange if ($phasechange);

  if (scalar (@attChanges))
  {
    return \@attChanges;
  }
  else
  {
    return;
  }
}

=head2 compare_feature_annotations

=cut

sub compare_feature_annotations
{
  my ($self, $feat1, $feat2) = @_;
  my @annChanges;

  my @tags1 = $feat1->get_all_tags();
  my @tags2 = $feat2->get_all_tags();
  foreach my $tag (grep {$feat2->has_tag($_)} @tags1)
  {
    my %vals1 = map {$_ => 1} $feat1->get_tag_values($tag);
    my %vals2 = map {$_ => 1} $feat2->get_tag_values($tag);
    foreach my $val (grep {! exists $vals2{$_}} keys %vals1)
    {
      push @annChanges, Bio::BioStudio::Diff::Difference->new(
                -oldfeat => $feat1,
                -newfeat => $feat2,
                -oldatt => "$tag = $val",
                -code => 9
      );
    }
    foreach my $val (grep {! exists $vals1{$_}} keys %vals2)
    {
      push @annChanges, Bio::BioStudio::Diff::Difference->new(
                -oldfeat => $feat1,
                -newfeat => $feat2,
                -newatt => "$tag = $val",
                -code => 10
      );
    }
  }
  foreach my $tag (grep {! $feat2->has_tag($_)} @tags1)
  {
    push @annChanges, Bio::BioStudio::Diff::Difference->new(
                -oldfeat => $feat1,
                -newfeat => $feat2,
                -oldatt => "$tag = " . join(", ", $feat1->get_tag_values($tag)),
                -code => 9
    );
  }
  foreach my $tag (grep {! $feat1->has_tag($_)} @tags2)
  {
    push @annChanges, Bio::BioStudio::Diff::Difference->new(
                -oldfeat => $feat1,
                -newfeat => $feat2,
                -oldatt => "$tag = " . join(", ", $feat2->get_tag_values($tag)),
                -code => 10
    );
  }

  if (scalar (@annChanges))
  {
    return \@annChanges;
  }
  else
  {
    return;
  }
}

=head2 compare_feature_sequences

=cut

sub compare_feature_sequences
{
  my ($self, $feat1, $feat2) = @_;

  my ($old, $var) = ($feat1->seq->seq, $feat2->seq->seq);
  return if ($old eq $var);
  my ($aligns, $basechange) = (undef, 0);
  if ($feat1->primary_tag() eq "chromosome")
  {
    ##WHOLE CHROMOSOME ALIGNMENT
    return;
  }
  if ($self->{alignseq})
  {
    my $alnz = $self->BLAST_factory->bl2seq(
      -method         => 'blastn',
      -subject        => $feat1->seq,
      -query          => $feat2->seq,
      -method_args => [
        gapopen       => 11,
        gapextend     => 2
      ]
    );
    if ($alnz)
    {
      $aligns = $alnz;
      my $mismatchcount = 0;
      my $hitlen = 0;
      while (my $hit = $aligns->next_hit())
      {
        if (scalar($hit->hsps()))
        {
          $hitlen += $hit->length();
          $mismatchcount += ($hit->length() - $hit->matches('id'));
        }
      }
      $mismatchcount += (length($var) - $hitlen);
      $basechange = $mismatchcount;
    }
  }
  else
  {
    #my $cthsh = _compare_sequences($feat2->Tag_wtseq, $feat2->Tag_newseq);
    my $cthsh = _compare_sequences($old, $var);
    $basechange = $cthsh->{D};
  }
  my $difference = Bio::BioStudio::Diff::Difference->new(
    -oldfeat    => $feat1,
    -newfeat    => $feat2,
    -oldatt     => $old,
    -newatt     => $var,
    -code       => 8,
    -aligns     => $aligns,
    -basechange => $basechange
  );
  return $difference;
}

=head2 compare_feature_translations

=cut

sub compare_feature_translations
{
  my ($self, $feat1, $feat2) = @_;
  my $oldchr = $self->{oldchr};
  my $GD = $oldchr->GD;

  my $orf1 = $feat1->seq->seq;
  my $f1phase = $feat1->phase ? $feat1->phase : 0;
	my $old = $GD->translate(-sequence => $orf1, -frame => $f1phase + 1);

	my $orf2 = $feat2->seq->seq;
  my $f2phase = $feat2->phase ? $feat2->phase : 0;
	my $var = $GD->translate(-sequence => $orf2, -frame => $f2phase + 1);

  return if ($old eq $var);

  if ((!$old && length($orf1) >=3) || (!$var && length($orf2) >=3))
  {
    print "original $feat1 " if (!$old);
    print "variant $feat2 " if (!$var);
    print "has no translation, strangely!!\n";
    return;
  }
  my $aligns = undef;
  if ($self->{aligntrx})
  {
    my $newfeat1 = Bio::Seq->new(-id => $feat1->id, -seq => $old);
    my $newfeat2 = Bio::Seq->new(-id => $feat2->id, -seq => $var);
    $aligns = $self->BLAST_factory->bl2seq(
      -method  => 'blastp',
      -subject => $newfeat1,
      -query   => $newfeat2
    );
  }
  my $difference = Bio::BioStudio::Diff::Difference->new(
    -oldfeat => $feat1,
    -newfeat => $feat2,
    -oldatt => $old,
    -newatt => $var,
    -code => 7,
    -aligns => $aligns
  );
  return $difference;
}

=head2 compare_comments

=cut

sub compare_comments
{
	my ($self) = @_;
  my $ref1 = join "\n", $self->{oldchr}->comments();
  my $ref2 = join "\n", $self->{newchr}->comments();
	my @textdiff;
  diff \$ref1, \$ref2, {OUTPUT => \@textdiff};
	return @textdiff;
}

=head2 verify_newseq

=cut

sub verify_newseq
{
  my ($self, $feat) = @_;
  return 1 unless ($feat->has_tag("newseq"));
  my $newseq = $feat->Tag_newseq;
  my $featseq = $feat->seq->seq;
  return 1 if ($newseq eq $featseq);
  my $chr = $self->{newchr};
  my $GD = $chr->GD;
  $featseq = $GD->complement(-sequence => $featseq, -reverse => 1);
  return 1 if ($newseq eq $featseq && $feat->strand == -1);
  return 0;
}

=head1 ACCESSOR METHODS

=head2 oldchr

=cut

sub oldchr
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    unless ($value->isa("Bio::BioStudio::Chromosome"))
    {
      $self->throw("oldchr value is not a Bio::BioStudio::Chromosome object");
    }
	  $self->{oldchr} = $value;
  }
  return $self->{oldchr};
}

=head2 newchr

=cut

sub newchr
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    unless ($value->isa("Bio::BioStudio::Chromosome"))
    {
      $self->throw("newchr value is not a Bio::BioStudio::Chromosome object");
    }
	  $self->{newchr} = $value;
  }
  return $self->{newchr};
}

=head2 checktrx

=cut

sub checktrx
{
  my ($self) = @_;
  return $self->{checktrx};
}

=head2 aligntrx

=cut

sub aligntrx
{
  my ($self) = @_;
  return $self->{aligntrx};
}

=head2 alignseq

=cut

sub alignseq
{
  my ($self) = @_;
  return $self->{alignseq};
}

=head2 checkseq

=cut

sub checkseq
{
  my ($self) = @_;
  return $self->{checkseq};
}

=head2 BLAST_factory

=cut

sub BLAST_factory
{
  my ($self) = @_;
  if (! defined $self->{BLAST_factory})
  {
    $self->_make_bl2seq_factory();
  }
  return $self->{BLAST_factory};
}

=head1 PRIVATE

=head2 _make_bl2seq_factory

Returns a L<Bio::Tools::Run::StandAloneBlastPlus> object that can be used to
run BLAST bl2seq queries

=cut

sub _make_bl2seq_factory
{
  my ($self) = @_;
  my $bdir = Bio::BioStudio::ConfigData->config('tmp_path');
  my $factory = Bio::Tools::Run::StandAloneBlastPlus->new(
    -db_dir  => $bdir
  );
  $self->{BLAST_factory} = $factory;
  return $factory;
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
