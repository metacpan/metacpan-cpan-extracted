#
# BioStudio object
#

=head1 NAME

Bio::BioStudio

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::BioStudio;
use base qw(Bio::Root::Root);

use Bio::GeneDesign;
use Bio::BioStudio::ConfigData;
use Bio::BioStudio::Chromosome;
use Bio::BioStudio::Marker;
use Bio::BioStudio::Megachunk;
use Bio::BioStudio::Chunk;
use Bio::BioStudio::SeqFeature::Amplicon;
use Bio::BioStudio::SeqFeature::CDSVariant;
use Bio::BioStudio::SeqFeature::Chunk;
use Bio::BioStudio::SeqFeature::Codon;
use Bio::BioStudio::SeqFeature::Custom;
use Bio::BioStudio::SeqFeature::Megachunk;
use Bio::BioStudio::SeqFeature::ProposedDeletion;
use Bio::BioStudio::SeqFeature::RestrictionSite;
use Bio::BioStudio::SeqFeature::Tag;
use Bio::BioStudio::Repository qw(:BS);
use Bio::BioStudio::BLAST qw(:BS);
use Bio::BioStudio::DB qw(:BS);
use Digest::MD5;
use Scalar::Util qw(looks_like_number);
use File::Path qw(make_path);
use File::Basename;
use YAML::Tiny;
use Carp;
use DBI;

use strict;
use warnings;

our $VERSION = 2.10;

=head1 CONSTRUCTORS

=head2 new

 Title   : new
 Function:
 Returns : a new Bio::BioStudio object
 Args    :

=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);
 
  my ($repo) = $self->_rearrange([qw(repo)], @args);
  bless $self, $class;
  
  #Filepaths
  $self->{bioperl_path} = Bio::BioStudio::ConfigData->config('bioperl_path');
  $self->{script_path} = Bio::BioStudio::ConfigData->config('script_path');
  $self->{tmp_path} = Bio::BioStudio::ConfigData->config('tmp_path');

  $self->{conf} = Bio::BioStudio::ConfigData->config('conf_path');

  $self->throw("$repo does not exist") if ($repo && ! -e $repo);
  $repo = $repo || $self->{conf} . 'genome_repository/';
  $self->{repo} = $repo;
  
  #GBrowse configuration
  my $gbrowse = Bio::BioStudio::ConfigData->config('gbrowse_support');
  if ($gbrowse)
  {
    $self->{gbrowse} = 1;
  }
  else
  {
    $self->{gbrowse} = 0;
  }
  
  #Sun Grid Engine configuration
  my $sge = Bio::BioStudio::ConfigData->config('SGE_support');
  if ($sge)
  {
    $self->{SGE_support} = 1;
  }
  else
  {
    $self->{SGE_support} = 0;
  }
   
  #BLAST configuration
  my $bl = Bio::BioStudio::ConfigData->config('blast_support');
  if ($bl)
  {
    $self->{blast_support} = 1;
    $self->{blast_registry} = {};
  }
  else
  {
    $self->{blast_support} = 0;
  }
     
  #Cairo configuration
  my $cairo = Bio::BioStudio::ConfigData->config('cairo_support');
  if ($cairo)
  {
    $self->{cairo} = 1;
    $self->{cairo_conf_path} = $self->conf . 'cairo/';
    $self->{cairo_colors_path} = $self->{cairo_conf_path} . 'Cairo_colors.yaml';
  }
  else
  {
    $self->{cairo} = 0;
  }

  $self->{db_engine} = Bio::BioStudio::ConfigData->config('db_engine');

  #Custom features
  $self->{path_to_features} = $self->{conf} . 'features/';
  $self->{custom_features} = $self->_fetch_custom_features();
  
  #Custom markers
  $self->{path_to_markers} = $self->{conf} . 'markers/';
  $self->{custom_markers} = $self->_fetch_custom_markers();
  
  return $self;
}

=head1 FUNCTIONS

=head1 ACCESSORS

=cut

=head2 path_to_markers

=cut

sub path_to_markers
{
  my ($self) = @_;
  return $self->{path_to_markers};
}

=head2 custom_markers

=cut

sub custom_markers
{
  my ($self) = @_;
  return $self->{custom_markers};
}

=head2 path_to_repo

=cut

sub path_to_repo
{
  my ($self) = @_;
  return $self->{repo};
}

=head2 path_to_features

=cut

sub path_to_features
{
  my ($self) = @_;
  return $self->{path_to_features};
}

=head2 custom_features

=cut

sub custom_features
{
  my ($self) = @_;
  return $self->{custom_features};
}

=head2 tmp_path

=cut

sub tmp_path
{
  my ($self) = @_;
  return $self->{tmp_path};
}

=head2 script_path

=cut

sub script_path
{
  my ($self) = @_;
  return $self->{script_path};
}

=head2 gbrowse

=cut

sub gbrowse
{
  my ($self) = @_;
  return $self->{gbrowse};
}

=head2 SGE

=cut

sub SGE
{
  my ($self) = @_;
  return $self->{SGE_support};
}

=head2 BLAST

=cut

sub BLAST
{
  my ($self) = @_;
  return $self->{blast_support};
}

=head2 cairo

=cut

sub cairo
{
  my ($self) = @_;
  return $self->{cairo};
}

=head2 bioperl_path

=cut

sub bioperl_path
{
  my ($self) = @_;
  return $self->{bioperl_path};
}

=head2 conf

=cut

sub conf
{
  my ($self) = @_;
  return $self->{conf};
}

=head1 FUNCTIONS

=head2 set_chromosome

=cut

sub set_chromosome
{
  my ($self, @args) = @_;
  
  my ($chrname, $gbrowse) = $self->_rearrange([qw(chromosome gbrowse)], @args);
  
  $self->throw('No chromosome name provided') unless ($chrname);
  
  $gbrowse = $gbrowse || 0;
  
  my $chr = Bio::BioStudio::Chromosome->new(
    -name       => $chrname,
    -repo       => $self->{repo},
    -db_engine  => $self->{db_engine},
    -gbrowse    => $gbrowse,
  );
  
  return $chr;
}

=head2 gather_latest_genome

=cut

sub gather_latest_genome
{
  my ($self, @args) = @_;
  
  my ($species) = $self->_rearrange([qw(species)], @args);
  
  $self->throw('No species provided') unless ($species);
  
  my @objset = ();
  
  my $latest_names = _gather_latest($species, $self->{repo});
  
  foreach my $chrname (@{$latest_names})
  {
    my $chr = Bio::BioStudio::Chromosome->new(-name => $chrname);
    push @objset, $chr->seqobj;
  }
  return \@objset;
}

=head2 get_species_BLAST_database

=cut

sub get_species_BLAST_database
{
  my ($self, @args) = @_;
  
  if (! $self->{blast_support})
  {
    warn "BS_WARNING: No BLAST support in this installation of BioStudio.\n" . 
    "No BLAST factory will be made.\n";
    return undef;
  }
  my ($species) = $self->_rearrange([qw(species)], @args);
  
  $self->throw('No species provided') unless ($species);
  
  my $factory = _get_species_BLAST_database($species, $self->{repo});
  
  if (! exists $self->{blast_registry}->{$species})
  {
    $self->{blast_registry}->{$species} = $factory; 
  }
  
  return $factory;
}



=head2 BLASTn_short_sequence

=cut

sub BLASTn_short_sequence
{
  my ($self, @args) = @_;
  
  if (! $self->{blast_support})
  {
    warn "BS_WARNING: No BLAST support in this installation of BioStudio.\n" . 
    "No BLAST can be run.\n";
    return undef;
  }
  my ($species, $sequence, $count)
                       = $self->_rearrange([qw(species sequence count)], @args);
  
  $self->throw('No species provided to BLAST') unless ($species);
  
  $self->throw('No sequence provided to BLAST') unless ($sequence);
  
  $count = $count || undef;
  
  if (! ref $sequence)
  {
    my $sid = Digest::MD5::md5_hex(Digest::MD5::md5_hex(time().{}.rand().$$));
    my $obj = Bio::Seq->new(-seq => $sequence, -id => $sid);
    $sequence = $obj;
  }
  elsif (! $sequence->isa("Bio::Seq"))
  {
    $self->throw('Sequence to BLAST is not a Bio::Seq object');
  }
  my $seqlen = length $sequence->seq;
  if ($seqlen > 40)
  {
    $self->throw('Sequence length > 40 inappropriate for this function');
  }
  
  my $factory = undef;
  if (! exists $self->{blast_registry}->{$species})
  {
    $factory = _get_species_BLAST_database($species, $self->{repo});
    $self->{blast_registry}->{$species} = $factory; 
  }
  else
  {
    $factory = $self->{blast_registry}->{$species};
  }
  
  my @hits = _blastn_short($sequence, $factory);
  
  return defined $count ? scalar @hits : @hits;
}

=head2 species_list

=cut

sub species_list
{
  my ($self) = @_;
  return _list_species($self->{repo});
}

=head2 source_list

=cut

sub source_list
{
  my ($self) = @_;
  return _list_repository($self->{repo});
}

=head2 gv_increment_warning

=cut

sub gv_increment_warning
{
  my ($self, $chromosome) = @_;

  my $species = $chromosome->species();
  my $seqid   = $chromosome->seq_id();
  my $cver    = $chromosome->chromosome_version();
  my $ngver   = $chromosome->genome_version() + 1;
  my $gscale  = $species . q{_} . $seqid . q{_} . $ngver . q{_} . $cver;
  my $dblist  = $self->source_list();
  return $gscale if (exists $dblist->{$gscale});
  return 0;
}

=head2 cv_increment_warning

=cut

sub cv_increment_warning
{
  my ($self, $chromosome) = @_;

  my $species = $chromosome->species();
  my $seqid   = $chromosome->seq_id();
  my $gver    = $chromosome->genome_version();
  my $cver    = $chromosome->chromosome_version();
  my $ncver   = $chromosome->GD->pad($cver + 1, 2);
  my $cscale = $species . q{_} . $seqid . q{_} . $gver  . q{_} . $ncver;
  my $dblist = $self->source_list();
  return $cscale if (exists $dblist->{$cscale});
  return 0;
}

=head2 prepare_repository

=cut

sub prepare_repository
{
  my ($self, @args) = @_;
  
  my ($species, $chrname) = $self->_rearrange([qw(species chrname)], @args);
  
  my $path = _prepare_repository($self->{repo}, $species, $chrname);
  return $path;
}

=head1 ACCESSORS

=head2 genome_repository

A path to a directory that can be used as a genome repository. Defaults to
the config dir as set at install slash genome_repository.

=cut

sub genome_repository
{
  my ($self, $value) = @_;
  if ($value)
  {
    $self->throw("$value does not exist") unless (-e $value);
    $value .= q{/} unless substr($value, -1, 1) eq q{/};
    $self->{repo} = $value;
  }
  return $self->{repo};
}

=head2 db_engine

A path to a directory that can be used as a genome repository. Defaults to
the config dir as set at install slash genome_repository.

=cut

sub db_engine
{
  my ($self, $value) = @_;
  if ($value)
  {
    $self->{db_engine} = $value;
  }
  return $self->{db_engine};
}

=head2 _fetch_custom_features()

Returns a hashref of custom features in the BioStudio configuration directory.
Each key is a feature name, each value is a Bio::SeqFeature object.

=cut

sub _fetch_custom_features
{
  my ($self) = @_;
  my %features;
  my $path = $self->{path_to_features};
  if (-e $path)
  {
    opendir(my $FDIR, $path);
    my @features = grep {$_ =~ m{\.fasta\z}msix} readdir($FDIR);
    closedir $FDIR;
    foreach my $feature (@features)
    {
      my $path = $self->path_to_features . $feature;
      my ($iterator, $name) = _import_fasta($path);
      my ($type, $sequence) = (undef, undef);
      while ( my $obj = $iterator->next_seq() )
      {
        $type = $obj->id;
        $sequence = $obj->seq;
        last;
      }
      my $prototype = Bio::BioStudio::SeqFeature::Custom->new(
        -prototype => $name,
        -primary_tag => $type,
        -default_sequence => $sequence,
      );
      $features{$name} = $prototype;
    }
  }

  return \%features;
}

=head2 _fetch_custom_markers

=cut

sub _fetch_custom_markers
{
  my ($self) = @_;
  my %markers;
  
  my $path = $self->{path_to_markers};
  if (-e $path)
  {
    opendir(my $FDIR, $path);
    my @markers = grep {$_ =~ m{\.gff\z}msix} readdir($FDIR);
    closedir $FDIR;
    my $n = 1;
    foreach my $marker (@markers)
    {
      my $name = 'marker' . $n;
      $n++;
      $name = $1 if ($marker =~ m{([\w\d]+)\.gff\z}msix);
      my $path = $self->{path_to_markers} . $marker;
      my $db = Bio::DB::SeqFeature::Store->new(
        -adaptor           => 'memory',
        -gff               => $path,
        -index_subfeatures => 'true'
      );
      $markers{$name} = Bio::BioStudio::Marker->new(
        -name => $name,
        -db => $db
      );
    }
  }
  return \%markers;
}

=head2 _import_fasta

=cut

sub _import_fasta
{
  my ($path) = @_;
  my $iterator = Bio::SeqIO->new(-file => $path);
  my ($filename, $dirs, $suffix) = fileparse($path, qr/\.[^.]*/x);
  return ($iterator, $filename);
}

1;

=head2 DESTROY

=cut

sub DESTROY
{
  my ($self) = @_;
  my @factories = values %{$self->{blast_registry}};
  foreach my $factory (@factories)
  {
    $factory->cleanup();
  }
  $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
  return;
}

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, BioStudio developers
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

=cut