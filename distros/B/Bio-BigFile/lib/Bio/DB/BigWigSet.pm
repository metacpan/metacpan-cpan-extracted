package Bio::DB::BigWigSet;
# $Id$

# make a directory of BigWig files look like one big database

=head1 SYNOPSIS

   use Bio::DB::BigSet;
   use Bio::DB::BigWig 'binMean';

   my $wigset = Bio::DB::BigWigSet->new(-dir          => $dir,
                                        -feature_type => 'summary'
    );

   my $iterator = $wigset->get_seq_stream(-seq_id => 'I',
                                          -start  => 100,
                                          -end    => 1000,
                                          -type   => 'binding_site');
   while (my $summary = $iterator->next_seq) {
      my $arry = $summary->statistical_summary(100);
      print binMean($_),"\n" foreach @$arry;
   }

=head1 DESCRIPTION

This module provides a convenient way of adding metadata to a
directory of BigWig files in such a way that it appears that all the
BigWig files form a single database of sequence features. The
directory should be layed out so that it contains one or more BigWig
files and a metadata index file that adds names and attributes to the files.

The metdata file must be named beginning "meta". Anything following
the initial ``meta'' is fine. Its format is described below. The
metadata file is optional if the BigWig files end with the extension
".bw", in which case they will be added to the collection
automatically

The metadata file is plain text and should be laid out like this:

 [file1.bw]
 display_name = foobar
 type         = some_type1
 method       = my_method1
 source       = my_source1
 some_attribute    = value1
 another_attribute = value2

 [file2.bw]
 display_name = barfoo
 type         = some_type2
 method       = my_method2
 source       = my_source2
 some_attribute    = value3
 another_attribute = value4

 ...

Each stanza begins with the name of one of the bigwig files in the
directory, enclosed by brackets. Following this are a series of
"attribute = value pairs" which will be applied to features returned
from the corresponding BigWig file. The following attributes have
predefined meanings:

  Attribute        Value
  ---------        -----

  display_name     The value returned by each feature's display_name()
                    method.

  name             An alias for display_name.

  type             The value returned by each feature's type() method
                     (this method will return "$method:$source" if
                     type is not defined).

  primary_tag      The value returned by each feature's primary_tag()
                    and method () methods.

  method           An alias for primary_tag.

  source           The value returned by each feature's source() and
                     source_tag() methods.

Any other attributes are stored in the feature and can be retrieved
with the get_all_tags(), get_tag_values() and attributes()
methods. See L<Bio::SeqFeatureI> and L<Bio::SeqFeature::Lite>.

Any bigwig files that are present in the directory but not mentioned
in the metdata file will be assigned a display_name equal to the name
of the file, minus the .bw extension.

The point of this is to allow you to make a set of BigWig files act
like a uniform database, and to assign distinguishing types, names and
attributes to the features returned to the file.

For example, if one of the WigFiles is assigned a type of
"polII_binding_site:early_embryo" using a stanza like this:

 [random_wigfile.bw]
 type = polII_binding_site:early_embryo

You can fetch it from the BigWigSet using this call:

  my @summaries = $bigwigset->features(-seq_id=>'chr1',
                                       -start =>1,-end=>50_000_000,
                                       -type  => 'polII_binding_site:early_embryo');

See L<Bio::DB::SeqFeature::Store> for more examples of this API.

The directory of BigWigs may be on a remote HTTP or FTP server; simply
provide the URL for the remote directory. This will only work if the
remote server allows directory listings.

=head1 METHODS

Most methods are inherited from Bio::DB::BigWig (see
L<Bio::DB::BigWig>). This section describes the differences.

=head2 Class Methods

=over 4

=item $bws = Bio::DB::BigWigSet->new('/path/to/directory')

=item $bws = Bio::DB::BigWigSet->new(-dir => '/path/to/directory', 
                                     -feature_type => $type,
				     -fasta        => $fasta_file_or_obj)

=item $bws = Bio::DB::BigWigSet->new(-index => '/path/to/metadata.txt') 

This method creates a new Bio::DB::BigWigSet. If just one argument is
provided, it is used as the path to the directory where the BigWig
files are stored. In the named-argument form, the following arguments
are recognized:

  Argument          Description
  --------          -----------

  -dir              Path to the directory containing wigfiles and
                     metadata.

  -fasta            A Fasta file path or a sequence accessor to
                     pass to each of the BigWig files when they are
                     open. See the Bio::DB::BigWig manual page for
                     more information.

  -feature_type     The type of feature to retrieve from the BigWig
                     files. One of "summary", "bin", "region" or
		     "interval." See the Bio::DB::BigWig manual
                     page for more information. If not specified
                     "summary" is assumed.

  -index            Provide a path to the metadata file directly.

You may call new() without any arguments, in which case an empty
BigWig set is created. You may add BigWig files to the set
individually using add_bigwig().

=item $count = Bio::DB::BigWig->index_dir($path/to/dir)

Given a directory, this class method creates a skeletal metadata file
named "metadata.index" from any bigwig fies it finds in the
directory. You should customize this file as needed. If the method is
called on a directory that already contains one or more metadata files
then it will leave intact any stanzas that correspond to existing SAM
tiles, add new stanzas for bigwigs that are not mentioned in the
index, and remove stanzas that no longer correspond to a WIG file.

Also see the index_bigwigset.pl script that comes with the
distribution.

=back

=cut

use strict;
use Bio::DB::BigWig;
use IO::Dir;
use IO::File;
use File::Spec;
use File::Basename 'basename','dirname';
use Carp 'croak';

sub new {
    my $class = shift;
    my %opts = $_[0] =~ /^-/ ? @_ : (-dir=>shift);
    my $self  = $class->_new();
    $self->fasta_path($opts{-fasta})           if $opts{-fasta};
    $self->readdir($opts{-dir})                if $opts{-dir};
    $self->read_index($opts{-index})           if $opts{-index};
    $self->feature_type($opts{-feature_type})  if $opts{-feature_type};
    $self;
}

sub index_dir {
    my $class = shift;
    my $dir   = shift or croak "Usage: Bio::DB::BigWigSet->index_dir(\$path_to_dir)";
    my (@indices,%wigfiles);

    my $d = IO::Dir->new($dir);
    while (my $node = $d->read) {
	next if $node =~ /^[.#]/; # dot files and temp files
	next if $node =~ /~$/;    # autosave files
	next unless -f File::Spec->catfile($dir,$node);
	if ($node =~ /^meta/) {
	    push @indices,$node;
	} elsif ($node =~ /\.bw/i) {
	    $wigfiles{$node}++;
	}
    }
    undef $d;

    if (@indices > 1) {
	warn "More than one index file. Will consolidate them.\n";
    }

    # read indices into a data structure
    my (%metadata,$current,@order);
    for my $i (@indices) {
	open my $f,File::Spec->catfile($dir,$i) or die "$i: $!";
	while (<$f>) {
	    next unless /\S/;
	    if (/^\[([^\]]+)\]/) {  # beginning of a configuration section
		$current = $1;
		push @order,$current;
	    }
	    elsif ($current) {
		$metadata{$current} .= $_
	    }
	}
    }

    unlink (map {File::Spec->catfile($dir,$_)} @indices);

    # write out updated file
    open my $f,">",File::Spec->catfile($dir,'metadata.index');
    for my $path (@order) {
	next unless $wigfiles{$path};  # delete dangling metadata
	print $f "[$path]\n";
	print $f $metadata{$path},"\n";
    }
    # add an empty stanza for each new files
    for my $wigfile (sort grep {!$metadata{$_}} keys %wigfiles) {
	(my $name = $wigfile) =~ s/\.\w+$//;
	print $f "[$wigfile]\n";
	print $f "display_name = $name\n";
	print $f "\n";
    }
    return scalar keys %wigfiles;
}

sub _new {
    my $class = shift;
    return bless {
	bigwigs     => {},   # path (id) => $bigwig object
	attributes  => {},   # path (id) => hash of attributes
    },ref $class || $class;
}

=head2 Accessors

These are accessors for BigWigSet properties.

=over 4

=item $fasta = $bws->fasta_path([$new_path])

Get or set the FASTA file path or sequence accessor.

=cut

sub fasta_path {
    my $self = shift;
    my $d    = $self->{fasta_path};
    $self->{fasta_path} = shift if @_;
    return $d;
}

=item $type = $bws->feature_type([$new_type])

Get or set the underlying type of object that the BigWig set will
return. One of "summary", "bin", "region" or "interval". See
L<Bio::DB::BigWig>.

=cut

sub feature_type {
    my $self = shift;
    my $d    = $self->{feature_type};
    $self->{feature_type} = shift if @_;
    return $d || 'summary';
}
 
=item $accessor = $bws->dna_accessor()

Returns the object that will be used to access DNA sequences, if a
-fasta argument was providd at create time.

=back

=cut

sub dna_accessor {
    my $self = shift;
    my $fasta_path = $self->fasta_path or return;
    return $self->{fasta} ||= Bio::DB::BigWig->new_dna_accessor($fasta_path);
}

=head2 Fetching Features

These are methods used to query the collection of BigWig files managed
by the BigWigSet for various kinds of features. They are similar to
the like-named methods in Bio::DB::BigWig.

=over 4

=item B<@features = $bigwig-E<gt>features(@args)>

This method is the workhorse for retrieving various types of intervals
and summary statistics from the BigWig database. It takes a series of
named arguments in the format (-argument1 => value1, -argument2 =>
value2, ...) and returns a list of zero or more BioPerl
Bio::SeqFeatureI objects.

The following arguments are recognized:

   Argument     Description                         Default
   --------     -----------                         -------

   -seq_id      Chromosome or contig name defining  All chromosomes/contigs.
                the range of interest.

   -start       Start of the range of interest.     1

   -end         End of the range of interest        Chromosome/contig end

   -type        Retrieve only features with the     none
                  matching type(s). The argument
                  can be a scalar or an arrayref. 

   -name        Retrieve only features with the     none
                  indiccated name.

   -attributes  Retrieve only features that have    none
                  matching attributes. The argument
                  is a hashref of tag value
		  attributes, in which the key is
		  the tag and the value is either
		  a simple value, or an array 
		  reference of values.

   -iterator    Boolean, which if true, returns     undef (false)
                an iterator across the list rather
                than the list itself.

The features() method is similar to that of Bio::DB::BigWig, but some
of the arguments have slightly different meanings.

B<-type> is a selector that filters the features returned by the type
specified in their metadata. You can provide a single value, or an
arrayref of several types to filter by. Only BigWig files whose type,
as set in the metadata index, match one or more of the provided types
will be consulted for features. The behavior of the features --
whether they represent individal wiggle intervals, summaries, or bins
is set by the B<-feature_type> argument passed to the BigWigSet->new()
method.

The B<-attributes> argument will filter BigWig data by any combination
of metadata tag. Here's how it works:

  @features = $bws->features(-seq_id      => 'chr1',
                             -attributes  => {method    => ['ChIP-seq','ChIP-chip'],
                                              validated => 1});

This will query BigWig files from the set whose metadata indicates a
method of either "ChIP-seq" or "ChIP-chip" and which have a
"validated" attribute of 1. GLOB matches, such as "ChIP*" are
also accepted.

The features returned from this call will return values from
display_name(), primary_tag(), source_tag(), and get_tag_values() that
correspond to the information specified in the metadata index. For
example, the features returned from the example query above, will
return either "ChIP-seq" or "ChIP-chip" when you call:

     $method = $feature->get_tag_values('method');

=cut

sub features {
    my $self    = shift;
    my @args    = @_;
    my %options = $args[0]=~/^-/ ? @args : (-type=>$_[0]);

    my $iterator = $self->get_seq_stream(@args);
    return $iterator if $options{-iterator};
    
    my @result;
    while (my $f = $iterator->next_seq) {
	push @result,$f;
    }

    return @result;
}

=item $iterator = $bws->get_seq_stream(@args)

This call takes the same arguments as features() but returns a
memory-efficient iterator. Call the iterator's next_seq() method
repeatedly to fetch the features one at a time.

=cut

sub get_seq_stream {
    my $self    = shift;
    my %options;

    if (@_ && $_[0] !~ /^-/) {
	%options = (-type => $_[0]);
    } else {
	%options = @_;
    }
    $options{-type} ||= $options{-types};

    my @ids = keys %{$self->{bigwigs}};
    @ids    = $self->_filter_ids_by_type($options{-type},           \@ids) if $options{-type};
    @ids    = $self->_filter_ids_by_attribute($options{-attributes},\@ids) if $options{-attributes};
    @ids    = $self->_filter_ids_by_name($options{-name},           \@ids) if $options{-name};

    my %search_opts  = (-type => $self->feature_type);
    $search_opts{$_} = $options{$_} foreach qw(-seq_id -start -end);

    return Bio::DB::BigWigSet::Iterator->new($self,\@ids,\%search_opts);
}

=item @features = $bws->get_features_by_location($seq_id,$start,$end)

Same as in Bio::DB::BigWig, except that features from all members of
the set are returned.

=cut

sub get_features_by_location {
    my $self = shift;
    my ($seqid,$start,$end) = @_;
    return $self->features(-seq_id=> $seqid,
			   -start => $start,
			   -end   => $end);
}

=item @features = $bws->get_features_by_name($name)

=item @features = $bws->get_feature_by_name($name)

=item @features = $bws->get_features_by_alias($name)

Only features from BigWig files whose display_name attribute matches
$name will be returned. These three methods all do the same thing.

=cut

sub get_features_by_name {
    my $self = shift;
    my $name = shift;
    return $self->features(-name  => $name);
}

sub get_feature_by_name  { shift->get_features_by_name(@_) }
sub get_features_by_alias { shift->get_features_by_name(@_) }

=item @features = $bws->get_features_by_attribute($attributes)

Only features matching the attributes hash will be returned. See
features() for a description of how this filter works.

=cut

sub get_features_by_attribute { 
    my $self = shift;
    my $att  = shift;
    $self->features(-attributes=>$att);
}

=item $feature = $bws->get_features_by_id($id)

Given an ID returned by calling a feature's primary_id() method this
returns the same feature. If used between sessions, it only works as
expected if the BigWigSet is created in the same way each time.

=back

=cut

# kind of a cheat, but it mostly works
sub get_feature_by_id {
    my $self = shift;
    my $id   = shift;
    my @pieces = split ':',$id;
    @pieces >= 4 or return;

    my ($dbid,$fid) = ($pieces[0],join(':',@pieces[1..3],$self->feature_type));
    my $db = $self->get_bigwig($dbid) or return;
    my $f = $db->get_feature_by_id($fid);
    my $type = join(':',@pieces[4..$#pieces]);
    $f->set_attributes({dbid=>$dbid,type=>$type});
    $f;
}

sub _filter_ids_by_type {
    my $self = shift;
    my ($type,$ids) = @_;

    my %ids;
    my @types    = ref $type ? @$type : $type;

    my %ok_types = map {lc $_=>1} @types;
  ID:
    for my $id (@$ids) {
	my $att           = $self->{attributes}{$id};
	my $type_base     = lc ($att->{type} || $att->{method} || $att->{primary_tag} || $self->feature_type);
	{
	    no warnings;
	    my $type_extended = lc "$att->{method}:$att->{source}" if $att->{method};
	    next ID unless $ok_types{$type_base} || $ok_types{$type_extended};
	}
	$ids{$id}++;
    }

    return keys %ids;
}

sub _filter_ids_by_name {
    my $self = shift;
    my ($name,$ids) = @_;
    my $atts = $self->{attributes};
    my @result = grep {($atts->{$_}{display_name} || $atts->{$_}{name}) eq $name} @$ids;
    return @result;
}

sub _filter_ids_by_attribute {
    my $self = shift;
    my ($attributes,$ids) = @_;

    my @result;
    my %ids = map {$_=>1} @$ids;
    for my $att_name (keys %$attributes) {
	my @search_terms = ref($attributes->{$att_name}) && ref($attributes->{$att_name}) eq 'ARRAY'
	                   ? @{$attributes->{$att_name}} : $attributes->{$att_name};
	for my $id (keys %ids) {
	    my $ok;
	    
	    for my $v (@search_terms) {
		my $att = $self->{attributes}{$id} or next;
		my $val = $att->{lc $att_name}     or next;
		if (my $regexp = $self->glob_match($v)) {
		    $ok++ if $val =~ /$regexp/i;
		} else {
		    $ok++ if lc $val eq lc $v;
		}
	    }
	    delete $ids{$id} unless $ok;
	}
    }
    return keys %ids;
}

sub glob_match {
  my $self = shift;
  my $term = shift;
  return unless $term =~ /(?:^|[^\\])[*?]/;
  $term =~ s/(^|[^\\])([+\[\]^{}\$|\(\).])/$1\\$2/g;
  $term =~ s/(^|[^\\])\*/$1.*/g;
  $term =~ s/(^|[^\\])\?/$1./g;
  return $term;
}

=head2 Methods for manipulating the BigWig files contained in the set

These are methods that allow you to add BigWig files to the set and
manipulate their metadata.

=over 4

=item $bws->readdir($path)

Read the contents of the indicated directory, and combine the
information about the BigWig .bw files and metadata indexes into a
BigWig set. You may call this repeatedly to combine multiple
directories into a BigWigSet.

=cut

sub readdir {
    my $self = shift;
    my $dir  = shift or croak "Usage: \$bigwigset->readdir(\$dir)";
    my ($wigfiles,$indices);
    if ($dir =~ /^(ftp|http):/) {
	($wigfiles,$indices) = $self->read_remote_dir($dir);
    }
    else {
	($wigfiles,$indices) = $self->read_local_dir($dir);
    }

    # create a lazy loading bigwig for each file
    for my $file (@$wigfiles) {
	$self->add_bigwig($file);
	my $name  = basename($file,'.bw');
	$self->set_bigwig_attributes($file,
				     {
					 display_name=>$name,
					 dbid        =>$file,
				     });
    }

    # read the tables of attributes
    for my $file (@$indices) {
	$self->read_index($file,$dir);
    }
}

sub read_local_dir {
    my $self = shift;
    my $dir  = shift;
    croak "directory $dir doesn't exist" unless -d $dir;
    croak "directory $dir not readable"  unless -r _;

    my (@indices,@wigfiles);
    my $d = IO::Dir->new($dir);
    while (my $node = $d->read) {
	next if $node =~ /^[.#]/; # dot files and temp files
	next if $node =~ /~$/;    # autosave files
	my $file = File::Spec->catfile($dir,$node);
	next unless -f $file;
	if ($node =~ /^meta/) {
	    push @indices,$file;
	} elsif ($node =~ /\.bw/i) {
	    push @wigfiles,$file;
	}
    }
    undef $d;
    return (\@wigfiles,\@indices);
}

sub read_remote_dir {
    my $self = shift;
    my $dir  = shift;

    eval "require LWP::UserAgent;1" or die "LWP is required to handle remote directories"
	unless LWP::UserAgent->can('new');

    eval "require URI::URL;1"       or die "URI::URL is required to handle remote directories"
	unless URI::URL->can('new');

    my $ua  = LWP::UserAgent->new;
    my $response = $ua->get($dir,Accept=>'text/html, */*;q=0.1');

    unless ($response->is_success) {
	warn "Web fetch of $dir failed: ",$response->status_line;
	return;
    }

    my $html = $response->decoded_content;
    my $base = $response->base;
    my @wigfiles = map {URI::URL->new($_=>$base)->abs} $html =~ /href="([^\"]+\.bw)"/ig;
    my @indices  = map {URI::URL->new($_=>$base)->abs} $html =~ /href="(meta[^\"]*)"/ig;
    return (\@wigfiles,\@indices);
}


=item $bws->add_bigwig($path)

Given a path to a .bw file, add the BigWig file to the set.

=cut

sub add_bigwig {
    my $self = shift;
    my $path = shift;
    $self->{bigwigs}{$path} = undef;  # lazy loading
}

=item $bws->remove_bigwig($path)

Given a path to a .bw file, removes it from the set.

=cut

sub remove_bigwig {
    my $self = shift;
    my $path = shift;
    delete $self->{bigwigs}{$path};
    delete $self->{attributes}{$path};
}

=item $bws->set_bigwig_attributes($path,$attributes)

Given the path to a BigWig file, assign metadata to it. The second
argument is a hash in which the keys are attribute names such as
"type" and the values are the values of those attributes.

If the BigWig file is not already part of the set, it is added (as in
add_bigwig()).

=cut

sub set_bigwig_attributes {
    my $self = shift;
    my ($path,$attributes) = @_;
    if (my $old = $self->{attributes}{$path}) {
	%$attributes = (%$old,%$attributes);  # merge
    }
    $self->{bigwigs}{$path}  ||= undef;
    $self->{attributes}{$path} = $attributes;
}

=item @paths = $bws->bigwigs

Returns the path to all the BigWig files in the collection.

=cut

sub bigwigs {
    my $self = shift;
    return keys %{$self->{bigwigs}};
}

=item $bigwig = $bws->get_bigwig($path)

If the BigWig file is part of the set, opens and returns it.

=back

=cut

sub get_bigwig {
    my $self = shift;
    my $path = shift;
    return unless exists $self->{bigwigs}{$path};
    my $bw = $self->{bigwigs}{$path} ||=
	Bio::DB::BigWig->new(-bigwig => $path,
			     -fasta  => $self->dna_accessor||undef) 
	or die "Could not open bigwig file $path: $!";
    return $bw;
}

sub read_index {
    my $self = shift;
    my ($file,$base) = @_;
    $base ||= dirname($file);
    my $f;

    if ($file =~ /^(ftp|http):/i) {
	my $ua = LWP::UserAgent->new;
	my $r  = $ua->get($file);
	die "Couldn't read $file: ",$r->status_line unless $r->is_success;
	eval "require IO::String; 1" 
	    or die "IO::String module is required for remote directories"
	    unless IO::String->can('new');
	$f = IO::String->new($r->decoded_content);
    }
    else {
	$f = IO::File->new($file) or die "$file: $!";
    }
    my ($current_path,%wigs);

    while (<$f>) {
	chomp;
	s/\s+$//;   # strip whitespace at ends of lines
	# strip right-column comments unless they look like colors or html fragments
	s/\s*\#.*$// unless /\#[0-9a-f]{6,8}\s*$/i || /\w+\#\w+/ || /\w+\"*\s*\#\d+$/;   
	if (/^\[([^\]]+)\]/) {  # beginning of a configuration section
	    my $wigname = $1;
	    $current_path    = $wigname =~ m!^(/|http:|ftp:)! ? $wigname
		                                              : "$base/$wigname";
	}

	elsif ($current_path && /^([\w: -]+?)\s*=\s*(.*)/) {  # key value pair
	    my $tag = lc $1;
	    my $value = defined $2 ? $2 : '';
	    $wigs{$current_path}{$tag}=$value;
	}
    }

    for my $path (keys %wigs) {
	my $attributes = $wigs{$path};
	$self->set_bigwig_attributes($path,$attributes);
    }
}

sub segment {
    my $self = shift;
    my ($seqid,$start,$end) = @_;

    if ($_[0] =~ /^-/) {
	my %args = @_;
	$seqid = $args{-seq_id} || $args{-name};
	$start = $args{-start};
	$end   = $args{-stop}    || $args{-end};
    } else {
	($seqid,$start,$end) = @_;
    }

    my ($one_bigwig) = keys %{$self->{bigwigs}};
    my $bw           = $self->get_bigwig($one_bigwig);

    my $size = $bw->length($seqid) or return;

    $start ||= 1;
    $end   ||= $bw->length($seqid);

    return unless $start >= 1 && $start < $size;
    return unless $end   >= 1 && $end   < $size;

    return Bio::DB::BigWigSet::Segment->new(-bws   => $self,
					    -seq_id=> $seqid,
					    -start => $start,
					    -end   => $end);
}

sub metadata {
    my $self = shift;

    my $att = $self->{attributes};

    # obscure file names
    my @indices = sort {
		      $att->{$a}{display_name} cmp $att->{$b}{display_name}
		  } keys %$att;
    my @values  = @{$att}{@indices};
    my @ids     = (1..@values);

    my %result;
    @result{@ids} = @values;

    return \%result;
}

package Bio::DB::BigWigSet::Segment;
use base 'Bio::DB::BigWig::Summary';

sub new {
    my $self = shift;
    my $feat  = $self->SUPER::new(@_);
    my %args = @_;
    $feat->{bws} = $args{-bws} if $args{-bws};
    return $feat;
}

sub features {
    my $self = shift;
    return $self->{bws}->features(-seq_id => $self->seq_id,
				  -start  => $self->start,
				  -end    => $self->end,
				  -type   => $_[0]);
}

sub get_seq_stream {
    my $self = shift;
    return $self->{bws}->get_seq_stream(-seq_id => $self->seq_id,
					-start  => $self->start,
					-end    => $self->end,
					-type   => $_[0]);
}


package Bio::DB::BigWigSet::Iterator;

sub new {
    my $class = shift;
    my ($set,$ids,$search_opts) = @_;
    return bless {set         => $set,
		  ids         => $ids,
		  search_opts => $search_opts,
    },ref $class || $class;
}

sub next_seq {
    my $self = shift;
    my $set  = $self->{set};
    my $ids  = $self->{ids};
    my $opts = $self->{search_opts};

    while (1) {
	if (my $i = $self->{current_iterator}) {
	    if (my $next = $i->next_seq) {
		my $id   = $self->{current_id};
		my $att  = $set->{attributes}{$id};
		if ($att) {
		    $next->set_attributes($att);
		    my ($method,$source) = split(':',$att->{type}||'');
		    $next->primary_tag($method || $att->{primary_tag}) if $method || $att->{primary_tag};
		    $next->source_tag ($source || $att->{source}     ) if $source || $att->{source};
		}
		return $next;
	    }
	}
	$self->{current_id}       = shift @$ids or return;  # leave when we run out of ids
	my $bw                    = $set->get_bigwig($self->{current_id}) or next;
	$self->{current_iterator} = $bw->get_seq_stream(%$opts,-type=>$set->feature_type);
    }
}

=head1 Using BigWig objects and GBrowse

The Generic Genome Browser version 2.0 (http://www.gmod.org/gbrowse)
can treat a BigWig file as a track database. A typical configuration
will look like this:

 [BigWig:database]
 db_adaptor    = Bio::DB::BigWigSet
 db_args       = -dir /var/www/data/bigwigs
	         -fasta  /var/www/data/elegans-ws190.fa

 [BigWigIntervals]
 feature  = ChIP-chip
 database = BigWig
 glyph    = wiggle_whiskers
 min_score = -1
 max_score = +1.5
 key       = ChIP-chip datasets

=head1 SEE ALSO

L<Bio::DB::BigWig> L<Bio::DB::BigFile>, L<Bio::Perl>, L<Bio::Graphics>, L<Bio::Graphics::Browser2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@oicr.on.caE<gt>.
E<lt>lincoln.stein@bmail.comE<gt>

Copyright (c) 2010 Ontario Institute for Cancer Research.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

1;

