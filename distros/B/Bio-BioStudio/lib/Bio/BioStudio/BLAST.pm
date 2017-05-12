#
# BioStudio BLAST functions
#

=head1 NAME

Bio::BioStudio::BLAST

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::BLAST;
require Exporter;

use Bio::BioStudio::ConfigData;
use Bio::BioStudio::Exceptions;
use Bio::BioStudio::Repository qw(:BS);
use Bio::Tools::Run::StandAloneBlastPlus;
use File::Path qw(remove_tree);
use Carp;
use English qw(-no_match_vars);

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';

our @EXPORT_OK = qw(
  _get_species_BLAST_database _blastn_short
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);

=head1 Functions

=cut

=head2 _get_species_database

=cut

sub _get_species_BLAST_database
{
  my ($species, $repo) = @_;
  $repo = _endslash($repo) || _repobase();
  my $blastdir = _path_to_BLAST_database($species, $repo);
  
  #If BLAST database does not exist make a new one
  if (! -e $blastdir)
  {
    return _make_species_database($species, $repo);
  }
  
  #If BLAST database is out of date make a new one
  my $bit = _verify_BLAST_index($species, $repo);
  if (! $bit)
  {
    remove_tree($blastdir);
    return _make_species_database($species, $repo);
  }
  
  #Recover existing BLAST database
  my $factory = Bio::Tools::Run::StandAloneBlastPlus->new(
    -db_dir  => $blastdir,
    -db_name => _BLAST_name($species),
  );
  return $factory;
}

=head2 _BLAST_name

=cut

sub _BLAST_name
{
  my ($species) = @_;
  return 'BLAST_' . $species;
}

=head2 _path_to_BLAST_database

=cut

sub _path_to_BLAST_database
{
  my ($species, $repo) = @_;
  $repo = _endslash($repo) || _repobase();
  return $repo . $species . q{/} . '_blast/';
}

=head2 _path_to_BLAST_index

=cut

sub _path_to_BLAST_index
{
  my ($species, $repo) = @_;
  my $blbase = _path_to_BLAST_database($species, $repo);
  return $blbase . '_chrindex.txt';  
}

=head2 _fetch_BLAST_index

=cut

sub _fetch_BLAST_index
{
  my ($species, $repo) = @_;
  my $indexpath = _path_to_BLAST_index($species, $repo);
  my %index = ();
  if (-e $indexpath)
  {
    open (my $BLASTINDEX, '<', $indexpath)
      || croak "BS_ERROR: Can't open BLAST index $indexpath : $OS_ERROR";
    my $indexref = do {local $/ = <$BLASTINDEX>};
    close $BLASTINDEX;
    my @indexkeys = split m{\s}, $indexref;
    %index = map {$_ => 1} @indexkeys; 
  }
  return \%index;
}

=head2 _make_BLAST_index

=cut

sub _make_BLAST_index
{
  my ($species, $repo, $chrlist) = @_;
  my $indexpath = _path_to_BLAST_index($species, $repo); 
  my @list = @{$chrlist};
  my $str = join qq{\t}, @list;
  open (my $BLASTINDEX, '>', $indexpath)
    || croak "BS_ERROR: Can't write BLAST index $indexpath : $OS_ERROR";
  print $BLASTINDEX $str;
  close $BLASTINDEX;
  return;
}

=head2 _verify_BLAST_index

=cut

sub _verify_BLAST_index
{
  my ($species, $repo) = @_;
  my %index = %{_fetch_BLAST_index($species, $repo)};
  my @chrs = @{_gather_latest($species, $repo)};
  my %latest = map {$_ => 1} @chrs;
  my $flags = 0;
  foreach my $chr (keys %latest)
  {
    $flags++ if (! exists $index{$chr});
  }
  foreach my $chr (keys %index)
  {
    $flags++ if (! exists $latest{$chr});
  }
  return $flags ? 0 : 1;
}


=head2 _make_species_database

=cut

sub _make_species_database
{
  my ($species, $repo) = @_;
  my @latest = @{_gather_latest($species, $repo)};
  my @blastdata = ();
  foreach my $chrname (@latest)
  {
    my $chr = Bio::BioStudio::Chromosome->new(-name => $chrname);
    my $seqobj = $chr->seqobj;
    my $seqlen = $seqobj->length();
    push @blastdata, $chr->seqobj;
  }
  my $blastdir = _path_to_BLAST_database($species, $repo);
  mkdir $blastdir if (! -e $blastdir);
  my $factory = Bio::Tools::Run::StandAloneBlastPlus->new(
    -db_dir  => $blastdir,
    -db_name => _BLAST_name($species),
    -db_data => \@blastdata,
    -create  => 1,
  );
  $factory->make_db();
  _make_BLAST_index($species, $repo, \@latest);
  return $factory;
}

=head2 _blastn_short

Pass it a ~30mer sequence and a BLAST factory, it will return the number of
plausible hits it makes

=cut

sub _blastn_short
{
  my ($seqobj, $BLAST_factory) = @_;
  $BLAST_factory->run(
    -method => 'blastn',
    -query  => [$seqobj],
    -method_args => [
      -word_size      => 7,
      -perc_identity  => 85,
      -reward         => 1,
      -penalty        => -3,
      -evalue         => 0.0001,
    ]
  );
  $BLAST_factory->rewind_results;
  my @hits;
  while (my $result = $BLAST_factory->next_result)
  {
    while( my $hit = $result->next_hit())
    {
      while( my $hsp = $hit->next_hsp())
      {
        push @hits, $hsp->start('subject');
      }
    }
  }
  return @hits;
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

