#
# BioStudio module for sequence modeling
#

=head1 NAME

Bio::BioStudio::Chromosome

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::BioStudio::Chromosome;

use Bio::GeneDesign;
use Bio::BioStudio::Mask;
use Bio::BioStudio::Exceptions;
use Bio::BioStudio::DB qw(:BS);
use Bio::BioStudio::Repository qw(:BS);
use Bio::Annotation::Comment;
use Time::Format qw(%time);
use Text::Wrap qw($columns &wrap);
use URI::Escape;
use Bio::Seq;
use English qw(-no_match_vars);
use Carp;

use strict;
use warnings;

use base qw(Bio::Root::Root);

our $VERSION = 2.10;

my $VERNAME = qr{([\w]+)_[chr]*([\w\d]+)_(\d+)_(\d+)([\_\w+]*)}msix;
my %PHASES = (0 => 1, 1 => 1, 2 => 1);
my %conttypes = ('chromosome' => 1);

=head1 CONSTRUCTORS

=head2 new

 Title   : new
 Function:
 Returns : a new Bio::BioStudio::Chromosome object
 Args    :

=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  bless $self, $class;

  my ($name, $repo, $gbrowse) = $self->_rearrange(
    [qw(NAME REPO GBROWSE)], @args);
  $self->throw('No name argument provided to chromosome new') unless ($name);

  $repo = $repo || _repobase();
  $repo .= q{/} unless substr($repo, -1, 1) eq q{/};
  $self->{repo} = $repo;
  
  if ($name =~ $VERNAME)
  {
    my ($species, $chrid, $genver, $chrver, $tag) = ($1, $2, $3, $4, $5);
    
    $self->{species} = $species;
    $self->{GD} = Bio::GeneDesign->new();
    $self->{GD}->set_organism(-organism_name => $species);
    $self->{chromosome_id} = $chrid;
    $self->{genome_version} = $genver;
    $self->{chromosome_version} = $chrver;
    $self->{seq_id} = 'chr' . $chrid;
    $self->{tag} = $tag ? $tag : undef;
    $self->{provisional} = -1;
    $self->{mask} = undef;
    
    if ($gbrowse && Bio::BioStudio::ConfigData->config('gbrowse_support'))
    {
      $self->{gbrowse} = 1;
      require Bio::BioStudio::GBrowse;
      import Bio::BioStudio::GBrowse qw(:BS);
      add_to_GBrowse($self);
    }
    else
    {
      $self->{gbrowse} = 0;
    }
    #my $path = $self->path_to_GFF();
    #if (! -e $path)
    #{
    #  $self->throw('Cannot find $path in repository!');
    #}
  }
  else
  {
    $self->throw("Can't parse $name");
  }
  
  return $self;
}

=head2 DESTROY

=cut

sub DESTROY
{
  my ($self) = @_;
  if ($self->{provisional} == 1)
  {
    drop_database($self);
    my $path = $self->path_to_GFF();
    system "rm $path" if (-e $path);
    if ($self->{gbrowse})
    {
      remove_from_GBrowse($self);
    }
  }
  $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
  return;
}

=head1 FUNCTIONS

=cut

=head1 ACCESSORS

=head2 provisional

Provisional databases are removed from the repository and the db engine when the
programs shut down.

=cut

sub provisional
{
  my ($self, $value) = @_;
  if ($value)
  {
    $self->{provisional} = $value;
  }
  return $self->{provisional};
}

=head2 name

=cut

sub name
{
  my ($self) = @_;
  my $name = $self->{species} . q{_} . $self->{seq_id} . q{_};
  $name .= $self->{genome_version} . q{_} . $self->{chromosome_version};
  $name .= $self->{tag} if ($self->{tag});
  return $name;
}

=head2 repo

=cut

sub repo
{
  my ($self) = @_;
  return $self->{repo};
}

=head2 path_to_GFF

=cut

sub path_to_GFF
{
  my ($self) = @_;
  my $path = _path_in_repository($self);
  return $path;
}

=head2 path_to_DB

=cut

sub path_to_DB
{
  my ($self) = @_;
  my $path = _path_to_DB($self);
  return $path;
}

=head2 path_in_repo

=cut

sub path_in_repo
{
  my ($self) = @_;
  my $path = _dir_in_repository($self);
  return $path;
}

=head2 gbrowse

=cut

sub gbrowse
{
  my ($self) = @_;
  return $self->{gbrowse};
}

=head2 database

=cut

sub database
{
  my ($self, $refresh) = @_;
  return $self->db($refresh);
}

=head2 db

=cut

sub db
{
  my ($self, $refresh) = @_;
  $refresh = $refresh || 0;
  if (! $self->{database} || $refresh)
  {
    $self->{database} = fetch_database($self, $refresh);
  }
  return $self->{database};
}

=head2 container_id

=cut

sub container_id
{
  my ($self) = @_;
  if (! defined $self->{container_id})
  {
    my @containers = $self->db->features(
      -seq_id => $self->{seq_id},
      -type => 'chromosome',
      -name => $self->{seq_id},
    );
    $self->{container_id} = $containers[0]->primary_id();
  }
  return $self->{container_id};
}

=head2 feature_mask

=cut

sub feature_mask
{
  my ($self) = @_;
  if (! defined $self->{mask})
  {
    my $mask = Bio::BioStudio::Mask->new(-sequence => $self->seqobj);
    my $db = $self->db;
    my @featlist = $db->features( -seq_id => $self->{seq_id} );
    @featlist = grep {! exists $conttypes{$_->primary_tag}} @featlist;
    $mask->add_to_mask(\@featlist);
    $self->{mask} = $mask;
  }
  return $self->{mask};
}

=head2 type_mask

=cut

sub type_mask
{
  my ($self, $type) = @_;
  my $mask = Bio::BioStudio::Mask->new(-sequence => $self->seqobj);
  my $db = $self->db;
  my @featlist = $db->features( -seq_id => $self->{seq_id}, -type => $type );
  $mask->add_to_mask(\@featlist);
  return $mask;
}

=head2 empty_mask

=cut

sub empty_mask
{
  my ($self) = @_;
  my $mask = Bio::BioStudio::Mask->new(-sequence => $self->seqobj);
  return $mask;
}

=head2 species

=cut

sub species
{
  my ($self) = @_;
  return $self->{species};
}

=head2 genome_version

=cut

sub genome_version
{
  my ($self) = @_;
  return $self->{genome_version};
}

=head2 chromosome_version

=cut

sub chromosome_version
{
  my ($self) = @_;
  return $self->{chromosome_version};
}

=head2 tag

=cut

sub tag
{
  my ($self) = @_;
  return $self->{tag};
}

=head2 seq_id

=cut

sub seq_id
{
  my ($self) = @_;
  return $self->{seq_id};
}

=head2 chromosome_id

=cut

sub chromosome_id
{
  my ($self) = @_;
  return $self->{chromosome_id};
}

=head2 signature

=cut

sub signature
{
  my ($self) = @_;
  return $self->{genome_version} . q{_} . $self->{chromosome_version};
}

=head2 sequence

=cut

sub sequence
{
  my ($self) = @_;
  if (! defined $self->{sequence})
  {
    $self->{sequence} = $self->db->fetch_sequence($self->{seq_id});
  }
  return $self->{sequence};
}

=head2 len

=cut

sub len
{
  my ($self) = @_;
  my $sequence = $self->sequence();
  return length $sequence;
}

=head2 seqobj

=cut

sub seqobj
{
  my ($self) = @_;
  my $seqobj = Bio::Seq->new(-id => $self->{seq_id}, -seq => $self->sequence);
  return $seqobj;
}

=head2 comments

=cut

sub comments
{
  my ($self) = @_;
  if (! defined ($self->{comments}))
  {
    $self->{comments} = $self->fetch_comments();
  }
  return @{$self->{comments}};
}

=head2 add_to_comments

=cut

sub add_to_comments
{
  my ($self, $value) = @_;
  $self->comments();
  if (defined $value && ref $value ne 'ARRAY')
  {
    $value = [$value];
  }
  if (defined $value && ref $value eq 'ARRAY')
  {
    my @arr = @{$value};
    foreach my $line (@arr)
    {
      $line .= "\n" if (substr $line, -1, 1 ne "\n");
      unshift @{$self->{comments}}, $line;
    }
  }
  return @{$self->{comments}};
}

=head2 add_reason

=cut

sub add_reason
{
  my ($self, $editor, $memo) = @_;
  $self->comments();
  my $header = q{# # # } . $self->today();
  $header .= q{ by } . $editor . q{ (} . $memo . q{)};
  $self->add_to_comments([$header]);
  return;
}

=head2 GD

=cut

sub GD
{
  my ($self) = @_;
  return $self->{GD};
}

=head1 FUNCTIONS

=cut

=head2 rollback

=cut

sub rollback
{
  my ($self) = @_;
  $self->provisional(1);
  return;
}

=head2 fetch_comments

=cut

sub fetch_comments
{
  my ($self) = @_;
  my $path = $self->path_to_GFF;
  open (my $FILE, '<', $path) || $self->throw("Can't find $path: $OS_ERROR\n");
  my $ref = do {local $/ = <$FILE>};
  close $FILE;
  my @lines = split m{\n}, $ref;
  my @precomments = grep {$_ =~ m{^\# [^\#.]+ }msx} @lines;
  my @comments = map {$_ . "\n"} @precomments;
  return \@comments;
}

=head2 fetch_features

=cut

sub fetch_features
{
  my ($self, @args) = @_;
  my ($type, $name)
    = $self->_rearrange([qw(
        type
        name)], @args
  );
  if ($type && $name)
  {
    return $self->db->features(
      -seq_id => $self->seq_id(),
      -type => $type,
      -name => $name,
    );
  }
  if ($type)
  {
    return $self->db->get_features_by_type($type);
  }
  if ($name)
  {
    my @res = $self->db->get_feature_by_name($name);
    return $res[0];
  }
  else
  {
    return $self->db->get_all_features();
  }
}

=head2 add_feature

=cut

sub add_feature
{
  my ($self, @args) = @_;

  my ($f, $atts, $comments, $source)
    = $self->_rearrange([qw(
        feature
        attributes
        comments
        source)], @args
  );

  $self->throw('no feature to add!') unless ($f);
  
  $self->throw('argument to comments is not array reference')
    if ($comments && ref $comments ne 'ARRAY');
    
  $self->throw('object ' . ref $f . ' is not a Bio::SeqFeatureI')
    unless ($f->isa('Bio::SeqFeatureI'));

  $source = $source || 'BIO';

  $atts   = $atts || {};
  $atts->{intro} = $self->signature unless (exists $atts->{intro});
  $atts->{version} = 1 unless (exists $atts->{version});
  $atts->{wtpos} = $f->start unless (exists $atts->{wtpos});
  $atts->{$_} = join(q{,}, $f->get_tag_values($_)) foreach ($f->get_all_tags);
  my $fname = $f->display_name;
  my $mask = $self->feature_mask();
  if (exists $mask->feature_index->{$fname})
  {
    my $excuse = 'a feature with name ' . $fname . ' already exists';
    Bio::BioStudio::Exception::PreserveUniqueNames->throw($excuse);
  }

  my ($start, $end) = ($f->start, $f->end);
  my $newfeat = $self->db->new_feature(
    -seq_id       => $self->{seq_id},
    -start        => $start,
    -end          => $end,
    -primary_tag  => $f->primary_tag,
    -source       => $source,
    -load_id      => $fname,
    -display_name => $fname,
    -attributes   => $atts,
  ) || Bio::BioStudio::Exception::AddFeature->throw('Cannot add new feature');
  $self->{mask}->add_to_mask([$newfeat]);
  if ($newfeat->has_tag('parent_id'))
  {
    my @parents = $self->db->get_feature_by_name($newfeat->Tag_parent_id);
    my $parent = $parents[0];
    $parent->add_SeqFeature($newfeat);
  }
  if ($newfeat->has_tag('newseq'))
  {
    my $len = $end - $start + 1;
#    print "\tadding feature with sequence ", $newfeat->Tag_newseq , "\n";
#    print "\t\told sequence ", $newfeat->Tag_wtseq , "\n";
    $self->sequence();
    substr $self->{sequence}, $start - 1, $len, $newfeat->Tag_newseq;
  }
  #print "\tmade a $newfeat\n";
  #print "\t", $newfeat->display_name, "\n";
  $comments = $comments || $fname . ' added';
  $self->add_to_comments($comments) if ($comments);
  return $newfeat;
}

=head2 modify_feature

Check if sequence requires moving things downstream

=cut

sub modify_feature
{
  my ($self, @args) = @_;
  
  my ($f, $newseq, $comments, $tags, $preserve)
    = $self->_rearrange([qw(
      feature
      new_sequence
      comments
      tags
      preserve_overlapping_features
    )], @args
  );

  $self->throw('no feature to modify!') unless ($f);
  
  $self->throw('argument to comments is not array reference')
    if ($comments && ref $comments ne 'ARRAY');

  $self->sequence();
  if ($newseq && $preserve)
  {
    $self->{mask} || $self->feature_mask();
    my $size = $f->end - $f->start + 1;
    my $extents = $self->{mask}->overlap_extents($f->start, $size);
    foreach my $featid (keys %{$extents})
    {
      next if ($featid == $f->primary_id());
      my ($sstart, $send) = @{$extents->{$featid}};
      my $fstart = $f->start;
      next if ($sstart == $fstart && $send == $f->end);
      my $rstart = $sstart - $fstart;
      my $rsize = $send - $sstart + 1;
      my $fseq = substr $self->{sequence}, $sstart - 1, $rsize;
      substr $newseq, $rstart, $rsize, $fseq;
    }
  }
  if ($newseq)
  {
    my $oldseq = $self->sequence();
    my $newsequence = substr($oldseq, 0, $f->start - 1);
    $newsequence .= $newseq;
    $newsequence .= substr($oldseq, $f->end);
    $self->{sequence} = $newsequence;
  }
  
  $tags = $tags || {};
  if ($tags)
  {
    my @keys = keys %{$tags};
    foreach my $tag (@keys)
    {
      $f->add_tag_value($tag, $tags->{$tag});
    }
    $f->update();
  }

  $comments = $comments || $f->display_name . ' modified';
  $self->add_to_comments($comments);
  
  return;
}

=head2 insert_feature

=cut

sub insert_feature
{
  my ($self, @args) = @_;
  my $a = [qw(feature attributes position comments destroy)];
  my ($f, $atts, $position, $comments, $destroy) = $self->_rearrange($a, @args);

  $self->throw('no feature to add!') unless ($f);
  
  $self->throw('argument to comments is not array reference')
    if ($comments && ref $comments ne 'ARRAY');
    
  #$self->throw('object ' . ref $f . ' is not a Bio::SeqFeature')
  #  unless ($f->isa('Bio::SeqFeature'));

  $position = $position || 1;
  $destroy  = $destroy || 0;
  my @destroyed = ();
  my $insseq = $f->seq->seq;
  my $fname = $f->display_name;
  my $movelen = length $insseq;
  my $db = $self->db();
  my $mask = $self->feature_mask();
  if (exists $mask->feature_index->{$fname})
  {
    my $excuse = 'a feature with name ' . $fname . ' already exists';
    Bio::BioStudio::Exception::PreserveUniqueNames->throw($excuse);
  }
  my %olapids = $mask->what_overlaps($position);
  my @olapfeats = values %olapids;
  if (! $destroy && scalar @olapfeats)
  {
    @destroyed = keys %olapids;
    my $excuse = 'this action will destroy features ' . join q{, }, @destroyed;
    Bio::BioStudio::Exception::PreserveExsistingFeature->throw($excuse);
  }
  foreach my $featid (values %olapids)
  {
    my $feat = $self->db->fetch($featid);
    $feat->end($feat->end + $movelen);
    $feat->update();
    push @destroyed, $feat->display_name;
  }
  my @shifts = $db->features(
      -seqid      => $self->{seq_id},
      -start      => $position,
      -range_type => 'contains'
  );
  foreach my $feat (@shifts)
  {
    $feat->start($feat->start + $movelen);
    $feat->end  ($feat->end   + $movelen);
    $feat->update();
  }

  $atts   = $atts || {};
  $atts->{intro} = $self->signature unless (exists $atts->{intro});
  $atts->{version} = 1 unless (exists $atts->{version});
  $atts->{display_name} = $fname if (! exists $atts->{display_name});
  $atts->{$_} = join(q{,}, $f->get_tag_values($_)) foreach $f->get_all_tags;

  my $newfeat = $db->new_feature(
    -start        => $position,
    -end          => $position + $movelen - 1,
    -seq_id       => $self->{seq_id},
    -primary_tag  => $f->primary_tag,
    -source       => $f->source_tag,
    -attributes   => $atts,
    -load_id      => $fname,
    -display_name => $fname,
  );
  $self->{mask}->insert_sequence($newfeat);
  my $newsequence = substr $self->{sequence}, 0, $position - 1;
  $newsequence .= $insseq;
  $newsequence .= substr $self->{sequence}, $position - 1;
  $self->{sequence} = $newsequence;
  my $container = $self->db->fetch($self->container_id);
  $container->end($container->end + $movelen);
  $container->update;
  $comments = $comments || $fname . ' inserted';
  if (scalar @destroyed)
  {
    $comments .= q{ (};
    $comments .= join q{, }, @destroyed;
    $comments .= q{ destroyed)};
  }
  $self->add_to_comments($comments);
  return $newfeat;
}

=head2 delete_region

=cut

sub delete_region
{
  my ($self, @args) = @_;

  my $a = [qw(start stop name comments)];
  my ($start, $stop, $name, $comments) = $self->_rearrange($a, @args);

  $self->throw('no start coordinate') unless ($start);
  $self->throw('no stop coordinate') unless ($stop);
  $self->throw('start and stop do not parse') if ($stop < $start);
  
  $self->throw('argument to comments is not array reference')
    if ($comments && ref $comments ne 'ARRAY');

  my $db = $self->db();
  $self->{mask} || $self->feature_mask();
  my $size = $stop - $start + 1;
  my @olaps = $self->{mask}->features_in_range($start, $size);
  foreach my $featid (@olaps)
  {
    my $feat = $self->db->fetch($featid);
    #Deletion feature
    if ($feat->primary_tag eq 'deletion')
    {
      $feat->start($start);
      $feat->end($start + 1);
    }
    #Container
    elsif ($feat->start < $start && $feat->end > $stop)
    {
      $feat->end($feat->end - $size);
      $feat->update();
    }
    #Three prime truncated
    elsif ($feat->end <= $stop && $feat->start < $start)
    {
      my $common = $feat->end - $start + 1;
      $feat->end($feat->end - $common);
      $feat->update();
    }
    #Five prime truncated
    elsif ($feat->start <= $stop && $feat->end > $stop)
    {
      my $common = $stop - $feat->start + 1;
      $feat->start($feat->start + $common);
      $feat->update();
    }
    #Completely contained
    else
    {
      next if ($feat->has_tag('parent_id'));
      $db->delete($feat) || Bio::BioStudio::Exception::DeleteFeature->throw('Cannot delete feature');
    }
  }
  #my @unaffecteds = $db->features(
  #    -seqid      => $self->{seq_id},
  #    -start      => 1,
  #    -end        => $start - 1,
  #    -range_type => 'contains'
  #);
  my @shifts = $db->features(
      -seqid      => $self->{seq_id},
      -start      => $stop,
      -range_type => 'contains'
  );
  foreach my $feat (@shifts)
  {
    $feat->start($feat->start - $size);
    $feat->end  ($feat->end   - $size);
    $feat->update();
  }

  my $atts = {};
  $atts->{intro} = $self->signature unless (exists $atts->{intro});
  $atts->{version} = 1 unless (exists $atts->{version});
  $atts->{display_name} = $name || 'del_' . $start . q{_} . $stop;

  my $newfeat = $db->new_feature(
    -start        => $start,
    -end          => $start + 1,
    -seq_id       => $self->{seq_id},
    -primary_tag  => 'deletion',
    -source       => 'BIO',
    -attributes   => $atts,
    -load_id      => $atts->{display_name},
    -display_name => $atts->{display_name},
  );
  $self->{mask}->remove_sequence($start, $stop);
  my $newsequence = substr $self->{sequence}, 0, $start - 1;
  $newsequence .= substr $self->{sequence}, $stop;
  $self->{sequence} = $newsequence;

  my $container = $self->db->fetch($self->container_id);
  $container->end($container->end - $size);
  $container->update;
  
  $self->add_to_comments($comments) if ($comments);

  return $newfeat;
}

=head2 flatten_subfeats

Given a seqfeature, iterate through its subfeatures and add all their subs to
one big array. Mainly need this when CDSes are hidden behind mRNAs in genes.

=cut

sub flatten_subfeats
{
  my ($self, $feature) = @_;
  my @subs = $feature->get_SeqFeatures();
  push @subs, $_->get_SeqFeatures foreach (@subs);
  return @subs;
}

=head2 current_sequence

=cut

sub current_sequence
{
  my ($self, $feat) = @_;
  my ($fstart, $fend) = ($feat->start, $feat->end);
  my $seq = substr $self->{sequence}, $fstart - 1, $fend - $fstart + 1;
  $seq = $self->{GD}->complement($seq, 1) if ($feat->strand == -1); #like bperl
  return $seq;
}

=head2 make_cDNA

=cut

sub make_cDNA
{
  my ($self, $feature) = @_;
  my $cDNA = q{};
  if ($feature->primary_tag eq 'CDS')
  {
    return $self->current_sequence($feature);
  }
  elsif ($feature->primary_tag ne 'gene')
  {
    return $cDNA;
  }
  my @subs = $self->flatten_subfeats($feature);
  my @CDSes = grep {$_->primary_tag eq 'CDS'} @subs;
  @CDSes = sort {$b->start <=> $a->start} @CDSes if ($feature->strand == -1);
  @CDSes = sort {$a->start <=> $b->start} @CDSes if ($feature->strand ==  1);
  $cDNA .= $self->current_sequence($_) foreach (@CDSes);
  return $cDNA;
}

=head2 make_intergenic_features

=cut

sub make_intergenic_features
{
  my ($self) = @_;
  my $mask = $self->type_mask('gene');
  my @flist = ();
  #my %intergen = @{mask_filter($mask)};
  my @intergenics = @{$mask->find_deserts()};
  foreach my $range (@intergenics)
  {
    my $start = $range->start;
    my $end = $range->end;
    my $name = 'igenic_' . $start . q{-} . $end;
    my $newfeat = Bio::SeqFeature::Generic->new(
        -start        => $start,
        -end          => $end,
        -display_name => $name,
        -strand       => 0,
        -seq_id       => $self->{seq_id},
        -primary_tag  => 'intergenic_sequence',
        -source       => 'BIO'
    );
    push @flist, $newfeat;
  }
  return @flist;
}

=head2 iterate

  Creates a PROVISIONAL copy of the current chromosome.

=cut

sub iterate
{
  my ($self, @args) = @_;
  
  my $a = [qw(genver chrver tag version)];
  my ($gen, $chr, $tag, $ver) = $self->_rearrange($a, @args);
  
  if (defined $ver)
  {
    $gen = $ver =~ m{g}msix ? 1 : 0;
    $chr = $ver =~ m{c}msix ? 1 : 0;
  }
  else
  {
    $gen = $gen || 0;
    $chr = $chr || 1;
  }
  $tag = $tag || undef;
  my $oldpath = $self->path_to_GFF;
  
  my $newname = $self->{species} . q{_} . $self->{seq_id} . q{_};
  
  if ($gen)
  {
    my $newgenver = $self->{genome_version};
    $newgenver += $gen;
    $newname .= $newgenver;
  }
  else
  {
    $newname .= $self->{genome_version};
  }
  $newname .= q{_};
  if ($chr)
  {
    my $newchrver = $self->{chromosome_version};
    $newchrver += $chr;
    $newchrver = '0' . $newchrver while(length($newchrver) < 2);
    $newname .= $newchrver;
  }
  else
  {
    $newname .= $self->{chromosome_version};
  }
  if ($tag)
  {
    $newname .= $tag;
  }
  
  my $newchr = Bio::BioStudio::Chromosome->new(
    -name       => $newname,
    -repo       => $self->{repo},
    -gbrowse    => $self->{gbrowse}
  );
  my $newpath = $newchr->path_to_GFF;
  system "cp $oldpath $newpath" || die "$!";
  
  $newchr->provisional(1);
  $newchr->db(1);
  return $newchr;
}

=head2 today

=cut

sub today
{
  my ($self) = @_;
  return $time{'yymmdd'};
}

=head2 write_chromosome

=cut

sub write_chromosome
{
  my ($self) = @_;
  my @outdata = ();

  #Prepare the comments
  push @outdata, $self->print_comments();

  #Prepare the features
  push @outdata, $self->gff3();

  #Prepare the sequence
  push @outdata, "##FASTA\n";
  push @outdata, $self->FASTA();
  
  push @outdata, "\n";

  #Write
  my $path = $self->path_to_GFF();
  open (my $OUT, '>', $path) || $self->throw("can't open $path $OS_ERROR");
  print $OUT @outdata;
  close $OUT;

  if ($self->{gbrowse})
  {
    add_to_GBrowse($self);
  }
  $self->provisional(-1);
  $self->db(1);
  return $path;
}

=head2 allowable_codon_changes()

Given two codons (a from, and a to) and a GeneDesign codon table hashref, this
function generates every possible peptide pair that could contain the from codon
and checks to see if the peptide sequence can be maintained when the from codon
is replaced by the to codon.  This function is of particular use when codons are
being changed in genes that overlap one another.

=cut

sub allowable_codon_changes
{
  my ($self, $cod1, $cod2) = @_;
  my %result;
  my $GD = $self->GD();
  for my $orient (0..1)
  {
    $result{$orient} = {};
    for my $offset (0..2)
    {
      my %union = my %isect = ();
      my $seq1 = $offset != 0
        ?  'N' x $offset . $cod1 . 'N' x (3 - $offset)
        :  $cod1;
      my $seq2 = $offset != 0
        ?  'N' x $offset . $cod2 . 'N' x (3 - $offset)
        :  $cod2;
      my $qes1 = $orient  
        ?  $GD->complement($seq1, $orient)
        :  $seq1;
      my $qes2 = $orient  
        ?  $GD->complement($seq2, $orient)
        :  $seq2;
      my @set1 = $GD->ambiguous_translation(-sequence => $qes1);
      my @set2 = $GD->ambiguous_translation(-sequence => $qes2);
      foreach my $pep (@set1, @set2)
      {
        $union{$pep}++ && $isect{$pep}++;
      }
      $result{$orient}->{$_}++ foreach keys %isect;
    #  print "$offset and $orient:\n";
    #  print "\t$seq1 - $qes1: @set1\n\t$seq2 - $qes2: @set2\n";
    }
  }
  return \%result;
}

=head2 print_comments

=cut

sub print_comments
{
  my ($self) = @_;
  my @comments = ();
  push @comments, "##gff-version 3\n";
  $self->comments();
  my @precomments = @{$self->{comments}};
  foreach my $line (@precomments)
  {
    if (substr($line, 0, 1) ne q{#})
    {
      $line = q{# } . $line;
    }
    push @comments, $line;
  }
  push @comments, qq{#\n};
  return @comments;
}

=head2 genbank_feature

=cut

sub genbank_feature
{
  my ($self, @args) = @_;

  my ($feature, $skips, $acolors, $text, $seq) = $self->_rearrange([qw(
    feature
    skip_features
    ape_color
    comment
    sequence)], @args
  );
  die 'No feature provided genbank feature!' if (! $feature);
  $seq = $seq || $feature->seq->seq;
  $skips = $skips || {'chromosome' => 1};
  $acolors = $acolors || {};
  my $name = $feature->display_name;
  my ($fstart, $fend) = ($feature->start, $feature->end);
  $text = $text || "from $fstart to $fend in " . $self->name();
  my $comment = Bio::Annotation::Comment->new();
  $comment->text($text);
  my $seqobj = Bio::Seq->new( -id => $name, -seq => $seq);
  $seqobj->add_Annotation('comment', $comment);
  
  my @ofeats = $self->db->features(
    -seq_id     => $self->{seq_id},
    -start      => $fstart,
    -end        => $fend,
    -range_type => 'overlaps',
  );
  foreach my $ofeat (@ofeats)
  {
    my $kind = $ofeat->primary_tag();
    next if (exists $skips->{$kind});
    my $tag = {label => $ofeat->display_name};
    if (exists $acolors->{$kind})
    {
      $tag->{ApEinfo_fwdcolor} = $acolors->{$kind};
      $tag->{ApEinfo_revcolor} = $acolors->{$kind};
    }
    my $sfeat = Bio::SeqFeature::Generic->new
    (
      -primary => $ofeat->primary_tag,
      -start   => $ofeat->start - $fstart + 1,
      -end     => $ofeat->end - $fstart + 1,
      -tag     => $tag,
    );
    $seqobj->add_SeqFeature($sfeat);
  }
  return $seqobj;
}

=head2 FASTA

=cut

sub FASTA
{
  my ($self) = @_;
  my @FASTArr = ();
  $columns = 81;
  push @FASTArr, '>' . $self->{seq_id} . "\n";
  push @FASTArr, wrap(q{}, q{}, $self->sequence), "\n";
  return @FASTArr;
}

=head2 gff3

=cut

sub gff3
{
  my ($self) = @_;
  my @gfflines = ();
  my $seq_stream = $self->{database}->get_seq_stream()
    || $self->throw('failed to get_seq_stream');
  my @featarr;
  while (my $seq = $seq_stream->next_seq)
  {
    push @featarr, $seq;
  }
  @featarr = sort {$a->start <=> $b->start
              || (($b->end - $b->start) <=> ($a->end - $a->start))}
             @featarr;
  push @gfflines, $self->gff3_string($_) . "\n" foreach (@featarr);
  return @gfflines;
}

=head2 gff3_string

=cut

sub gff3_string
{
  my ($self, $feat) = @_;
  my ($seqid, $source, $type, $start, $end, $score, $strand, $phase) =
  ($feat->seq_id(), $feat->source_tag(), $feat->primary_tag(), $feat->start(),
   $feat->end(), $feat->score(), $feat->strand(), $feat->phase());
  $score = $score ? $score  : q{.};
  $phase = $phase && exists($PHASES{$phase}) ? $phase  : q{.};
  $strand = $strand == -1 ? q{-} : $strand == 1  ? q{+} : q{.};
  my $str = "$seqid\t$source\t$type\t$start\t$end\t$score\t$strand\t$phase\t";
  if ($feat->has_tag('load_id'))
  {
    $str .= 'ID=' . $feat->Tag_load_id . q{;};
    $str .= 'Name=' . $feat->Tag_load_id . q{;};
  }
  elsif ($feat->display_name)
  {
    $str .= 'ID=' . $feat->display_name . q{;};
    $str .= 'Name=' . $feat->display_name . q{;};
  }
  else
  {
    print q{};
  }
  if ($feat->has_tag('parent_id'))
  {
    $str .= 'Parent=' . $feat->Tag_parent_id . q{;};
  }
  my @alltags = sort{ $a cmp $b } $feat->get_all_tags();
  my $tagnum = scalar @alltags;
  my $tagtal = 0;
  foreach my $tag (@alltags)
  {
    $tagtal++;
    next if ($tag eq 'load_id' || $tag eq 'parent_id' || $tag eq 'display_name');
    my @vals = $feat->each_tag_value($tag);
    if (scalar(@vals))
    {
      my $attstr = join(q{,}, @vals);
      $attstr =~ s{\h+}{ }g;
      if ($tag eq 'Note')
      {
        $str .= "$tag=" . uri_escape($attstr, q{^\s^\d^\w^\-^\.^\_^\,^\(^\)});
      }
      else
      {
        $str .= "$tag=" . $attstr;
      }
      $str .= q{;} if ($tagtal != $tagnum);
    }
  }
  $str = substr $str, 0, (length $str) - 1 if (substr $str, -1, 1) eq q{;};
  return $str;
}

=head2 analyze_proteinCodingGenes

=cut

sub analyze_proteinCodingGenes
{
  my ($self, @args) = @_;

  my ($start, $stop)
    = $self->_rearrange([qw(
        start
        stop)], @args
  );

  require Bio::BioStudio::Analyze::ProteinCodingGenes;
  import Bio::BioStudio::Analyze::ProteinCodingGenes qw(:BS);
  return _analyze($self, $start, $stop);
}

=head2 analyze_RestrictionEnzymes

=cut

sub analyze_RestrictionEnzymes
{
  my ($self, @args) = @_;

  my ($start, $stop)
    = $self->_rearrange([qw(
        start
        stop)], @args
  );

  require Bio::BioStudio::Analyze::RestrictionEnzymes;
  import Bio::BioStudio::Analyze::RestrictionEnzymes qw(:BS);
  return _analyze($self, $start, $stop);
}

=head2 analyze_ArbitraryFeatures

=cut

sub analyze_ArbitraryFeatures
{
  my ($self, @args) = @_;

  my ($start, $stop, $typelist)
    = $self->_rearrange([qw(
        start
        stop
        typelist)], @args
  );

  require Bio::BioStudio::Analyze::ArbitraryFeatures;
  import Bio::BioStudio::Analyze::ArbitraryFeatures qw(:BS);
  return _analyze($self, $start, $stop, $typelist);
}

=head2 gbrowse_feature_link

=cut

sub gbrowse_feature_link
{
  my ($self, $feature) = @_;
  return link_to_feature($self, $feature);
}

=head2 gbrowse_chromosome_link

=cut

sub gbrowse_chromosome_link
{
  my ($self) = @_;
  return link_to_chromosome($self);
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
