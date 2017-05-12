#
# BioStudio functions
#

=head1 NAME

Bio::BioStudio::Mask

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Mask;

use base qw(Bio::Root::Root);
use Bio::SeqFeature::Generic;

use strict;
use warnings;

our $VERSION = '2.10';

=head1 CONSTRUCTORS

=head2 new

 Title   : new
 Function:
 Returns : a new Bio::BioStudio::Mask object
 Args    :

=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  bless $self, $class;

  my ($seqobj, $offset) = $self->_rearrange([qw(SEQUENCE OFFSET)], @args);
        
  $self->throw('No Bio::Seq provided') unless $seqobj;

  my $ref = ref($seqobj);
  $self->throw("object of class $ref is not the kind of object Mask can take")
	  unless ($seqobj->isa('Bio::Seq')
         || $seqobj->isa('Bio::SeqFeatureI')
         || $seqobj->isa('Bio::PrimarySeq'));

  my $seq = $seqobj->seq;
  $seq = $seq->seq if (ref $seq);
  $self->{length} = length $seq;

  $self->{seqid} = $seqobj->id;

  #COMMENT THIS
  my @mask = map { [{}, 0] } (undef) x $self->{length};
  $self->{mask} = \@mask;

  $self->{index} = {};
  
  $self->{offset} = $offset || 0;

  return $self;
}

=head1 Masking functions

=head2 add_to_mask()

Given an array reference full of L<SeqFeature|Bio::DB::SeqFeature>s,
fills the mask

=cut

sub add_to_mask
{
  my ($self, $featlist) = @_;
  my $mask = $self->{mask};
  my $offset = $self->{offset};
  foreach my $q (@{$featlist})
  {
    $self->throw('object ' . ref($q) . ' is not a Bio::SeqFeatureI')
      unless ($q->isa('Bio::SeqFeatureI'));
    my $name = $q->display_name || $q->primary_tag . q{_} . $q->start;
    my $pid = $q->primary_id || $name;
    $self->{index}->{$name} = $pid;
    $self->{feature}->{$name} = $q;
    my $start = $q->start() - ($offset);
    my $end = $q->end() - ($offset);
		for my $x ($start - 1 .. $end - 1)
		{
      $mask->[$x]->[0]->{$name}++;
      $mask->[$x]->[1]++;
		}
  }
  return $self;
}

=head2 remove_from_mask()

=cut

sub remove_from_mask
{
  my ($self, $feature) = @_;
  my $mask = $self->{mask};
  my $offset = $self->{offset};
  $self->throw('object ' . ref($feature) . ' is not a Bio::SeqFeatureI')
    unless ($feature->isa('Bio::SeqFeatureI'));
  my $name = $feature->display_name;
  delete $self->{index}->{$name};
  my $start = $feature->start - 1 - $offset;
  my $end = $feature->end - 1 - $offset;
	for my $x ($start .. $end)
	{
    print "Removing $feature from mask at $x\n";
    delete $mask->[$x]->[0]->{$name};
    $mask->[$x]->[1]--;
	}
  return $self;
}

=head2 insert_sequence()

=cut

sub insert_sequence
{
  my ($self, $feat) = @_;
  my $mask = $self->{mask};
  my $offset = $self->{offset};
  my $name = $feat->display_name;
  $self->{index}->{$name} = $feat->primary_id;
  my $start = $feat->start - $offset;
  my $end   = $feat->end - $offset;
  my $len = $end - $start + 1;
  my %list = $self->what_overlaps($start);
  my @insert = map { [{}, 0] } (undef) x $len;
  splice @{$mask}, $start - 1, 0, @insert;
	for my $x ($start - 1 .. $end - 1)
	{
    my %insy = map {$_ => 1} values %list;
    $mask->[$x]->[0] = \%insy;
    $mask->[$x]->[0]->{$name}++;
    $mask->[$x]->[1]++;
	}
  $self->{length} += $len;
  return $self;
}

=head2 remove_sequence()

=cut

sub remove_sequence
{
  my ($self, $start, $end) = @_;
  $self->_sanity_check($start, $start - $end + 1);
  my $mask = $self->{mask};
  my $len = $end - $start + 1;
  splice @{$mask}, $start - 1, $len;
  $self->{length} -= $len;
  return $self;
}

=head2 find_deserts()

=cut

sub find_deserts
{
  my ($self) = @_;
  my @ranges;

  my $len   = $self->{length};
  my $mask  = $self->{mask};
  # stat will track if we are in a feature or a desert
  my $stat  = $mask->[0]->[1];
  my $start = $stat == 0 ? 1 : undef;
  my $end  = $stat == 0 ? 0 : 1;
  
  for my $x (0 .. $len - 1)
  {
    $stat = $mask->[$x]->[1];
    
    #moving from feature to desert
    if ($stat == 0 && $end != 0)
    {
      $start = $x + 1;
    }
    
    #moving from desert to feature
    elsif ($end == 0 && $stat != 0)
    {
      push @ranges, Bio::SeqFeature::Generic->new(
          -start        => $start,
          -end          => $x,
          -display_name => "$start..$x",
          -primary_tag  => 'desert',
      );
    }
    $end = $stat;
  }
  # end case - finish on a desert
  if ($stat == 0)
  {
    push @ranges, Bio::SeqFeature::Generic->new(
        -start        => $start,
        -end          => $len,
        -display_name => "$start..$len",
        -primary_tag  => 'desert',
    );    
  }
  return \@ranges;
}

=head2 find_overlaps()

=cut

sub find_overlaps
{
  my ($self) = @_;
  my @ranges;

  my $len   = $self->{length};
  my $mask  = $self->{mask};
  my $seqid = $self->{seqid};
  my $init  = $mask->[0]->[1];
  my $start = $init > 1 ? $init : undef;
  my $end  = $init > 1 ? $init : 1;
  my $flag  = $init > 1 ? $init : 0;

  my %list = ();
  for my $x (0 .. $len - 1)
  {
    my $stat = $mask->[$x]->[1];
    
    #moving from non overlap to overlap
    if ($stat > 1 && $end <= 1)
    {
      $start = $x+1;
      $flag = 1;
      $list{$_} = [$x+1, $x+1] foreach keys %{$mask->[$x]->[0]};
    }
    #moving from overlap to non overlap
    elsif ($end > 1 && $stat <= 1)
    {
      my $lapfeat = Bio::SeqFeature::Generic->new(
          -start        => $start,
          -end          => $x,
          -display_name => "$start..$x",
          -primary_tag  => 'overlap',
          -seq_id       => $seqid
      );
      foreach my $featid (keys %list)
      {
        my ($fstart, $fstop) = @{$list{$featid}};
        my $subfeat = Bio::SeqFeature::Generic->new(
          -start        => $fstart,
          -end          => $fstop,
          -display_name => $featid,
          -seq_id       => $seqid,
          -tag          => {
            -length     => $fstop - $fstart + 1,
            -featname   => $featid
          }
        );
        $lapfeat->add_SeqFeature($subfeat);
      }
      push @ranges, $lapfeat;
      %list = ();
      $flag = 0;
    }
    #inside an overlap
    elsif ($flag == 1)
    {
      foreach my $featid (keys %{$mask->[$x]->[0]})
      {
        if (exists $list{$featid})
        {
          $list{$featid}->[1] = $x+1;
        }
        else
        {
          $list{$featid} = [$x+1, $x+1];
        }
      }
    }
    $end = $stat;
  }
  return \@ranges;
}

=head2 what_overlaps()

=cut

sub what_overlaps
{
  my ($self, $coordinate) = @_;
  my $start = $coordinate - $self->{offset};
  $self->_sanity_check($start);
  my $poshash = $self->{mask}->[$start - 1]->[0];
  my @names = keys %{$poshash};
  my %feats = ();
  foreach my $name (@names)
  {
    $feats{$name} = $self->{index}->{$name};
  }
  return %feats;
}

=head2 what_objects_overlap()

=cut

sub what_objects_overlap
{
  my ($self, $coordinate) = @_;
  my $start = $coordinate - $self->{offset};
  $self->_sanity_check($start);
  my $poshash = $self->{mask}->[$start - 1]->[0];
  my @names = keys %{$poshash};
  my %feats = ();
  foreach my $name (@names)
  {
    $feats{$name} = $self->{feature}->{$name};
  }
  return %feats;
}

=head2 overlap_extents()

=cut

sub overlap_extents
{
  my ($self, $start, $size) = @_;
  $self->_sanity_check($start, $size);
  my $mask = $self->{mask};
  my $cstart = $start - 1;
  my %extents;
  for my $x ($cstart .. $cstart + $size - 1)
  {
    my @here = keys %{$mask->[$x]->[0]};
    foreach my $name (@here)
    {
      my $id = $self->{index}->{$name};
      if (! exists $extents{$id})
      {
        $extents{$id} = [$x + 1, $x + 1];
      }
      else
      {
        $extents{$id}->[1] = $x + 1;
      }
    }
  }
  return \%extents;
}

=head2 occlusion

=cut

sub occlusion
{
  my ($self, $start, $size) = @_;
  $self->_sanity_check($start, $size);
  my $mask = $self->{mask};
  my %feats;
  my $cstart = $start - 1;
  for my $x ($cstart .. $cstart + $size - 1)
  {
    my @here = keys %{$mask->[$x]->[0]};
    $feats{$_}++ foreach @here;
  }
  my %percs = map {$_ => sprintf "%.1f", $feats{$_} / $size} keys %feats;
  return %percs;
}

=head2 count_features()

=cut

sub count_features
{
  my ($self, $coordinate) = @_;
  $self->_sanity_check($coordinate);

  my $stat = $self->{mask}->[$coordinate - 1]->[1];
  return $stat;
}

=head2 count_features_in_range

=cut

sub count_features_in_range
{
  my ($self, $coordinate, $size) = @_;
  my $start = $coordinate - $self->{offset};
  $self->_sanity_check($start, $size);
  my %feats;
  my $mask = $self->{mask};
  my $cstart = $start - 1;
  for my $x ($cstart .. $cstart + $size - 1)
  {
    my @here = keys %{$mask->[$x]->[0]};
    $feats{$_}++ foreach @here;
  }
  return scalar values %feats;
}

=head2 features_in_range

=cut

sub features_in_range
{
  my ($self, $start, $size) = @_;
  $self->_sanity_check($start, $size);
  my %feats;
  my $mask = $self->{mask};
  my $cstart = $start - 1;
  for my $x ($cstart .. $cstart + $size - 1)
  {
    my @here = keys %{$mask->[$x]->[0]};
    $feats{$_}++ foreach @here;
  }
  my @results = map {$self->{index}->{$_}} keys %feats;
  return @results;
}

=head2 feature_objects_in_range

=cut

sub feature_objects_in_range
{
  my ($self, $start, $size) = @_;
  $self->_sanity_check($start, $size);
  my %feats;
  my $mask = $self->{mask};
  my $cstart = $start - 1;
  for my $x ($cstart .. $cstart + $size - 1)
  {
    my @here = keys %{$mask->[$x]->[0]};
    $feats{$_}++ foreach @here;
  }
  my @results = map {$self->{feature}->{$_}} keys %feats;
  return @results;
}


=head2 range_string

=cut

sub range_string
{
  my ($self, $start, $size) = @_;
  $self->_sanity_check($start, $size);
  my $string;
  my $mask = $self->{mask};
  my $cstart = $start - 1;
  for my $x ($cstart .. $cstart + $size - 1)
  {
    my $stat = $mask->[$x]->[1];
    $string .= $stat;
  }
  return $string;
}

=head1 ACCESSORS

=head2 seqid

=cut

sub seqid
{
  my ($self) = @_;
  return $self->{seqid};
}

=head2 len

=cut

sub len
{
  my ($self) = @_;
  return $self->{length};
}

=head2 feature_index

=cut

sub feature_index
{
  my ($self) = @_;
  return $self->{index};
}

=head1 PRIVATE

=head2 _sanity_check

=cut

sub _sanity_check
{
  my ($self, $start, $size) = @_;
  
  my $cstart = $start - 1;
  if ($cstart < 0)
  {
    $self->throw('Start argument to mask is not a positive index');
  }
  my $len = $self->{length};
  if ($cstart > $len)
  {
    $self->throw("Start argument $cstart is greater than mask length $len");
  }
  if ($size && $cstart + $size - 1 > $len)
  {
    warn("Size argument $size puts index greater than mask length $len\n");
  }
  return;
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
