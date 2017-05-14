package Boulder::Unigene;
#
use Boulder::Stream;
require Exporter;
@ISA = qw(Exporter Boulder::Stream);
@EXPORT = ();
@EXPORT_OK = ();
use Carp;
$VERSION=1.0;
use constant DEFAULT_UNIGENE_PATH => '/data/unigene/Hs.dat';

=head1 NAME

Boulder::Unigene - Fetch Unigene data records as parsed Boulder Stones

=head1 SYNOPSIS

  # parse a file of Unigene records
  $ug = new Boulder::Unigene(-accessor=>'File',
                             -param => '/data/unigene/Hs.dat');
  while (my $s = $ug->get) {
    print $s->Identifier;
    print $s->Gene;
  }

  # parse flatfile records yourself
  open (UG,"/data/unigene/Hs.dat");
  local $/ = "*RECORD*";
  while (<UG>) {
     my $s = Boulder::Unigene->parse($_);
     # etc.
  }

=head1 DESCRIPTION

Boulder::Unigene provides retrieval and parsing services for UNIGENE records

Boulder::Unigene provides retrieval and parsing services for NCBI
Unigene records.  It returns Unigene entries in L<Stone>
format, allowing easy access to the various fields and values.
Boulder::Unigene is a descendent of Boulder::Stream, and provides a
stream-like interface to a series of Stone objects.

Access to Unigene is provided by one I<accessors>, which
give access to  local Unigene database.  When you
create a new Boulder::Unigene stream, you provide the
accessors, along with accessor-specific parameters that control what
entries to fetch.  The accessors is:

=over 2

=item File

This provides access to local Unigene entries by reading from a flat file
(typically Hs.dat file downloadable from NCBI's Ftp site).
The stream will return a Stone corresponding to each of the entries in 
the file, starting from the top of the file and working downward.  The 
parameter is the path to the local file.

=back

It is also possible to parse a single Unigene entry from a text string 
stored in a scalar variable, returning a Stone object.

=head2 Boulder::Unigene methods

This section lists the public methods that the I<Boulder::Unigene>
class makes available.

=over 4

=item new()

   # Local fetch via File
   $ug=new Boulder::Unigene(-accessor  =>  'File',
                            -param     =>  '/data/unigene/Hs.dat');

The new() method creates a new I<Boulder::Unigene> stream on the
accessor provided.  The only possible accessors is B<File>.  
If successful, the method returns the stream
object.  Otherwise it returns undef.

new() takes the following arguments:

	-accessor	Name of the accessor to use
	-param		Parameters to pass to the accessor

Specify the accessor to use with the B<-accessor> argument.  If not
specified, it defaults to B<File>.  

B<-param> is an accessor-specific argument.  The possibilities is:

For B<File>, the B<-param> argument must point to a string-valued
scalar, which will be interpreted as the path to the file to read
Unigene entries from.

=item get()

The get() method is inherited from I<Boulder::Stream>, and simply
returns the next parsed Unigene Stone, or undef if there is nothing
more to fetch.  It has the same semantics as the parent class,
including the ability to restrict access to certain top-level tags.

=item put()

The put() method is inherited from the parent Boulder::Stream class,
and will write the passed Stone to standard output in Boulder format.
This means that it is currently not possible to write a
Boulder::Unigene object back into Unigene flatfile form.

=back

=head1 OUTPUT TAGS

The tags returned by the parsing operation are taken from the names shown in the Flat file
Hs.dat since no better description of them is provided yet by the database source producer.

=head2 Top-Level Tags

These are tags that appear at the top level of the parsed Unigene
entry.

=over 4

=item Identifier

The Unigene identifier of this entry.  Identifier is a single-value tag.

Example:
       
      my $identifierNo = $s->Identifier;

=item Title

The Unigene title for this entry.

Example:
      my $titledef=$s->Title;

=item Gene
The Gene associated with   this Unigene entry

Example:
      my $thegene=$s->Gene;

=item Cytoband
The cytological band position of this entry

Example:
      my $thecytoband=$s->Cytoband;

=item Counts
The number of EST in this record

Example:
      my $thecounts=$s->Counts;

=item LocusLink
The id of the LocusLink entry associated with this record

Example:
      my $thelocuslink=$s->LocusLink;

=item Chromosome
This field contains a list, of the chromosomes numbers in which this entry has been linked

Example:
      my @theChromosome=$s->Chromosome;

=back

=head2 STS     
Multiple records in the form ^STS     ACC=XXXXXX NAME=YYYYYY

=over 4

=item ACC

=item NAME

=back

=head2 TXMAP
Multiple records in the form  ^TXMAP  XXXXXXX; MARKER=YYYYY; RHPANEL=ZZZZ

The TXMAP tag points to a Stone record that contains multiple
subtags.  Each subtag is the name of a feature which points, in turn,
to a Stone that describes the feature's location and other attributes.

Each feature will contain one or more of the following subtags:

=over 4

=item MARKER

=item RHPANEL

=back


=head2 PROTSIM
Multiple records in the form ^PROTSIM ORG=XXX; PROTID=DBID:YYY; PCT=ZZZ; ALN=QQQQ
Where DBID is 
	PID for indicate presence of GenPept identifier, 
	SP to indicate SWISSPROT identifier,
	PIR to indicate PIR identifier,
	PRF to indicate ???

=over 4

=item ORG

=item PROTID

=item PCT

=item ALN

=back

=head2 SEQUENCE
Multiple records in the form ^SEQUENCE ACC=XXX; NID=YYYY; PID = CLONE= END= LID=

=over

=item ACC

=item NID

=item PID

=item CLONE

=item END

=item LID

=back

=head1 SEE ALSO

L<Boulder>, L<Boulder::Blast>, L<Boulder::Genbank>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.
Luca I.G. Toldo <luca.toldo@merck.de>

Copyright (c) 1997 Lincoln D. Stein
Copyright (c) 1999 Luca I.G. Toldo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

#
# Following did not require any changes compared to Genbank.pm
#
sub new  {
    my($package,@parameters) = @_;
    # superclass constructor
    my($self) = new Boulder::Stream;
    
    # figure out whether parameters are named.  Look for
    # an initial '-'
    if ($parameters[0]=~/^-/) {
	my(%parameters) = @parameters;
	$self->{'accessor'}=$parameters{'-accessor'} || 'File';
	$self->{'param'}=$parameters{'-param'};
	$self->{'OUT'}=$parameters{'-out'} || 'main::STDOUT';
    } else {
	$self->{'accessor'}='File';
	$self->{'param'}=[@parameters];
    }
    
    croak "Require parameters" unless defined($self->{'param'});
    $self->{'accessor'} = new {$self->{'accessor'}}($self->{'param'});
    
    return bless $self,$package;
}

#
# Following required no changes compared to Genbank.pm
#
sub read_record {
    my($self,@tags) = @_;
    my($s);

    if (wantarray) {
	my(@result);
	while (!$self->{'done'}) {
	    $s = $self->read_one_record(@tags);
	    next unless $s;
	    next if $query && !(&$query);
	    push(@result,$s);
	}
	return @result;
    } 

    # we get here if in a scalar context
    while (!$self->{'done'}) {
	$s = $self->read_one_record(@tags);
	next unless $s;
	return $s unless $query;
	return $s if &$query;
    }
    return undef;
}

#<LIGT>
# Here is everything new
#</LIGT>
sub parse {
  my $self = shift;
  my $record = shift;
  return unless $record;
  my $tags = shift;
  my %ok;
  %ok = map {$_ => 1} @$tags if ref($tags) eq 'ARRAY';
    my($s,@lines,$line,$accumulated,$key,$keyword,$value,$feature,@features, $label);
  
  $s = new Stone;
#<LIGT> following this line the parsing of the record must be done
#              each key-value pair is stored by the following command:
#	$self->_addToStone($key,$value,$stone,\%ok);
#
# Process new record lines
#
#
  (@recordlines)=split(/\n/,$record);
 undef $unigeneid, $title, $gene,$cytoband, $locuslink, $chromosome, $scount;
 undef $sts, $txmap,$protsim,$sequence;
 undef @sts,@txmaps,@protsims,@sequences;
  foreach $line  (@recordlines) {
    if      ($line=~/^ID/) {
     ($key,$unigeneid)=split(/\s+/,$line);
     $self->_addToStone('Identifier',$unigeneid,$s,\%ok);
    } elsif ($line=~/^TITLE/) {
     (@titles)=split(/\s+/,$line);
     shift @titles;
     $title=join(' ',@titles);
     $self->_addToStone('Title',$title,$s,\%ok);
    } elsif ($line=~/^GENE/) {
     ($key,$gene)=split(/\s+/,$line);
     $self->_addToStone('Gene',$gene,$s,\%ok);
    } elsif ($line=~/^CYTOBAND/) {
     ($key,$cytoband)=split(/\s+/,$line);
     $self->_addToStone('Cytoband',$cytoband,$s,\%ok);
    } elsif ($line=~/^LOCUSLINK/) {
     ($key,$locuslink)=split(/\s+/,$line);
     $self->_addToStone('Locuslink',$locuslink,$s,\%ok);
    } elsif ($line=~/^CHROMOSOME/) {
     ($key,$chromosome)=split(/\s+/,$line);
     $self->_addToStone('Chromosome',$chromosome,$s,\%ok);
    } elsif ($line=~/^SCOUNT/) {
     ($key,$scount)=split(/\s+/,$line);
     $self->_addToStone('Scount',$scount,$s,\%ok);
    } elsif ($line=~/^STS/) {
#STS ACC=XXX; NAME=YYY;
     (@sts)=split(/\s+/,$line); shift @sts;  $sts=join(' ',@sts);
     ($tmpacc,$tmpname)=split(/\s+/,$sts);
     ($jnk,$acc)=split(/\=/,$tmpacc);
     ($jnk,$name)=split(/\=/,$tmpname);

     undef @features;    
     $featurelabel="Accession"; $featurevalue=$name;
     $feature = {'label'=>$featurelabel,'value'=>$featurevalue};
     push(@features,$feature);
     $featurelabel="Name";
     $feature = {'label'=>$featurelabel,'value'=>$featurevalue};
     push(@features,$feature);

      $self->_addFeaturesToStone(\@features,_trim($'),$s,\%ok);
    } elsif ($line=~/^TXMAP/) {
#TXMAP  XXX; MARKER=YYY; RHPANEL=ZZZ;
     (@txmaps)=split(/\s+/,$line); shift @txmaps;  $txmap=join(' ',@txmaps);
#     $self->_addToStone('TXMAP',$txmap,$s,\%ok);
    undef @features;
     $self->_addFeaturesToStone(\@features,_trim($'),$s,\%ok);
    } elsif ($line=~/^PROTSIM/) {
#PROTSIM ORG=QQQ; PROTID=RRR; PCT=SSSS; ALN=TTTT;
     (@protsims)=split(/\s+/,$line); shift @protsims;  $protsim=join(' ',@protsims);
#     $self->_addToStone('PROTSIM',$protsim,$s,\%ok);
    undef @features;
     $self->_addFeaturesToStone(\@features,_trim($'),$s,\%ok);
    } elsif ($line=~/^SEQUENCE/) {
#SEQUENCE ACC=XXXX; NID=YYYY; PID=RRRRR; CLONE=QQQ; END=PPPP; LID=ZZZZ;
     (@sequences)=split(/\s+/,$line); shift @sequences;  $sequence=join(' ',@sequences);
#     $self->_addToStone('SEQUENCE',$sequence,$s,\%ok);
    undef @features;
     $self->_addFeaturesToStone(\@features,_trim($'),$s,\%ok);
   }
 }
#</LIGT>
  return $s;
}

#
# Following is unchanged from Genbank.pm
#
sub read_one_record {
  my($self,@tags) = @_;
  my(%ok);  
  my $accessor = $self->{'accessor'};
  my $record   = $accessor->fetch_next();
  unless ($record) {
    $self->{'done'}++;
    return undef;
  }

  return $self->parse($record,\@tags);
}

#
# Following is unchanged from Genbank.pm
#
sub _trim {
    my($v) = @_;
    $v=~s/^\s+//;
    $v=~s/\s+$//;
    return $v;
}

#
# Following is unchanged from Genbank.pm
#
sub _canonicalize {
  my $h = shift;
  substr($h,0)=~tr/a-z/A-Z/;
  substr($h,1,length($h)-1)=~tr/A-Z/a-z/;
  $h;
}

#
# Following is unchanged from Genbank.pm
#
sub _addToStone {
    my($self,$xlabel,$value,$stone,$ok) = @_;
    return unless !%{$ok} || $ok->{$xlabel};
    $stone->insert(_canonicalize($xlabel),$value);
}

#<LIGT>
# Following is entirely rewritten
#</LIGT>
sub _addFeaturesToStone {
	my($self,$features,$basecount,$stone,$ok) = @_;
	my($f) = new Stone;
	foreach (@$features) {
		my($q) = $_->{'value'};
		my($label) = _canonicalize($_->{'label'});
		my($position) = $q=~m!^([^/]+)!;
		my @qualifiers = $q=~m!/(\w+)=([^/]+)!g;
		my %qualifiers;
		while (my($key,$value) = splice(@qualifiers,0,2)) {
			$value =~ s/^\s*\"//;
			$value =~s/\"\s*$//;
			$value=~s/\s+//g if uc($key) eq 'TRANSLATION';  
			$qualifiers{_canonicalize($key)} = $value;
		}
		$f->insert($label=>new Stone('Position'=>$position,%qualifiers));
	}
	$stone->insert('Features',$f);
}



# -------------------------- DEFINITION OF ACCESSOR OBJECTS ------------------------------
#<LIGT>
#only name changes for avoid namespace collisions
#</LIGT>
package UnigeneAccessor;
use Carp;

sub new {
    my($class,@parameters) = @_;
    croak "UnigeneAccessor::new:  Abstract class\n";
}

sub fetch_next {
    my($self) = @_;
    croak "UnigeneAccessor::fetch_next: Abstract class\n";
}

sub DESTROY {
}

#<LIGT>
# Following, only the File package since the only one supported.
# If other access methods must be supported, then here appropriate
# packages and methods must be implemented
#</LIGT>
package File;
use Carp;
@ISA=qw(UnigeneAccessor);
$DEFAULT_PATH = Boulder::Unigene::DEFAULT_UNIGENE_PATH();

#<LIGT>
# Following, removed the search for the string locus in the file
#   as validation that the input be compliant with parser
#</LIGT>
sub new {
    my($package,$path) = @_;
    $path = $DEFAULT_PATH unless $path;
    open (UG,$path) or croak "File::new(): couldn't open $path: $!";
    # read the junk at the beginning
    my $found; $found++;
    croak "File::new(): $path doesn't look like a Unigene flat file"
	unless $found;
    $_ = <UG>;
    return bless {'fh'=>UG},$package;
}

#<LIGT>
# Following, changed the record separator
#</LIGT>
sub fetch_next {
    my $self = shift;
    return undef unless $self->{'fh'};
    local($/)="//\n";
    my($line);
    my($fh) = $self->{'fh'};
    chomp($line = <$fh>);
    return $line;
}

1;

__END__

