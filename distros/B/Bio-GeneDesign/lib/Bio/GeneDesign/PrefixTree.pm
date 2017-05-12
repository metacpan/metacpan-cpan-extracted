#
# GeneDesign module for sequence segmentation
#

=head1 NAME

GeneDesign::PrefixTree - A suffix tree implementation for nucleotide searching

=head1 VERSION

Version 5.54

=head1 DESCRIPTION

  GeneDesign uses this object to parse peptide sequences for restriction enzyme
  recognition site possibilities

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>

=cut

package Bio::GeneDesign::PrefixTree;

use 5.006;
use strict;
use warnings;

my $VERSION = 5.54;

=head1 Functions

=head2 new

Create a new suffix tree object.

    my $tree = Bio::GeneDesign::PrefixTree->new();

=cut

sub new
{
  my ($class) = @_;
  my $self = { root => {} };
  bless $self, $class;
  return $self;
}

=head2 add_prefix

Add suffixes to the tree. You can add a sequence, an id (which can be an array
reference of ids), and a scalar note.

    $tree->add_prefix('GGATCC', 'BamHI', "i hope this didn't pop up");
    $tree->add_prefix('GGCCC', ['OhnoI', 'WoopsII'], "I hope these pop up");

=cut

sub add_prefix
{
  my ($self, $sequence, $id, $note) = @_;
  my @ids = ref($id) eq "ARRAY" ? @$id  : ($id);
  my $next = $self->{ root };
  my $offset = 0;
  my $len = length($sequence);
  while ($offset < $len)
  {
    my $char = substr($sequence, $offset, 1);
    $next->{$char} = {} unless exists $next->{$char};
    $next = $next->{$char};
    $offset++;
  }
  $next->{ids} = {} unless exists $next->{ids};
  foreach my $id (@ids)
  {
    $next->{ids}->{$id} = [] unless (exists $next->{ids}->{$id});
    push @{$next->{ids}->{$id}}, $note if ($note);
  }
  $next->{sequence} = $sequence unless exists $next->{sequence};
  $next->{count} = $next->{count} ? $next->{count} + 1  : 1;
  return;
}

=head2 find_prefixes()

Pass a sequence to the tree and find the positions of hits. It will return an
array that is made up of array references; each array reference represents a hit
where the 0 index is the name of the subsequence in the tree, the 1 index is the
offset in the query sequence (1 BASED, NOT 0 BASED), the 2 index is the
subsequence, and the 3 index is whatever note is associated with the
subsequence.

  my @hits = $tree->find_prefixes('AAAGGATCCATCGCATACGAGGCCCCACCG');

  # @hits = (['BamHI', 4, 'GGATCC', 'i hope this didn't pop up'],
  #          ['OhnoI', 21, 'GGCCC', 'I hope these pop up'],
  #          ['WoopsII', 21, 'GGCCC', 'I hope these pop up']
  #);

=cut

sub find_prefixes
{
  my ($self, $sequence) = @_;
  my @locations;
  my @seq = split('', $sequence);
  my $limit = scalar @seq;
  for my $seq_idx (0..$limit)
  {
    my $cur_idx = $seq_idx;
    my $ref_idx = $seq[$seq_idx];
    my $ref     = $self->{root};
    while (++$cur_idx < $limit and $ref)
    {
      if ($ref->{ids})
      {
        foreach my $id (sort {$a cmp $b} keys %{$ref->{ids}})
        {
          my $notes = $ref->{ids}->{$id};
          push @locations, [$id, $seq_idx + 1, $ref->{sequence}, $notes];
        }
      }
      $ref_idx = $seq[$cur_idx];
      $ref = $ref->{$ref_idx};
    }
  }
  return @locations;
}


=head2 find_ntons

Pass a number, n. The tree will report all of the sequences inside it that it
has only seen n times. The return value is a hash, where the keys are the
sequences and the values are hash references containing the ids and notes
associated with each sequence in the tree.

  my %twos = $tree->find_ntons(2);

  # %twos = ('GGGCC' => {'OhnoI' => ['I hope these pop up'],
  #                    'WoopsII' => ['I hope these pop up']}
  # );


=cut

sub find_ntons
{
  my ($self, $n) = @_;
  $n = $n || 1;
  my %ntons;
  my $root = $self->{ root };
  my @nodes = map { $root->{$_} } sort {$a cmp $b} keys %{$root};
  foreach my $node (@nodes)
  {
    if (exists $node->{sequence} && $node->{count} == $n)
    {
      $ntons{$node->{sequence}} = $node->{ids};
    }
    push @nodes, map { $node->{$_} }
                 grep {$_ ne 'sequence' && $_ ne 'ids' && $_ ne 'count'}
                 sort {$a cmp $b} keys %{$node};
  }
  return %ntons;
}
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, GeneDesign developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the GeneDesign developers may
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

=cut
