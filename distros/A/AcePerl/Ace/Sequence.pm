package Ace::Sequence;
use strict;

use Carp;
use strict;
use Ace 1.50 qw(:DEFAULT rearrange);
use Ace::Sequence::FeatureList;
use Ace::Sequence::Feature;
use AutoLoader 'AUTOLOAD';
use vars '$VERSION';
my %CACHE;

$VERSION = '1.51';

use constant CACHE => 1;

use overload
  '""'       => 'asString',
  cmp        => 'cmp',
;

# synonym: stop = end
*stop = \&end;
*abs = \&absolute;
*source_seq = \&source;
*source_tag = \&subtype;
*primary_tag = \&type;

my %plusminus = (	 '+' => '-',
		 '-' => '+',
		 '.' => '.');

# internal keys
#    parent    => reference Sequence in "+" strand
#    p_offset  => our start in the parent
#    length    => our length
#    strand    => our strand (+ or -)
#    refseq    => reference Sequence for coordinate system

# object constructor
# usually called like this:
# $seq = Ace::Sequence->new($object);
# but can be called like this:
# $seq = Ace::Sequence->new(-db=>$db,-name=>$name);
# or
# $seq = Ace::Sequence->new(-seq    => $object,
#                           -offset => $offset,
#                           -length => $length,
#                           -ref    => $refseq
#                           );
# $refseq, if provided, will be used to establish the coordinate
# system.  Otherwise the first base pair will be set to 1.
sub new {
  my $pack = shift;
  my ($seq,$start,$end,$offset,$length,$refseq,$db) = 
    rearrange([
	       ['SEQ','SEQUENCE','SOURCE'],
	      'START',
	       ['END','STOP'],
	       ['OFFSET','OFF'],
	       ['LENGTH','LEN'],
	       'REFSEQ',
	       ['DATABASE','DB'],
	      ],@_);

  # Object must have a parent sequence and/or a reference
  # sequence.  In some cases, the parent sequence will be the
  # object itself.  The reference sequence is used to set up
  # the frame of reference for the coordinate system.

  # fetch the sequence object if we don't have it already
  croak "Please provide either a Sequence object or a database and name"
    unless ref($seq) || ($seq && $db);

  # convert start into offset
  $offset = $start - 1 if defined($start) and !defined($offset);

  # convert stop/end into length
  $length = ($end > $start) ? $end - $offset : $end - $offset - 2
    if defined($end) && !defined($length);

  # if just a string is passed, try to fetch a Sequence object
  my $obj = ref($seq) ? $seq : $db->fetch('Sequence'=>$seq);
  unless ($obj) {
    Ace->error("No Sequence named $obj found in database");
    return;
  }

  # get parent coordinates and length of this sequence
  # the parent is an Ace Sequence object in the "+" strand
  my ($parent,$p_offset,$p_length,$strand) = find_parent($obj);
  return unless $parent;

  # handle negative strands
  my $r_strand = $strand;
  my $r_offset = $p_offset;
  $offset ||= 0;
  $offset *= -1 if $strand < 0;

  # handle feature objects
  $offset += $obj->offset if $obj->can('smapped');

  # get source
  my $source = $obj->can('smapped') ? $obj->source : $obj;

  # store the object into our instance variables
  my $self = bless {
		    obj        => $source,
		    offset     => $offset,
		    length     => $length || $p_length,
		    parent     => $parent,
		    p_offset   => $p_offset,
		    refseq     => [$source,$r_offset,$r_strand],
		    strand     => $strand,
		    absolute   => 0,
		    automerge  => 1,
		   },$pack;

  # set the reference sequence
  eval { $self->refseq($refseq) } or return if defined $refseq;

  # wheww!
  return $self;
}

# return the "source" object that the user offset from
sub source {
  $_[0]->{obj};
}

# return the parent object
sub parent { $_[0]->{parent} }

# return the length
#sub length { $_[0]->{length} }
sub length { 
  my $self = shift;
  my ($start,$end) = ($self->start,$self->end);
  return $end - $start + ($end > $start ? 1 : -1);  # for stupid 1-based adjustments
}

sub reversed {  return shift->strand < 0; }

sub automerge {
  my $self = shift;
  my $d = $self->{automerge};
  $self->{automerge} = shift if @_;
  $d;
}

# return reference sequence
sub refseq {
  my $self = shift;
  my $prev = $self->{refseq};
  if (@_) {
    my $refseq = shift;
    my $arrayref;

  BLOCK: {
      last BLOCK unless defined ($refseq);

      if (ref($refseq) && ref($refseq) eq 'ARRAY') {
	$arrayref = $refseq;
	last BLOCK;
      }

      if (ref($refseq) && ($refseq->can('smapped'))) {
	croak "Reference sequence has no common ancestor with sequence"
	  unless $self->parent eq $refseq->parent;
	my ($a,$b,$c) = @{$refseq->{refseq}};
	#	$b += $refseq->offset;
	$b += $refseq->offset;
	$arrayref = [$refseq,$b,$refseq->strand];
	last BLOCK;
      }


      # look up reference sequence in database if we aren't given
      # database object already
      $refseq = $self->db->fetch('Sequence' => $refseq)
	unless $refseq->isa('Ace::Object');
      croak "Invalid reference sequence" unless $refseq;

      # find position of ref sequence in parent strand
      my ($r_parent,$r_offset,$r_length,$r_strand) = find_parent($refseq);
      croak "Reference sequence has no common ancestor with sequence" 
	unless $r_parent eq $self->{parent};

      # set to array reference containing this information
      $arrayref = [$refseq,$r_offset,$r_strand];
    }
    $self->{refseq} = $arrayref;
  }
  return unless $prev;
  return $self->parent if $self->absolute;
  return wantarray ? @{$prev} : $prev->[0];
}

# return strand
sub strand { return $_[0]->{strand} }

# return reference strand
sub r_strand {
  my $self = shift;
  return "+1" if $self->absolute;
  if (my ($ref,$r_offset,$r_strand) = $self->refseq) {
    return $r_strand;
  } else {
    return $self->{strand}
  }
}

sub offset { $_[0]->{offset} }
sub p_offset { $_[0]->{p_offset} }

sub smapped { 1; }
sub type    { 'Sequence' }
sub subtype { }

sub debug {
  my $self = shift;
  my $d = $self->{_debug};
  $self->{_debug} = shift if @_;
  $d;
}

# return the database this sequence is associated with
sub db {
  return Ace->name2db($_[0]->{db} ||= $_[0]->source->db);
}

sub start {
  my ($self,$abs) = @_;
  $abs = $self->absolute unless defined $abs;
  return $self->{p_offset} + $self->{offset} + 1 if $abs;

  if ($self->refseq) {
    my ($ref,$r_offset,$r_strand) = $self->refseq;
    return $r_strand < 0 ? 1 + $r_offset - ($self->{p_offset} + $self->{offset})
                         : 1 + $self->{p_offset} + $self->{offset} - $r_offset;
  }

  else {
    return $self->{offset} +1;
  }

}

sub end { 
  my ($self,$abs) = @_;
  my $start = $self->start($abs);
  my $f = $self->{length} > 0 ? 1 : -1;  # for stupid 1-based adjustments
  if ($abs && $self->refseq ne $self->parent) {
    my $r_strand = $self->r_strand;
    return $start - $self->{length} + $f 
      if $r_strand < 0 or $self->{strand} < 0 or $self->{length} < 0;
    return  $start + $self->{length} - $f
  }
  return  $start + $self->{length} - $f if $self->r_strand eq $self->{strand};
  return  $start - $self->{length} + $f;
}

# turn on absolute coordinates (relative to reference sequence)
sub absolute {
  my $self = shift;
  my $prev = $self->{absolute};
  $self->{absolute} = $_[0] if defined $_[0];
  return $prev;
}

# human readable string (for debugging)
sub asString {
  my $self = shift;
  if ($self->absolute) {
    return join '',$self->parent,'/',$self->start,',',$self->end;
  } elsif (my $ref = $self->refseq){
    my $label = $ref->isa('Ace::Sequence::Feature') ? $ref->info : "$ref";
    return join '',$label,'/',$self->start,',',$self->end;

  } else {
    join '',$self->source,'/',$self->start,',',$self->end;
  }
}

sub cmp {
  my ($self,$arg,$reversed) = @_;
  if (ref($arg) and $arg->isa('Ace::Sequence')) {
    my $cmp = $self->parent cmp $arg->parent 
      || $self->start <=> $arg->start;
    return $reversed ? -$cmp : $cmp;
  }
  my $name = $self->asString;
  return $reversed ? $arg cmp $name : $name cmp $arg;
}

# Return the DNA
sub dna {
  my $self = shift;
  return $self->{dna} if $self->{dna};
  my $raw = $self->_query('seqdna');
  $raw=~s/^>.*\n//m;
  $raw=~s/^\/\/.*//mg;
  $raw=~s/\n//g;
  $raw =~ s/\0+\Z//; # blasted nulls!
  my $effective_strand = $self->end >= $self->start ? '+1' : '-1';
  _complement(\$raw) if $self->r_strand ne $effective_strand;
  return $self->{dna} = $raw;
}

# return a gff file
sub gff {
  my $self = shift;
  my ($abs,$features) = rearrange([['ABS','ABSOLUTE'],'FEATURES'],@_);
  $abs = $self->absolute unless defined $abs;

  # can provide list of feature names, such as 'similarity', or 'all' to get 'em all
  #  !THIS IS BROKEN; IT SHOULD LOOK LIKE FEATURE()!
  my $opt = $self->_feature_filter($features);

  my $gff = $self->_gff($opt);
  warn $gff if $self->debug;

  $self->transformGFF(\$gff) unless $abs;
  return $gff;
}

# return a GFF object using the optional GFF.pm module
sub GFF {
  my $self = shift;
  my ($filter,$converter) = @_;  # anonymous subs
  croak "GFF module not installed" unless require GFF;
  require GFF::Filehandle;

  my @lines = grep !/^\/\//,split "\n",$self->gff(@_);
  local *IN;
  local ($^W) = 0;  # prevent complaint by GFF module
  tie *IN,'GFF::Filehandle',\@lines;
  my $gff = GFF::GeneFeatureSet->new;
  $gff->read(\*IN,$filter,$converter) if $gff;
  return $gff;
}

# Get the features table.  Can filter by type/subtype this way:
# features('similarity:EST','annotation:assembly_tag')
sub features {
  my $self = shift;
  my ($filter,$opt) = $self->_make_filter(@_);

  # get raw gff file
  my $gff = $self->gff(-features=>$opt);

  # turn it into a list of features
  my @features = $self->_make_features($gff,$filter);

  if ($self->automerge) {  # automatic merging
    # fetch out constructed transcripts and clones
    my %types = map {lc($_)=>1} (@$opt,@_);
    if ($types{'transcript'}) {
      push @features,$self->_make_transcripts(\@features);
      @features = grep {$_->type !~ /^(intron|exon)$/ } @features;
    }
    push @features,$self->_make_clones(\@features)      if $types{'clone'};
    if ($types{'similarity'}) {
      my @f = $self->_make_alignments(\@features);
      @features = grep {$_->type ne 'similarity'} @features;
      push @features,@f;
    }
  }

  return wantarray ? @features : \@features;
}

# A little bit more complex - assemble a list of "transcripts"
# consisting of Ace::Sequence::Transcript objects.  These objects
# contain a list of exons and introns.
sub transcripts {
  my $self    = shift;
  my $curated = shift;
  my $ef       = $curated ? "exon:curated"   : "exon";
  my $if       = $curated ? "intron:curated" : "intron";
  my $sf       = $curated ? "Sequence:curated" : "Sequence";
  my @features = $self->features($ef,$if,$sf);
  return unless @features;
  return $self->_make_transcripts(\@features);
}

sub _make_transcripts {
  my $self = shift;
  my $features = shift;

  require Ace::Sequence::Transcript;
  my %transcripts;

  for my $feature (@$features) {
    my $transcript = $feature->info;
    next unless $transcript;
    if ($feature->type =~ /^(exon|intron|cds)$/) {
      my $type = $1;
      push @{$transcripts{$transcript}{$type}},$feature;
    } elsif ($feature->type eq 'Sequence') {
      $transcripts{$transcript}{base} ||= $feature;
    }
  }

  # get rid of transcripts without exons
  foreach (keys %transcripts) {
    delete $transcripts{$_} unless exists $transcripts{$_}{exon}
  }

  # map the rest onto Ace::Sequence::Transcript objects
  return map {Ace::Sequence::Transcript->new($transcripts{$_})} keys %transcripts;
}

# Reassemble clones from clone left and right ends
sub clones {
  my $self = shift;
  my @clones = $self->features('Clone_left_end','Clone_right_end','Sequence');
  my %clones;
  return unless @clones;
  return $self->_make_clones(\@clones);
}

sub _make_clones {
  my $self = shift;
  my $features = shift;

  my (%clones,@canonical_clones);
  my $start_label = $self->strand < 0 ? 'end' : 'start';
  my $end_label   = $self->strand < 0 ? 'start' : 'end';
  for my $feature (@$features) {
    $clones{$feature->info}{$start_label} = $feature->start if $feature->type eq 'Clone_left_end';
    $clones{$feature->info}{$end_label}   = $feature->start if $feature->type eq 'Clone_right_end';

    if ($feature->type eq 'Sequence') {
      my $info = $feature->info;
      next if $info =~ /LINK|CHROMOSOME|\.\w+$/;
      if ($info->Genomic_canonical(0)) {
	push (@canonical_clones,$info->Clone) if $info->Clone;
      }
    }
  }

  foreach (@canonical_clones) {
    $clones{$_} ||= {};
  }

  my @features;
  my ($r,$r_offset,$r_strand) = $self->refseq;
  my $parent = $self->parent;
  my $abs = $self->absolute;
  if ($abs) {
    $r_offset  = 0;
    $r = $parent;
    $r_strand = '+1';
  }

  # BAD HACK ALERT.  WE DON'T KNOW WHERE THE LEFT END OF THE CLONE IS SO WE USE
  # THE MAGIC NUMBER -99_999_999 to mean "off left end" and
  # +99_999_999 to mean "off right end"
  for my $clone (keys %clones) {
    my $start = $clones{$clone}{start} || -99_999_999;
    my $end   = $clones{$clone}{end}   || +99_999_999;
    my $phony_gff = join "\t",($parent,'Clone','structural',$start,$end,'.','.','.',qq(Clone "$clone"));
    push @features,Ace::Sequence::Feature->new($parent,$r,$r_offset,$r_strand,$abs,$phony_gff);
  }
  return @features;
}

# Assemble a list of "GappedAlignment" objects. These objects
# contain a list of aligned segments.
sub alignments {
  my $self    = shift;
  my @subtypes = @_;
  my @types = map { "similarity:\^$_\$" } @subtypes;
  push @types,'similarity' unless @types;
  return $self->features(@types);
}

sub segments {
  my $self = shift;
  return;
}

sub _make_alignments {
  my $self = shift;
  my $features = shift;
  require Ace::Sequence::GappedAlignment;

  my %homol;

  for my $feature (@$features) {
    next unless $feature->type eq 'similarity';
    my $target = $feature->info;
    my $subtype = $feature->subtype;
    push @{$homol{$target,$subtype}},$feature;
  }

  # map onto Ace::Sequence::GappedAlignment objects
  return map {Ace::Sequence::GappedAlignment->new($homol{$_})} keys %homol;
}

# return list of features quickly
sub feature_list {
  my $self = shift;
  return $self->{'feature_list'} if $self->{'feature_list'};
  return unless my $raw = $self->_query('seqfeatures -version 2 -list');
  return $self->{'feature_list'} = Ace::Sequence::FeatureList->new($raw);
}

# transform a GFF file into the coordinate system of the sequence
sub transformGFF {
  my $self = shift;
  my $gff = shift;
  my $parent  = $self->parent;
  my $strand  = $self->{strand};
  my $source  = $self->source;
  my ($ref_source,$ref_offset,$ref_strand)  = $self->refseq;
  $ref_source ||= $source;
  $ref_strand ||= $strand;

  if ($ref_strand > 0) {
    my $o = defined($ref_offset) ? $ref_offset : ($self->p_offset + $self->offset);
    # find anything that looks like a numeric field and subtract offset from it
    $$gff =~ s/(?<!\")\s+(-?\d+)\s+(-?\d+)/"\t" . ($1 - $o) . "\t" . ($2 - $o)/eg;
    $$gff =~ s/^$parent/$source/mg;
    $$gff =~ s/\#\#sequence-region\s+\S+/##sequence-region $ref_source/m;
    $$gff =~ s/FMAP_FEATURES\s+"\S+"/FMAP_FEATURES "$ref_source"/m;
    return;
  } else {  # strand eq '-'
    my $o = defined($ref_offset) ? (2 + $ref_offset) : (2 + $self->p_offset - $self->offset);
    $$gff =~ s/(?<!\")\s+(-?\d+)\s+(-?\d+)\s+([.\d]+)\s+(\S)/join "\t",'',$o-$2,$o-$1,$3,$plusminus{$4}/eg;
    $$gff =~ s/(Target \"[^\"]+\" )(-?\d+) (-?\d+)/$1 $3 $2/g;
    $$gff =~ s/^$parent/$source/mg;
    $$gff =~ s/\#\#sequence-region\s+\S+\s+(-?\d+)\s+(-?\d+)/"##sequence-region $ref_source " . ($o - $2) . ' ' . ($o - $1) . ' (reversed)'/em;
    $$gff =~ s/FMAP_FEATURES\s+"\S+"\s+(-?\d+)\s+(-?\d+)/"FMAP_FEATURES \"$ref_source\" " . ($o - $2) . ' ' . ($o - $1) . ' (reversed)'/em;
  }

}

# return a name for the object
sub name {
  return shift->source_seq->name;
}

# for compatibility with Ace::Sequence::Feature
sub info {
  return shift->source_seq;
}

###################### internal functions #################
# not necessarily object-oriented!!

# return parent, parent offset and strand
sub find_parent {
  my $obj = shift;

  # first, if we are passed an Ace::Sequence, then we can inherit
  # these settings directly
  return (@{$obj}{qw(parent p_offset length)},$obj->r_strand)
    if $obj->isa('Ace::Sequence');

  # otherwise, if we are passed an Ace::Object, then we must
  # traverse upwards until we find a suitable parent
  return _traverse($obj) if $obj->isa('Ace::Object');

  # otherwise, we don't know what to do...
  croak "Source sequence not an Ace::Object or an Ace::Sequence";
}

sub _get_parent {
  my $obj = shift;
  # ** DANGER DANGER WILL ROBINSON! **
  # This is an experiment in caching parents to speed lookups.  Probably eats memory voraciously.
  return $CACHE{$obj} if CACHE && exists $CACHE{$obj};
  my $p = $obj->get(S_Parent=>2)|| $obj->get(Source=>1);
  return unless $p;
  return CACHE ? $CACHE{$obj} = $p->fetch 
               : $p->fetch;
}

sub _get_children {
  my $obj = shift;
  my @pieces = $obj->get(S_Child=>2);
  return @pieces if @pieces;
  return @pieces = $obj->get('Subsequence');
}

# get sequence, offset and strand of topmost container
sub _traverse {
  my $obj = shift;
  my ($offset,$length);

  # invoke seqget to find the top-level container for this sequence
  my ($tl,$tl_start,$tl_end) = _get_toplevel($obj);
  $tl_start ||= 0;
  $tl_end ||= 0;

  # make it an object
  $tl = ref($obj)->new(-name=>$tl,-class=>'Sequence',-db=>$obj->db);

  $offset += $tl_start - 1;  # offset to beginning of toplevel
  $length ||= abs($tl_end - $tl_start) + 1;
  my $strand = $tl_start < $tl_end ? +1 : -1;

  return ($tl,$offset,$strand < 0 ? ($length,'-1') : ($length,'+1') ) if $length;
}

sub _get_toplevel {
  my $obj = shift;
  my $class = $obj->class;
  my $name  = $obj->name;

  my $smap = $obj->db->raw_query("gif smap -from $class:$name");
  my ($parent,$pstart,$pstop,$tstart,$tstop,$map_type) = 
    $smap =~ /^SMAP\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.+)/;

  $parent ||= '';
  $parent =~ s/^Sequence://;  # remove this in next version of Acedb
  return ($parent,$pstart,$pstop);
}

# create subroutine that filters GFF files for certain feature types
sub _make_filter {
  my $self = shift;
  my $automerge = $self->automerge;

  # parse out the filter
  my %filter;
  foreach (@_) {
    my ($type,$filter) = split(':',$_,2);
    if ($automerge && lc($type) eq 'transcript') {
      @filter{'exon','intron','Sequence','cds'} = ([undef],[undef],[undef],[undef]);
    } elsif ($automerge && lc($type) eq 'clone') {
      @filter{'Clone_left_end','Clone_right_end','Sequence'} = ([undef],[undef],[undef]);
    } else {
      push @{$filter{$type}},$filter;
    }
  }

  # create pattern-match sub
  my $sub;
  my $promiscuous;  # indicates that there is a subtype without a type

  if (%filter) {
    my $s = "sub { my \@d = split(\"\\t\",\$_[0]);\n";
    for my $type (keys %filter) {
      my $expr;
      my $subtypes = $filter{$type};
      if ($type ne '') {
	for my $st (@$subtypes) {
	  $expr .= defined $st ? "return 1 if \$d[2]=~/$type/i && \$d[1]=~/$st/i;\n"
	                       : "return 1 if \$d[2]=~/$type/i;\n"
	}
      } else {  # no type, only subtypes
	$promiscuous++;
	for my $st (@$subtypes) {
	  next unless defined $st;
	  $expr .= "return 1 if \$d[1]=~/$st/i;\n";
	}
      }
      $s .= $expr;
    }
    $s .= "return;\n }";

    $sub = eval $s;
    croak $@ if $@;
  } else {
    $sub = sub { 1; }
  }
  return ($sub,$promiscuous ? [] : [keys %filter]);
}

# turn a GFF file and a filter into a list of Ace::Sequence::Feature objects
sub _make_features {
  my $self = shift;
  my ($gff,$filter) = @_;

  my ($r,$r_offset,$r_strand) = $self->refseq;
  my $parent = $self->parent;
  my $abs    = $self->absolute;
  if ($abs) {
    $r_offset  = 0;
    $r = $parent;
    $r_strand = '+1';
  }
  my @features = map {Ace::Sequence::Feature->new($parent,$r,$r_offset,$r_strand,$abs,$_)}
                 grep !m@^(?:\#|//)@ && $filter->($_),split("\n",$gff);
}


# low level GFF call, no changing absolute to relative coordinates
sub _gff {
  my $self = shift;
  my ($opt,$db) = @_;
  my $data = $self->_query("seqfeatures -version 2 $opt",$db);
  $data =~ s/\0+\Z//;
  return $data; #blasted nulls!
}

# shortcut for running a gif query
sub _query {
  my $self = shift;
  my $command = shift;
  my $db      = shift || $self->db;

  my $parent = $self->parent;
  my $start = $self->start(1);
  my $end   = $self->end(1);
  ($start,$end) = ($end,$start) if $start > $end;  #flippity floppity

  my $coord   = "-coords $start $end";

  # BAD BAD HACK ALERT - CHECKS THE QUERY THAT IS PASSED DOWN
  # ALSO MAKES THINGS INCOMPATIBLE WITH PRIOR 4.9 servers.
#  my $opt     = $command =~ /seqfeatures/ ? '-nodna' : '';
  my $opt = '-noclip';

  my $query = "gif seqget $parent $opt $coord ; $command";
  warn $query if $self->debug;

  return $db->raw_query("gif seqget $parent $opt $coord ; $command");
}

# utility function -- reverse complement
sub _complement {
  my $dna = shift;
  $$dna =~ tr/GATCgatc/CTAGctag/;
  $$dna = scalar reverse $$dna;
}

sub _feature_filter {
  my $self = shift;
  my $features = shift;
  return '' unless $features;
  my $opt = '';
  $opt = '+feature ' . join('|',@$features) if ref($features) eq 'ARRAY' && @$features;
  $opt = "+feature $features" unless ref $features;
  $opt;
}

1;

=head1 NAME

Ace::Sequence - Examine ACeDB Sequence Objects

=head1 SYNOPSIS

    # open database connection and get an Ace::Object sequence
    use Ace::Sequence;

    $db  = Ace->connect(-host => 'stein.cshl.org',-port => 200005);
    $obj = $db->fetch(Predicted_gene => 'ZK154.3');

    # Wrap it in an Ace::Sequence object 
    $seq = Ace::Sequence->new($obj);

    # Find all the exons
    @exons = $seq->features('exon');

    # Find all the exons predicted by various versions of "genefinder"
    @exons = $seq->features('exon:genefinder.*');

    # Iterate through the exons, printing their start, end and DNA
    for my $exon (@exons) {
      print join "\t",$exon->start,$exon->end,$exon->dna,"\n";
    }

    # Find the region 1000 kb upstream of the first exon
    $sub = Ace::Sequence->new(-seq=>$exons[0],
                              -offset=>-1000,-length=>1000);

    # Find all features in that area
    @features = $sub->features;

    # Print its DNA
    print $sub->dna;

    # Create a new Sequence object from the first 500 kb of chromosome 1
    $seq = Ace::Sequence->new(-name=>'CHROMOSOME_I',-db=>$db,
			      -offset=>0,-length=>500_000);

    # Get the GFF dump as a text string
    $gff = $seq->gff;

    # Limit dump to Predicted_genes
    $gff_genes = $seq->gff(-features=>'Predicted_gene');

    # Return a GFF object (using optional GFF.pm module from Sanger)
    $gff_obj = $seq->GFF;

=head1 DESCRIPTION

I<Ace::Sequence>, and its allied classes L<Ace::Sequence::Feature> and
L<Ace::Sequence::FeatureList>, provide a convenient interface to the
ACeDB Sequence classes and the GFF sequence feature file format.

Using this class, you can define a region of the genome by using a
landmark (sequenced clone, link, superlink, predicted gene), an offset
from that landmark, and a distance.  Offsets and distances can be
positive or negative.  This will return an I<Ace::Sequence> object.
Once a region is defined, you may retrieve its DNA sequence, or query
the database for any features that may be contained within this
region.  Features can be returned as objects (using the
I<Ace::Sequence::Feature> class), as GFF text-only dumps, or in the
form of the GFF class defined by the Sanger Centre's GFF.pm module.

This class builds on top of L<Ace> and L<Ace::Object>.  Please see
their manual pages before consulting this one.

=head1 Creating New Ace::Sequence Objects, the new() Method

 $seq = Ace::Sequence->new($object);

 $seq = Ace::Sequence->new(-source  => $object,
                           -offset  => $offset,
                           -length  => $length,
			   -refseq  => $reference_sequence);

 $seq = Ace::Sequence->new(-name    => $name,
			   -db      => $db,
                           -offset  => $offset,
                           -length  => $length,
			   -refseq  => $reference_sequence);

In order to create an I<Ace::Sequence> you will need an active I<Ace>
database accessor.  Sequence regions are defined using a "source"
sequence, an offset, and a length.  Optionally, you may also provide a
"reference sequence" to establish the coordinate system for all
inquiries.  Sequences may be generated from existing I<Ace::Object>
sequence objects, from other I<Ace::Sequence> and
I<Ace::Sequence::Feature> objects, or from a sequence name and a
database handle.

The class method named new() is the interface to these facilities.  In
its simplest, one-argument form, you provide new() with a
previously-created I<Ace::Object> that points to Sequence or
sequence-like object (the meaning of "sequence-like" is explained in
more detail below.)  The new() method will return an I<Ace::Sequence>
object extending from the beginning of the object through to its
natural end.

In the named-parameter form of new(), the following arguments are
recognized:

=over 4

=item -source

The sequence source.  This must be an I<Ace::Object> of the "Sequence" 
class, or be a sequence-like object containing the SMap tag (see
below).

=item -offset

An offset from the beginning of the source sequence.  The retrieved
I<Ace::Sequence> will begin at this position.  The offset can be any
positive or negative integer.  Offets are B<0-based>.

=item -length

The length of the sequence to return.  Either a positive or negative
integer can be specified.  If a negative length is given, the returned 
sequence will be complemented relative to the source sequence.

=item -refseq

The sequence to use to establish the coordinate system for the
returned sequence.  Normally the source sequence is used to establish
the coordinate system, but this can be used to override that choice.
You can provide either an I<Ace::Object> or just a sequence name for
this argument.  The source and reference sequences must share a common
ancestor, but do not have to be directly related.  An attempt to use a
disjunct reference sequence, such as one on a different chromosome,
will fail.

=item -name

As an alternative to using an I<Ace::Object> with the B<-source>
argument, you may specify a source sequence using B<-name> and B<-db>.
The I<Ace::Sequence> module will use the provided database accessor to
fetch a Sequence object with the specified name. new() will return
undef is no Sequence by this name is known.

=item -db

This argument is required if the source sequence is specified by name
rather than by object reference.

=back

If new() is successful, it will create an I<Ace::Sequence> object and
return it.  Otherwise it will return undef and return a descriptive
message in Ace->error().  Certain programming errors, such as a
failure to provide required arguments, cause a fatal error.

=head2 Reference Sequences and the Coordinate System

When retrieving information from an I<Ace::Sequence>, the coordinate
system is based on the sequence segment selected at object creation
time.  That is, the "+1" strand is the natural direction of the
I<Ace::Sequence> object, and base pair 1 is its first base pair.  This
behavior can be overridden by providing a reference sequence to the
new() method, in which case the orientation and position of the
reference sequence establishes the coordinate system for the object.

In addition to the reference sequence, there are two other sequences
used by I<Ace::Sequence> for internal bookeeping.  The "source"
sequence corresponds to the smallest ACeDB sequence object that
completely encloses the selected sequence segment.  The "parent"
sequence is the smallest ACeDB sequence object that contains the
"source".  The parent is used to derive the length and orientation of
source sequences that are not directly associated with DNA objects.

In many cases, the source sequence will be identical to the sequence
initially passed to the new() method.  However, there are exceptions
to this rule.  One common exception occurs when the offset and/or
length cross the boundaries of the passed-in sequence.  In this case,
the ACeDB database is searched for the smallest sequence that contains 
both endpoints of the I<Ace::Sequence> object.

The other common exception occurs in Ace 4.8, where there is support
for "sequence-like" objects that contain the C<SMap> ("Sequence Map")
tag.  The C<SMap> tag provides genomic location information for
arbitrary object -- not just those descended from the Sequence class.
This allows ACeDB to perform genome map operations on objects that are
not directly related to sequences, such as genetic loci that have been
interpolated onto the physical map.  When an C<SMap>-containing object
is passed to the I<Ace::Sequence> new() method, the module will again
choose the smallest ACeDB Sequence object that contains both
end-points of the desired region.

If an I<Ace::Sequence> object is used to create a new I<Ace::Sequence>
object, then the original object's source is inherited.

=head1 Object Methods

Once an I<Ace::Sequence> object is created, you can query it using the
following methods:

=head2 asString()

  $name = $seq->asString;

Returns a human-readable identifier for the sequence in the form
I<Source/start-end>, where "Source" is the name of the source
sequence, and "start" and "end" are the endpoints of the sequence
relative to the source (using 1-based indexing).  This method is
called automatically when the I<Ace::Sequence> is used in a string
context.

=head2 source_seq()

  $source = $seq->source_seq;

Return the source of the I<Ace::Sequence>.

=head2 parent_seq()

  $parent = $seq->parent_seq;

Return the immediate ancestor of the sequence.  The parent of the
top-most sequence (such as the CHROMOSOME link) is itself.  This
method is used internally to ascertain the length of source sequences
which are not associated with a DNA object.

NOTE: this procedure is a trifle funky and cannot reliably be used to
traverse upwards to the top-most sequence.  The reason for this is
that it will return an I<Ace::Sequence> in some cases, and an
I<Ace::Object> in others.  Use get_parent() to traverse upwards
through a uniform series of I<Ace::Sequence> objects upwards.

=head2 refseq([$seq])

  $refseq = $seq->refseq;

Returns the reference sequence, if one is defined.

  $seq->refseq($new_ref);

Set the reference sequence. The reference sequence must share the same
ancestor with $seq.

=head2 start()

  $start = $seq->start;

Start of this sequence, relative to the source sequence, using 1-based
indexing.

=head2 end()

  $end = $seq->end;

End of this sequence, relative to the source sequence, using 1-based
indexing.

=head2 offset()

  $offset = $seq->offset;

Offset of the beginning of this sequence relative to the source
sequence, using 0-based indexing.  The offset may be negative if the
beginning of the sequence is to the left of the beginning of the
source sequence.

=head2 length()

  $length = $seq->length;

The length of this sequence, in base pairs.  The length may be
negative if the sequence's orientation is reversed relative to the
source sequence.  Use abslength() to obtain the absolute value of
the sequence length.

=head2 abslength()

  $length = $seq->abslength;

Return the absolute value of the length of the sequence.

=head2 strand()

  $strand = $seq->strand;

Returns +1 for a sequence oriented in the natural direction of the
genomic reference sequence, or -1 otherwise.

=head2 reversed()

Returns true if the segment is reversed relative to the canonical
genomic direction.  This is the same as $seq->strand < 0.

=head2 dna()

  $dna = $seq->dna;

Return the DNA corresponding to this sequence.  If the sequence length
is negative, the reverse complement of the appropriate segment will be
returned.

ACeDB allows Sequences to exist without an associated DNA object
(which typically happens during intermediate stages of a sequencing
project.  In such a case, the returned sequence will contain the
correct number of "-" characters.

=head2 name()

  $name = $seq->name;

Return the name of the source sequence as a string.

=head2 get_parent()

  $parent = $seq->parent;

Return the immediate ancestor of this I<Ace::Sequence> (i.e., the
sequence that contains this one).  The return value is a new
I<Ace::Sequence> or undef, if no parent sequence exists.

=head2 get_children()

  @children = $seq->get_children();

Returns all subsequences that exist as independent objects in the
ACeDB database.  What exactly is returned is dependent on the data
model.  In older ACeDB databases, the only subsequences are those
under the catchall Subsequence tag.  In newer ACeDB databases, the
objects returned correspond to objects to the right of the S_Child
subtag using a tag[2] syntax, and may include Predicted_genes,
Sequences, Links, or other objects.  The return value is a list of
I<Ace::Sequence> objects.

=head2 features()

  @features = $seq->features;
  @features = $seq->features('exon','intron','Predicted_gene');
  @features = $seq->features('exon:GeneFinder','Predicted_gene:hand.*');

features() returns an array of I<Sequence::Feature> objects.  If
called without arguments, features() returns all features that cross
the sequence region.  You may also provide a filter list to select a
set of features by type and subtype.  The format of the filter list
is:

  type:subtype

Where I<type> is the class of the feature (the "feature" field of the
GFF format), and I<subtype> is a description of how the feature was
derived (the "source" field of the GFF format).  Either of these
fields can be absent, and either can be a regular expression.  More
advanced filtering is not supported, but is provided by the Sanger
Centre's GFF module.

The order of the features in the returned list is not specified.  To
obtain features sorted by position, use this idiom:

  @features = sort { $a->start <=> $b->start } $seq->features;

=head2 feature_list()

  my $list = $seq->feature_list();

This method returns a summary list of the features that cross the
sequence in the form of a L<Ace::Feature::List> object.  From the
L<Ace::Feature::List> object you can obtain the list of feature names
and the number of each type.  The feature list is obtained from the
ACeDB server with a single short transaction, and therefore has much
less overhead than features().

See L<Ace::Feature::List> for more details.

=head2 transcripts()

This returns a list of Ace::Sequence::Transcript objects, which are
specializations of Ace::Sequence::Feature.  See L<Ace::Sequence::Transcript>
for details.

=head2 clones()

This returns a list of Ace::Sequence::Feature objects containing
reconstructed clones.  This is a nasty hack, because ACEDB currently
records clone ends, but not the clones themselves, meaning that we
will not always know both ends of the clone.  In this case the missing
end has a synthetic position of -99,999,999 or +99,999,999.  Sorry.

=head2 gff()

  $gff = $seq->gff();
  $gff = $seq->gff(-abs      => 1,
                   -features => ['exon','intron:GeneFinder']);

This method returns a GFF file as a scalar.  The following arguments
are optional:

=over 4

=item -abs

Ordinarily the feature entries in the GFF file will be returned in
coordinates relative to the start of the I<Ace::Sequence> object.
Position 1 will be the start of the sequence object, and the "+"
strand will be the sequence object's natural orientation.  However if
a true value is provided to B<-abs>, the coordinate system used will
be relative to the start of the source sequence, i.e. the native ACeDB
Sequence object (usually a cosmid sequence or a link).  

If a reference sequence was provided when the I<Ace::Sequence> was
created, it will be used by default to set the coordinate system.
Relative coordinates can be reenabled by providing a false value to
B<-abs>.  

Ordinarily the coordinate system manipulations automatically "do what
you want" and you will not need to adjust them.  See also the abs()
method described below.

=item -features

The B<-features> argument filters the features according to a list of
types and subtypes.  The format is identical to the one described for
the features() method.  A single filter may be provided as a scalar
string.  Multiple filters may be passed as an array reference.

=back

See also the GFF() method described next.

=head2 GFF()

  $gff_object = $seq->gff;
  $gff_object = $seq->gff(-abs      => 1,
                   -features => ['exon','intron:GeneFinder']);

The GFF() method takes the same arguments as gff() described above,
but it returns a I<GFF::GeneFeatureSet> object from the GFF.pm
module.  If the GFF module is not installed, this method will generate 
a fatal error.

=head2 absolute()

 $abs = $seq->absolute;
 $abs = $seq->absolute(1);

This method controls whether the coordinates of features are returned
in absolute or relative coordinates.  "Absolute" coordinates are
relative to the underlying source or reference sequence.  "Relative"
coordinates are relative to the I<Ace::Sequence> object.  By default,
coordinates are relative unless new() was provided with a reference
sequence.  This default can be examined and changed using absolute().

=head2 automerge()

  $merge = $seq->automerge;
  $seq->automerge(0);

This method controls whether groups of features will automatically be
merged together by the features() call.  If true (the default), then
the left and right end of clones will be merged into "clone" features,
introns, exons and CDS entries will be merged into
Ace::Sequence::Transcript objects, and similarity entries will be
merged into Ace::Sequence::GappedAlignment objects.

=head2 db()

  $db = $seq->db;

Returns the L<Ace> database accessor associated with this sequence.

=head1 SEE ALSO

L<Ace>, L<Ace::Object>, L<Ace::Sequence::Feature>,
L<Ace::Sequence::FeatureList>, L<GFF>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Many thanks to David Block <dblock@gene.pbi.nrc.ca> for finding and
fixing the nasty off-by-one errors.

Copyright (c) 1999, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

__END__
