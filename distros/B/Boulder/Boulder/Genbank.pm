package Boulder::Genbank;

use strict;
use Boulder::Stream;
use Stone::GB_Sequence;
use Carp;
use vars qw(@ISA $VERSION);
@ISA = qw(Boulder::Stream);

$VERSION = 1.01;

# Hard-coded defaults - must modify for your site
use constant YANK            =>  '/usr/local/bin/yank';

# used by Entrez accessor, may need to change in the future
use constant HOST      => 'www.ncbi.nlm.nih.gov';
use constant BATCH_URI => '/cgi-bin/Entrez/qserver.cgi/result';

# Genbank entry parsing constants
# (may need to adjust!)
my $KEYCOL=0;
my $VALUECOL=12;
my $FEATURECOL=5;
my $FEATUREVALCOL=21;

=head1 NAME

Boulder::Genbank - Fetch Genbank data records as parsed Boulder Stones

=head1 SYNOPSIS

  use Boulder::Genbank
  
  # network access via Entrez
   $gb = Boulder::Genbank->newFh( qw(M57939 M28274 L36028) );

   while ($data = <$gb>) {
       print $data->Accession;

       @introns = $data->features->Intron;
       print "There are ",scalar(@introns)," introns.\n";
       $dna = $data->Sequence;
       print "The dna is ",length($dna)," bp long.\n";     

       my @features = $data->features(-type=>[ qw(Exon Source Satellite) ], 
				      -pos=>[90,310] );
       foreach (@features) {
          print $_->Type,"\n";
          print $_->Position,"\n";
          print $_->Gene,"\n";
      }
    }

  # another syntax
  $gb = new Boulder::Genbank(-accessor=>'Entrez',
                             -fetch => [qw/M57939 M28274 L36028/]);

  # local access via Yank
  $gb = new Boulder::Genbank(-accessor=>'Yank',
                             -fetch=>[qw/M57939 M28274 L36028/]);
  while (my $s = $gb->get) {
     # etc.
  }

  # parse a file of Genbank records
  $gb = new Boulder::Genbank(-accessor=>'File',
                             -fetch => '/usr/local/db/gbpri3.seq');
  while (my $s = $gb->get) {
     # etc.
  }

  # parse flatfile records yourself
  open (GB,"/usr/local/db/gbpri3.seq");
  local $/ = "//\n";
  while (<GB>) {
     my $s = Boulder::Genbank->parse($_);
     # etc.
  }

=head1 DESCRIPTION

Boulder::Genbank provides retrieval and parsing services for NCBI
Genbank-format records.  It returns Genbank entries in L<Stone>
format, allowing easy access to the various fields and values.
Boulder::Genbank is a descendent of Boulder::Stream, and provides a
stream-like interface to a series of Stone objects.

Access to Genbank is provided by three different I<accessors>, which
together give access to remote and local Genbank databases.  When you
create a new Boulder::Genbank stream, you provide one of the three
accessors, along with accessor-specific parameters that control what
entries to fetch.  The three accessors are:

=over 4

=item Entrez

This provides access to NetEntrez, accessing the most recent Genbank
information directly from NCBI's Web site.  The parameters passed to
this accessor are either a series of Genbank accession numbers, or an
Entrez query (see http://www.ncbi.nlm.nih.gov/Entrez/linking.html).
If you provide a list of accession numbers, the stream will return a
series of stones corresponding to the numbers.  Otherwise, if you
provided an Entrez query, the entries returned will be in the order
returned by Entez.

=item File

This provides access to local Genbank entries by reading from a flat file
(typically one of the .seq files downloadable from NCBI's Web site).
The stream will return a Stone corresponding to each of the entries in 
the file, starting from the top of the file and working downward.  The 
parameter in this case is the path to the local file.

=item Yank

This provides access to local Genbank entries using Will Fitzhugh's
Yank program.  Yank provides fast indexed access to a Genbank flat
file using the accession number as the key.  The parameter passed to
the Yank accessor is a list of accession numbers.  Stones will be
returned in the requested order.  By default the yank binary lives in
/usr/local/bin/yank.  To support other locations, you may define the
environment variable YANK to contain the full path.

=back

It is also possible to parse a single Genbank entry from a text string 
stored in a scalar variable, returning a Stone object.

=head2 Boulder::Genbank methods

This section lists the public methods that the I<Boulder::Genbank>
class makes available.

=over 4

=item new()

   # Network fetch via Entrez, with accession numbers
   $gb=new Boulder::Genbank(-accessor  =>  'Entrez',
                            -fetch     =>  [qw/M57939 M28274 L36028/]);

   # Same, but shorter and uses -> operator
   $gb = Boulder::Genbank->new qw(M57939 M28274 L36028);

   # Network fetch via Entrez, with a query

   # Network fetch via Entrez, with a query
   $query = 'Homo sapiens[Organism] AND EST[Keyword]';
   $gb=new Boulder::Genbank(-accessor  =>  'Entrez',
                            -fetch     =>  $query);

   # Local fetch via Yank, with accession numbers
   $gb=new Boulder::Genbank(-accessor  =>  'Yank',
                            -fetch     =>  [qw/M57939 M28274 L36028/]);

   # Local fetch via File
   $gb=new Boulder::Genbank(-accessor  =>  'File',
                            -fetch     =>  '/usr/local/genbank/gbpri3.seq');

The new() method creates a new I<Boulder::Genbank> stream on the
accessor provided.  The three possible accessors are B<Entrez>,
B<Yank> and B<File>.  If successful, the method returns the stream
object.  Otherwise it returns undef.

new() takes the following arguments:

	-accessor	Name of the accessor to use
	-fetch		Parameters to pass to the accessor

Specify the accessor to use with the B<-accessor> argument.  If not
specified, it defaults to B<Entrez>. 

B<-fetch> is an accessor-specific argument.  The possibilities are:

For B<Entrez>, the B<-fetch> argument may point to a scalar, in which
case it is interpreted as an Entrez query string.  See
http://www.ncbi.nlm.nih.gov/Entrez/linking.html for a description of
the query syntax.  Alternatively, B<-fetch> may point to an array
reference, in which case it is interpreted as a list of accession
numbers to retrieve.  If B<-fetch> points to a hash, it is interpreted
as extended information.  See L<"Extended Entrez Parameters"> below.

For B<Yank>, the B<-fetch> argument must point to an array reference
containing the accession numbers to retrieve.

For B<File>, the B<-fetch> argument must point to a string-valued
scalar, which will be interpreted as the path to the file to read
Genbank entries from.

For Entrez (and Entrez only) Boulder::Genbank allows you to use a
shortcut syntax in which you provde new() with a list of accession
numbers:

  $gb = new Boulder::Genbank('M57939','M28274','L36028');

=item newFh()

This works like new(), but returns a filehandle.  To recover each
GenBank record read from the filehandle with the <> operator:

  $fh = Boulder::GenBank->newFh('M57939','M28274','L36028');
  while ($record = <$fh>) {
     print $record->asString;
  }

=item get()

The get() method is inherited from I<Boulder::Stream>, and simply
returns the next parsed Genbank Stone, or undef if there is nothing
more to fetch.  It has the same semantics as the parent class,
including the ability to restrict access to certain top-level tags.

The object returned is a L<Stone::GB_Sequence> object, which is a
descendent of L<Stone>.

=item put()

The put() method is inherited from the parent Boulder::Stream class,
and will write the passed Stone to standard output in Boulder format.
This means that it is currently not possible to write a
Boulder::Genbank object back into Genbank flatfile form.

=back

=head2 Extended Entrez Parameters

The Entrez accessor recognizes extended parameters that allow you the
ability to customize the search.  Instead of passing a query string
scalar or a list of accession numbers as the B<-fetch> argument, pass
a hash reference.  The hashref should contain one or more of the
following keys:

=over

=item B<-query>

The Entrez query to process.

=item B<-accession>

The list of accession numbers to fetch, as an array ref.

=item B<-db>

The database to search.  This is a single-letter database code
selected from the following list:

  m  MEDLINE
  p  Protein
  n  Nucleotide
  t  3-D structure
  c  Genome

=back

As an example, here's how to search for ESTs from Oryza sativa that
have been entered or modified since January 12, 1999.

  my $gb = new Boulder::Genbank( -accessor=>Entrez, 
				 -query=>'Oryza sativa[Organism] AND EST[Keyword] AND 1999/01/12[Modification date]', 
                                 -db   => 'n'   
                                });

=head1 METHODS DEFINED BY THE GENBANK STONE OBJECT

Each record returned from the Boulder::Genbank stream defines a set of
methods that correspond to features and other fields in the Genbank
flat file record.  L<Stone::GB_Sequence> gives the full details, but
they are listed for reference here:

=head2 $length = $entry->length

Get the length of the sequence.

=head2 $start = $entry->start

Get the start position of the sequence, currently always "1".

=head2 $end = $entry->end

Get the end position of the sequence, currently always the same as the
length.

=head2 @feature_list = $entry->features(-pos=>[50,450],-type=>['CDS','Exon'])

features() will search the entry feature list for those features that
meet certain criteria.  The criteria are specified using the B<-pos>
and/or B<-type> argument names, as shown below.

=over 4

=item -pos

Provide a position or range of positions which the feature must
B<overlap>.  A single position is specified in this way:

   -pos => 1500;         # feature must overlap postion 1500

or a range of positions in this way:

   -pos => [1000,1500];  # 1000 to 1500 inclusive

If no criteria are provided, then features() returns all the features,
and is equivalent to calling the Features() accessor.

=item -type, -types

Filter the list of features by type or a set of types.  Matches are
case-insensitive, so "exon", "Exon" and "EXON" are all equivalent.
You may call with a single type as in:

   -type => 'Exon'

or with a list of types, as in

   -types => ['Exon','CDS']

The names "-type" and "-types" can be used interchangeably.

=head2 $seqObj = $entry->bioSeq;

Returns a L<Bio::Seq> object from the Bioperl project.  Dies with an
error message unless the Bio::Seq module is installed.

=back

=head1 OUTPUT TAGS

The tags returned by the parsing operation are taken from the NCBI
ASN.1 schema.  For consistency, they are normalized so that the
initial letter is capitalized, and all subsequent letters are
lowercase.  This section contains an abbreviated list of the most
useful/common tags.  See "The NCBI Data Model", by James Ostell and
Jonathan Kans in "Bioinformatics: A Practical Guide to the Analysis
of Genes and Proteins" (Eds. A. Baxevanis and F. Ouellette), pp
121-144 for the full listing.

=head2 Top-Level Tags

These are tags that appear at the top level of the parsed Genbank
entry.

=over 4

=item Accession

The accession number of this entry.  Because of the vagaries of the
Genbank data model, an entry may have multiple accession numbers
(e.g. after a merging operation).  Accession may therefore be a
multi-valued tag.

Example:
       
      my $accessionNo = $s->Accession;

=item Authors

The list of authors, as they appear on the AUTHORS line of the Genbank
record.  No attempt is made to parse them into individual authors.

=item Basecount

The nucleotide basecount for the entry.  It is presented as a Boulder
Stone with keys "a", "c", "t" and "g".  Example:

     my $A = $s->Basecount->A;
     my $C = $s->Basecount->C;
     my $G = $s->Basecount->G;
     my $T = $s->Basecount->T;
     print "GC content is ",($G+$C)/($A+$C+$G+$T),"\n";

=item Comment

The COMMENT line from the Genbank record.

=item Definition

The DEFINITION line from the Genbank record, unmodified.

=item Features

The FEATURES table.  This is a complex stone object with multiple
subtags.  See the L<"The Features Tag"> for details.


=item Journal

The JOURNAL line from the Genbank record, unmodified.

=item Keywords

The KEYWORDS line from the Genbank record, unmodified.  No attempt is
made to parse the keywords into separate values.

Example:

    my $keywords = $s->Keywords

=item Locus

The LOCUS line from the Genbank record.  It is not further parsed.

=item Medline, Nid

References to other database accession numbers.

=item Organism

The taxonomic name of the organism from which this entry was
derived. This line is taken from the Genbank entry unmodified.  See
the NCBI data model documentation for an explanation of their
taxonomic syntax.

=item Reference

The REFERENCE line from the Genbank entry.  There are often multiple
Reference lines.  Example:

  my @references = $s->Reference;

=item Sequence

The DNA or RNA sequence of the entry.  This is presented as a single
lower-case string, with all base numbers and formatting characters
removed. 

=item Source

The entry's SOURCE field; often giving clues on how the sequencing was
performed.

=item Title

The TITLE field from the paper describing this entry, if any.

=back

=head2 The Features Tag

The Features tag points to a Stone record that contains multiple
subtags.  Each subtag is the name of a feature which points, in turn,
to a Stone that describes the feature's location and other attributes.
The full list of feature is beyond this document, but the following
are the features that are most often seen:

	Cds		a CDS
	Intron		an intron
	Exon		an exon
	Gene		a gene
	Mrna		an mRNA
	Polya_site	a putative polyadenylation signal
	Repeat_unit	a repetitive region
	Source		More information about the organism and cell
			type the sequence was derived from
	Satellite	a microsatellite (dinucleotide repeat)

Each feature will contain one or more of the following subtags:

=over 4

=item DB_xref

A cross-reference to another database in the form
DB_NAME:accession_number.  See the NCBI Web site for a description of
these cross references.

=item Evidence

The evidence for this feature, either "experimental" or "predicted".

=item Gene

If the feature involves a gene, this will be the gene's name (or one
of its names).  This subtag is often seen in "Gene" and Cds features.

Example:

	foreach ($s->Features->Cds) {
	   my $gene = $_->Gene;
	   my $position = $_->Position;
           Print "Gene $gene ($position)\n";
        }

=item Map

If the feature is mapped, this provides a map position, usually as a
cytogenetic band.

=item Note

A grab-back for various text notes.

=item Number

When multiple features of this type occur, this field is used to
number them.  Ordinarily this field is not needed because
Boulder::Genbank preserves the order of features.

=item Organism

If the feature is Source, this provides the source organism.

=item Position

The position of this feature, usually expresed as a range
(1970..1975).

=item Product

The protein product of the feature, if applicable, as a text string.

=item Translation

The protein translation of the feature, if applicable.

=back

=head1 SEE ALSO

L<Boulder>, L<Boulder::Blast>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 1997 Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=head1 EXAMPLE GENBANK OBJECT

The following is an excerpt from a moderately complex Genbank Stone.
The Sequence line and several other long lines have been truncated for readability.

 Authors=Spritz,R.A., Strunk,K., Surowy,C.S.O., Hoch,S., Barton,D.E. and Francke,U.
 Authors=Spritz,R.A., Strunk,K., Surowy,C.S. and Mohrenweiser,H.W.
 Locus=HUMRNP7011   2155 bp    DNA             PRI       03-JUL-1991
 Accession=M57939
 Accession=J04772
 Accession=M57733
 Keywords=ribonucleoprotein antigen.
 Sequence=aagcttttccaggcagtgcgagatagaggagcgcttgagaaggcaggttttgcagcagacggcagtgacagcccag...
 Definition=Human small nuclear ribonucleoprotein (U1-70K) gene, exon 10 and 11.
 Journal=Nucleic Acids Res. 15, 10373-10391 (1987)
 Journal=Genomics 8, 371-379 (1990)
 Nid=g337441
 Medline=88096573
 Medline=91065657
 Features={
   Polya_site={
     Evidence=experimental
     Position=1989 
     Gene=U1-70K
   }
   Polya_site={
     Position=1990 
     Gene=U1-70K
   }
   Polya_site={
     Evidence=experimental
     Position=1992 
     Gene=U1-70K
   }
   Polya_site={
     Evidence=experimental
     Position=1998 
     Gene=U1-70K
   }
   Source={
     Organism=Homo sapiens
     Db_xref=taxon:9606
     Position=1..2155 
     Map=19q13.3
   }
   Cds={
     Codon_start=1 
     Product=ribonucleoprotein antigen
     Db_xref=PID:g337445
     Position=join(M57929:329..475,M57930:183..245,M57930:358..412, ...
     Gene=U1-70K
     Translation=MTQFLPPNLLALFAPRDPIPYLPPLEKLPHEKHHNQPYCGIAPYIREFEDPRDAPPPTR...
   }
   Cds={
     Codon_start=1 
     Product=ribonucleoprotein antigen
     Db_xref=PID:g337444
     Evidence=experimental 
     Position=join(M57929:329..475,M57930:183..245,M57930:358..412, ...
     Gene=U1-70K
     Translation=MTQFLPPNLLALFAPRDPIPYLPPLEKLPHEKHHNQPYCGIAPYIREFEDPR...
   }
   Polya_signal={
     Position=1970..1975 
     Note=putative
     Gene=U1-70K
   }
   Intron={
     Evidence=experimental
     Position=1100..1208 
     Gene=U1-70K
   }
   Intron={
     Number=10 
     Evidence=experimental
     Position=1100..1181 
     Gene=U1-70K
   }
   Intron={
     Number=9 
     Evidence=experimental
     Position=order(M57937:702..921,1..1011) 
     Note=2.1 kb gap
     Gene=U1-70K
   }
   Intron={
     Position=order(M57935:272..406,M57936:1..284,M57937:1..599, <1..>1208) 
     Gene=U1-70K
   }
   Intron={
     Evidence=experimental
     Position=order(M57935:284..406,M57936:1..284,M57937:1..599, <1..>1208) 
     Note=first gap-0.14 kb, second gap-0.62 kb
     Gene=U1-70K
   }
   Intron={
     Number=8 
     Evidence=experimental
     Position=order(M57935:272..406,M57936:1..284,M57937:1..599, <1..>1181) 
     Note=first gap-0.14 kb, second gap-0.62 kb
     Gene=U1-70K
   }
   Exon={
     Number=10 
     Evidence=experimental
     Position=1012..1099 
     Gene=U1-70K
   }
   Exon={
     Number=11 
     Evidence=experimental
     Position=1182..(1989.1998) 
     Gene=U1-70K
   }
   Exon={
     Evidence=experimental
     Position=1209..(1989.1998) 
     Gene=U1-70K
   }
   Mrna={
     Product=ribonucleoprotein antigen
     Position=join(M57928:358..668,M57929:319..475,M57930:183..245, ...
     Gene=U1-70K
   }
   Mrna={
     Product=ribonucleoprotein antigen
     Citation=[2] 
     Evidence=experimental 
     Position=join(M57928:358..668,M57929:319..475,M57930:183..245, ...
     Gene=U1-70K
   }
   Gene={
     Position=join(M57928:207..719,M57929:1..562,M57930:1..577, ...
     Gene=U1-70K
   }
 }
 Reference=1  (sites)
 Reference=2  (bases 1 to 2155)
 =

=cut

# new() takes named parameters:
# -accessor=> Reference to an object class that will return a series of
#           Genbank records.  Predefined objects include 'Yank', 'Entrez' and 'File'.
#           (defaults to 'Entrez').
# -fetch=>  Parameters to pass to the subroutine.  Can be a list of accession numbers
#           or an entrez query.
# -out=>    Output filehandle.  Defaults to STDOUT.
#
# If you don't use named parameters, then will assume method 'yank' on
# a list of accession numbers.
# e.g.
#        $gb = new Boulder::Genbank(-accessor=>'Yank',-fetch=>[qw/M57939 M28274 L36028/]);
sub new {
    my($package,@parameters) = @_;
    # superclass constructor
    my($self) = $package->SUPER::new();
    
    # figure out whether parameters are named.  Look for
    # an initial '-'
    my %parameters;

    if ($parameters[0]=~/^-/) {
	%parameters = @parameters;
	$self->{accessor}=$parameters{'-accessor'} || 'Entrez';
	$self->{OUT}=$parameters{'-out'} || \*STDOUT;
	$self->{format}    = $parameters{'-format'};
    } else {
	$self->{accessor}='Entrez';
	$parameters{-fetch} = \@parameters;
    }

    $self->{format} ||= 'stone';
    $parameters{-format} = $self->{format};
    $self->{accessor} = new {$self->{accessor}}(\%parameters);
    
    return bless $self,$package;
}

sub read_record {
    my($self,@tags) = @_;
    my($s);
    my $query = $self->{query};

    if (wantarray) {
	my(@result);
	while (!$self->{EOF}) {
	    $s = $self->read_one_record(@tags);
	    next unless $s;
	    next if $query && !(&$query);
	    push(@result,$s);
	}
	return @result;
    } 

    # we get here if in a scalar context
    while (!$self->{EOF}) {
	$s = $self->read_one_record(@tags);
	next unless $s;
	return $s unless $query;
	return $s if &$query;
    }
    return undef;
}

sub parse {
  my $self = shift;
  my $record = shift;
  return unless $record;

  my $tags = shift;
  my %ok;
  %ok = map {$_ => 1} @$tags if ref($tags) eq 'ARRAY';
  
  my($s,@lines,$line,$accumulated,$key,$keyword,$value,$feature,@features);
  
  $s = Stone::GB_Sequence->new;
  @lines = split("\n",$record);
  
  foreach $line (@lines) {
    
    if ($line=~/^ACCESSION\s+(.+)/) {
      foreach ($1=~/(\S+)/g) {
	$self->_addToStone('Accession',$_,$s,\%ok);
      }
      next;
    }
      
    # special case for the features table
    if ($line=~/^FEATURES/..$line=~/^ORIGIN/) {
      undef $keyword;
      
      if ($line=~/^FEATURES/) {
	undef @features;
	next;
      }

      if ($line=~/BASE COUNT|ORIGIN/) {
	push(@features,$feature) if $feature;
	$self->_addFeaturesToStone(\@features,_trim($'),$s,\%ok) if @features;
	undef @features; undef $feature;
	next if $line =~ /BASE COUNT/;

	# special case for the sequence itself
	if ($line=~/^ORIGIN/) {
	  $self->_addToStone($key,$accumulated,$s,\%ok) if $key;
	  last;
	}
      }
    
      my($featurelabel) = _trim(substr($line,$FEATURECOL,$FEATUREVALCOL-$FEATURECOL));
      my($featurevalue) = _trim(substr($line,$FEATUREVALCOL));
      if ($featurelabel) {
	push(@features,$feature) if $feature;
	$feature = {'label'=>$featurelabel,'value'=>$featurevalue};
      } else {
	$feature->{'value'} .= $featurevalue;
      }
      
      next;
    }
    
    $keyword = _trim(substr($line,0,$VALUECOL-1));
    $value = _trim(substr($line,$VALUECOL));
    
    if ($keyword && $key) {
      $self->_addToStone($key,_trim($accumulated),$s,\%ok);
      $accumulated = $value;
      next;
    }
    $accumulated .= " $value";
  } continue {
    $key = $keyword if $keyword;
  }
  
  my ($sequence)=$record=~/\nORIGIN.*\n([\s\S]+)/;
  $sequence=~s/[\s0-9-]+//g;  # remove white space
  $self->_addToStone('Sequence',$sequence,$s,\%ok);
  return $s;
}

sub read_one_record {
  my($self,@tags) = @_;
  my(%ok);
  
  my $accessor = $self->{'accessor'};
  my $record   = $accessor->fetch_next();
  unless ($record) {
    $self->{EOF}++;
    return undef;
  }

  return $record unless $self->{format} eq 'stone';
  return $self->parse($record,\@tags);
}

sub _trim {
    my($v) = @_;
    $v=~s/^\s+//;
    $v=~s/\s+$//;
    return $v;
}

sub _canonicalize {
  my $h = shift;
  substr($h,0)=~tr/a-z/A-Z/;
  substr($h,1,length($h)-1)=~tr/A-Z/a-z/;
  $h;
}

sub _addToStone {
    my($self,$label,$value,$stone,$ok) = @_;
    return unless !%{$ok} || $ok->{$label};
    $stone->insert(_canonicalize($label),$value);
}

sub _addFeaturesToStone {
    my($self,$features,$basecount,$stone,$ok) = @_;

    # first add the basecount
    if (!%{$ok} || $ok->{'BASECOUNT'}) {
	my(%counts) = $basecount=~/(\d+)\s+([gatcGATC])/g;
	%counts = map { uc $_ } reverse %counts;
	$stone->insert('Basecount',new Stone(%counts));
    }
    
    if (!%{$ok} || $ok->{'FEATURES'}) {
	# now add the features
	my($f) = new Stone;
	foreach (@$features) {
	    my($q) = $_->{'value'};
	    my($label) = _canonicalize($_->{'label'});
	    my($position) = $q=~m!^([^/\s]+)!;
	    my @qualifiers = $q=~m@/(\w+)=(.+?)(?=\"|/\w+=)@g;  # slower but ?better
	    my %qualifiers;
	    while (my($key,$value) = splice(@qualifiers,0,2)) {
	      $value =~ s/^\s*\"//; # trim off extra space and quotes
	      $value =~ s/\"\s*$//;
	      $value =~ s/^\s+//; # trim off extra space and quotes
	      $value =~ s/\s+$//;
	      $value =~ s/\s+//g if uc($key) eq 'TRANSLATION';  # get rid of spaces in protein translation
	      $qualifiers{_canonicalize($key)} = $value;
	    }
	    $f->insert($label=>new Stone('Position'=>$position,%qualifiers));
	}
	$stone->insert('Features',$f);
    }
}

# ----------------------------------------------------------------------------------------
# -------------------------- DEFINITION OF ACCESSOR OBJECTS ------------------------------
package GenbankAccessor;
use Carp;

sub new {
    my($class,@parameters) = @_;
    croak "GenbankAccessor::new:  Abstract class\n";
}

sub fetch_next {
    my($self) = @_;
    croak "GenbankAccessor::fetch_next: Abstract class\n";
}

sub DESTROY {
}

package Yank;
use strict;
use Carp;
use vars '@ISA';

@ISA=qw(GenbankAccessor);
my $YANK = $ENV{YANK} || Boulder::Genbank::YANK();

sub new {
    my($package,$param) = @_;
    croak "Yank::new(): need at least one Genbank acccession number" unless $param;
    croak "Yank::new(): yank executable not found" unless -x $YANK;
    $param->{fetch} ||= $param->{param};  # for backward compatibility
    $param->{fetch} || croak "Provide list of accession numbers to yank";
    my @accession = @{$param->{fetch}};
    my $tmpfile = "/usr/tmp/yank$$";
    open (TMP,">$tmpfile") || croak "Yank::new(): couldn't open tmpfile $tmpfile for write: $!";
    print TMP join("\n",@accession),"\n";
    close TMP;
    open(YANK,"$YANK < $tmpfile |") || croak "Yank::new(): couldn't open pipe from yank: $!";
    return bless {'tmpfile'=>$tmpfile,'fh'=>\*YANK},$package;
}

sub fetch_next {
    my($self) = @_;
    return undef unless $self->{'fh'};
    local($/) = "//\n";
    my($line);
    my($fh) = $self->{'fh'};
    chomp($line = <$fh>);
    return $line;
}

sub DESTROY {
    my($self) = shift;
    close $self->{'fh'} if $self->{'fh'};
    unlink $self->{'tmpfile'} if $self->{'tmpfile'}
}

package File;
use vars '@ISA';
use Symbol;
use Carp;

@ISA=qw(GenbankAccessor);

sub new {
    my($package,$param) = @_;
    my $path = $param->{-fetch} || $param->{-path} || $param->{-param};
    my $fh;
    if (!$path) {
      $fh = \*ARGV;
    } elsif (ref $path eq 'GLOB') {
      $fh = $path;
    } else {
      $fh = Symbol::gensym;
      open ($fh,$path) or croak "File::new(): couldn't open $path: $!";
    }
    return bless {'fh'=>$fh},$package;
}

sub fetch_next {
    my $self = shift;
    return undef unless $self->{'fh'};
    local($/)="//\n";
    my $line;
    my $fh = $self->{'fh'};
    chomp($line = <$fh>);
    return $line;
}

package Entrez;
use Carp;
use vars '@ISA';
use IO::Socket;

use constant PROTO => 'HTTP/1.0';
use constant CRLF  => "\r\n";
use constant MAX_ENTRIES => 19_000;

@ISA=qw(GenbankAccessor);

sub new {
    my($package,$param) = @_;
    croak "Entrez::new(): usage [list of accession numbers] or {args => values}" 
      unless $param;
    my $self = {};

    $self->{query}     = $param->{-query};
    $self->{accession} = $param->{-fetch} || $param->{-param};
    $self->{db}        = $param->{-db} || 'n';
    $self->{format}    = $param->{-format} || 'stone';

    croak "Must provide a 'query' or 'accession' argument" unless $self->{query} || $self->{accession} ;
    $self->{accession} = [ @{$self->{accession}} ]
      if $self->{accession} and ref $self->{accession}; # copy array to avoid munging caller's variable
    return bless $self,$package;
}

sub fetch_next {
    my $self = shift;

    # if any additional records are left, then return them
    if ($self->{'records'} && @{$self->{'records'}}) {
      my $data = shift @{$self->{'records'}};
      if ($data=~/\S/) {
	$self->_cleanup(\$data);
	return $data;
      } else {
	$self->{'records'} = [];
      }
    }

    my $format = $self->{format};

    local ($/) = $format eq 'fasta' ? "\n>" : "//\n";
    # if we have a socket open, then read a record
    if ($self->{'socket'}) {
      if (my $data = $self->_getline) {
	$self->_cleanup(\$data);
	return $data;
      }
    }

    die "Must provide either a list of accession numbers or an Entrez query"
      unless $self->{accession} || $self->{query};

    return unless $self->_request;

    my $data = $self->_getline;
    $self->_cleanup(\$data);
    return $data;
}

sub _cleanup {
  my ($self,$d) = @_;
  $$d =~ s/\A\s+//;
  $$d=~s!//\n$!!;
  return unless $self->{format} eq 'fasta';
  chomp $$d;
  substr($$d,0,0)='>' unless $$d =~/^>/;
}

sub _request {
  my $self = shift;
  my $format = $self->{format};
  my $sock = IO::Socket::INET->new(
				   PeerAddr => Boulder::Genbank::HOST,
				   PeerPort => 'http(80)',
				   Proto    => 'tcp'
				  );
  return unless $sock;

  # create the multipart form...
  my $db = $self->{'db'};
  my $boundary = '-' x 30 . int rand(10E14);
  my $name = 'Content-Disposition: form-data; name=';
  my %canned = ('db'     => $db,
		'FORMAT' => $format eq 'fasta' ? 1 : 0,
		'REQUEST_TYPE' => $self->{accession} ? 'LIST_OF_GIS' : 'ADVANCED_QUERY',
		'ORGNAME'      => '',
		'LIST_ORG'     => '(None)',
		'QUERY'        => "$self->{query}\r\n",
		'SAVETO'       => 'YES',
		'NOHEADER'     => 'YES');

  my @records = map {qq(Content-Disposition: form-data; name="$_"\r\n\r\n$canned{$_}\r\n)} keys %canned;

  if (my $a = $self->{accession}) {
    my @accessions = splice(@$a,0,MAX_ENTRIES);
    return unless @accessions;
    my $accessions = join "\n",@accessions;
    push @records,
      qq{Content-Disposition: form-data; name="UID"; filename="accession.txt"\r\nContent-type: text/plain\r\n\r\n$accessions\r\n};
  }

  my $content = "$boundary\r\n" . join("$boundary\r\n",@records) . "$boundary--\r\n";
  
  print $sock "POST ",Boulder::Genbank::BATCH_URI," ",PROTO,CRLF;
  print $sock "User-agent: Mozilla/5.0 [en] (PalmOS)",CRLF;
  print $sock "Content-Type: multipart/form-data; boundary=$boundary",CRLF;
  print $sock "Content-Length: ",length $content,CRLF,CRLF;

  print $sock $content;

  local($/) = CRLF . CRLF;

  my $header = $sock->getline;
  return unless $header;
  return unless $header =~ /^HTTP\/[\d.]+ 200/;

  $/ =  "\n";
  my $line = $sock->getline;

  # this handles the case of Batch Entrez complaining that we're trying to
  # get too many sequences at once!
  if ($line =~ /exceed limit/) {
    my @accessions;
    while ($_ = $sock->getline) {
      chomp;
      push @accessions,$_;
    }
    delete $self->{query};
    $self->{accession} = \@accessions;
    return $self->_request; # horrible recursion here!
  }
  $self->{bufferedline} = $line;
  if ($format eq 'fasta') {
    return unless $line =~ /^>/;
  } else { 
    return unless $line =~ /LOCUS/;
  }

  $self->{socket} = $sock;
  return 1;
}

sub _getline {
  my $l = $_[0]->{socket}->getline;
  if ($_[0]->{bufferedline}) {
    $l = "$_[0]->{bufferedline}$l";
    delete $_[0]->{bufferedline};
  }
  return $l;
}

1;

__END__

