package Boulder::LocusLink;
use Boulder::Stream;
require Exporter;
@ISA = qw(Exporter Boulder::Stream);
@EXPORT = ();
@EXPORT_OK = ();
use Carp;
$VERSION=1.00;
use constant DEFAULT_LOCUSLINK_PATH => '/data/LocusLink/LL_tmpl';

=head1 NAME

Boulder::LocusLink - Fetch LocusLink data records as parsed Boulder Stones

=head1 SYNOPSIS

  # parse a file of LocusLink records
  $ll = new Boulder::LocusLink(-accessor=>'File',
                             -param => '/home/data/LocusLink/LL_tmpl');
  while (my $s = $ll->get) {
    print $s->Identifier;
    print $s->Gene;
  }

  # parse flatfile records yourself
  open (LL,"/home/data/LocusLink/LL_tmpl");
  local $/ = "*RECORD*";
  while (<LL>) {
     my $s = Boulder::LocusLink->parse($_);
     # etc.
  }

=head1 DESCRIPTION

Boulder::LocusLink provides retrieval and parsing services for LocusLink records

Boulder::LocusLink provides retrieval and parsing services for NCBI
LocusLink records.  It returns Unigene entries in L<Stone>
format, allowing easy access to the various fields and values.
Boulder::LocusLink is a descendent of Boulder::Stream, and provides a
stream-like interface to a series of Stone objects.

Access to LocusLink is provided by one I<accessors>, which
give access to  local LocusLink database.  When you
create a new Boulder::LocusLink stream, you provide the
accessors, along with accessor-specific parameters that control what
entries to fetch.  The accessors is:

=over 2

=item File

This provides access to local LocusLink entries by reading from a flat file
(typically Hs.dat file downloadable from NCBI's Ftp site).
The stream will return a Stone corresponding to each of the entries in 
the file, starting from the top of the file and working downward.  The 
parameter is the path to the local file.

=back

It is also possible to parse a single LocusLink entry from a text string 
stored in a scalar variable, returning a Stone object.

=head2 Boulder::LocusLink methods

This section lists the public methods that the I<Boulder::LocusLink>
class makes available.

=over 4

=item new()

   # Local fetch via File
   $ug=new Boulder::LocusLink(-accessor  =>  'File',
                            -param     =>  '/data/LocusLink/Hs.dat');

The new() method creates a new I<Boulder::LocusLink> stream on the
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
LocusLink entries from.

=item get()

The get() method is inherited from I<Boulder::Stream>, and simply
returns the next parsed LocusLink Stone, or undef if there is nothing
more to fetch.  It has the same semantics as the parent class,
including the ability to restrict access to certain top-level tags.

=item put()

The put() method is inherited from the parent Boulder::Stream class,
and will write the passed Stone to standard output in Boulder format.
This means that it is currently not possible to write a
Boulder::LocusLink object back into LocusLink flatfile form.

=back

=head1 OUTPUT TAGS

The tags returned by the parsing operation are taken from the names shown in the Flat file
Hs.dat since no better description of them is provided yet by the database source producer.

=head2 Top-Level Tags

These are tags that appear at the top level of the parsed LocusLink
entry.

=over 4

=item Identifier

The LocusLink identifier of this entry.  Identifier is a single-value tag.

Example:
       
      my $identifierNo = $s->Identifier;

=item Current_locusid

If a locus has been merged with another, the Current_locusid contains the
previous LOCUSID line (A bit confusing, shall be called "previous_locusid",
but this is defined in NCBI README File ... ).

Example:
      my $prevlocusid=$s->Current_locusid;

=item Organism
Source species ased on NCBI's Taxonomy

Example:
      my $theorganism=$s->Organism;

=item Status
Type of reference sequence record. If "PROVISIONAL"
then means that is generated automatically from existing Genbank record and
information stored in the LocusLink database, no curation. If "REVIEWED"
than it means that is generated from the most representative complete
GenBank sequence or merge of GenBank sequenes and from information stored in
the LocusLink database

Example:
      my $thestatus=$s->Status;

=item LocAss
Here comes a complex record ... made up of
        LOCUS_STRING, 
	NM         The value in the LOCUS field of the RefSeq record , 
	NP         The RefSeq accession number for an mRNA record, 
	PRODUCT    The name of the produc tof this transcript, 
	TRANSVAR   a variant-specific description, 
	ASSEMBLY   The Genbank accession used to assemble the refseq record

Example:
      my $theprod=$s->LocAss->Product;

=item AccProt
Here comes a complex record ... made up of
	ACCNUM	     Nucleotide sequence accessio number
        TYPE         e=EST, m=mRNA, g=Genomic
        PROT         set of PID values for the coding region or regions
                     annotated on the nucleotide record. The first value
                     is the PID (an integer or null), then either MMDB or na, 
                     separated from the PID by a |. If MMDB is present, it 
                     indicates there are structur edata available for a protein
                     related to the protein referenced by the PID
Example:
      my $theprot=$s->AccProt->Prot;

=item OFFICIAL_SYMBOL
 The symbol used for gene reports, validated by the appropriate nomenclature
committee

=item PREFERRED_SYMBOL
 Interim symbol used for display

=item OFFICIAL_GENE_NAME
The gene description used for gene reports validate by the appropriate nomenclatur eommittee. If the symbol is official, the gene name will be official. No records will have both official and interim nomenclature.

=item PREFERRED_GENE_NAME
 Interim used for display

=item PREFERRED_PRODUCT
 The name of the product used in the RefSeq record

=item ALIAS_SYMBOL
 Other symbols associated with this gene

=item ALIAS_PROT
 Other protein names associated with this gene

=item PhenoTable
   A complex record made up of
   Phenotype
   Phenotype_ID

=item SUmmary

=item Unigene

=item Omim

=item Chr

=item Map

=item STS

=item ECNUM

=item ButTable
 BUTTON
 LINK

=item DBTable
 DB_DESCR
 DB_LINK

=item PMID
 a subset of publications associated with this locus with the link being the 
 PubMed unique identifier comma separated

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
  undef $LocusLinkid, $curlocusid, $organism, $status, $locusstring;
  undef @locass;
  foreach $line  (@recordlines) {
    if      ($line=~/^LOCUSID:/) {
     ($key,$LocusLinkid)=split(/\s+/,$line);
      $self->_addToStone('Identifier',$LocusLinkid,$s,\%ok);
    } elsif ($line=~/^CURRENT_LOCUSID/) {
     ($key,$curlocusid)=split(/\s+/,$line);
     $self->_addToStone('Current_locusid',$curlocusid,$s,\%ok);
    } elsif ($line=~/^ORGANISM/) {
     ($key,$organism)=split(/\s+/,$line);
     $self->_addToStone('Organism',$organism,$s,\%ok);
    } elsif ($line=~/^STATUS/) {
     ($key,$status)=split(/\s+/,$line);
     $self->_addToStone('Status',$status,$s,\%ok);
# special case for the LOCUS_STRING .. ASSEMBLY table
    } elsif ($line=~/^LOCUS_STRING/..$line=~/^ASSEMBLY/) {
      if ($line=~/^LOCUS_STRING:/) {
       undef @locass;
       ($key,$locusstring)=split(/\s+/,$line);
       $locass= {'label'=>'LOCUS_STRING','value'=>$locusstring};
       push(@locass,$locass);
      }
      if ($line=~/^NM:/) { 
       ($key,$nm)=split(/\s+/,$line); 
       $locass= {'label'=>'NM','value'=>$nm};
       push(@locass,$locass);
      } 
      if ($line=~/^NP:/) { 
       ($key,$np)=split(/\s+/,$line); 
       $locass= {'label'=>'NP','value'=>$np};
       push(@locass,$locass);
      } 
      if ($line=~/^PRODUCT:/) {
       ($key,$product)=split(/\s+/,$line);
       $locass= {'label'=>'PRODUCT','value'=>$product};
       push(@locass,$locass);
      } 
      if ($line=~/^TRANSVAR:/) {
       ($key,$transvar)=split(/\s+/,$line);
       $locass= {'label'=>'TRANSVAR','value'=>$transvar};
       push(@locass,$locass);
      } 
      if ($line=~/^ASSEMBLY:/) {
       ($key,$assembly)=split(/\s+/,$line);
       $locass= {'label'=>'ASSEMBLY','value'=>$assembly};
       push(@locass,$locass);
       $self->_addLocassToStone(\@locass,_trim($'),$s,\%ok);
       next;
      } 
# special case for the ACCNUM .. SYMBOL table
    } elsif ($line=~/^ACCNUM/..$line=~/_SYMBOL:/) {
      if ($line=~/^ACCNUM:/) {
       undef @accsym;
       ($key,$accnum)=split(/\s+/,$line);
       $accsym= {'label'=>'ACCNUM','value'=>$accnum};
       push(@accsym,$accsym);
      }
      if ($line=~/^TYPE:/) {
       ($key,$type)=split(/\s+/,$line);
       if ($type=~/e/) { 
         $type="EST";
       } elsif ($type=~/m/) { 
         $type="mRNA"; 
       } elsif ($type=~/g/) {
         $type="genomic"; 
       }
       $accsym= {'label'=>'TYPE','value'=>$type};
       push(@accsym,$accsym);
      } 
      if ($line=~/^PROT:/) {
       ($key,$prot)=split(/\s+/,$line);
       $accsym= {'label'=>'PROT','value'=>$prot};
       push(@accsym,$accsym);
      }
      if ($line=~/_SYMBOL:/) {
       $self->_addAccSymToStone(\@accsym,_trim($'),$s,\%ok);
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone($key,$value,$s,\%ok);
      } 
   } elsif ($line=~/_GENE_NAME:/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone($key,$value,$s,\%ok);
   } elsif ($line=~/^PREFERRED_PRODUCT:/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone($key,$value,$s,\%ok);
   } elsif ($line=~/^ALIAS_SYMBOL:/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone($key,$value,$s,\%ok);
   } elsif ($line=~/^ALIAS_PROT:/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone($key,$value,$s,\%ok);
# special case for the PHENOTYPE table
    } elsif ($line=~/^PHENOTYPE/..$line=~/PHENOTYPE_ID:/) {
      if ($line=~/^PHENOTYPE:/) {
       undef @pheno;
       ($key,$pheno)=split(/\s+/,$line);
       $phenol= {'label'=>'PHENOTYPE','value'=>$pheno};
       push(@phenol,$phenol);
      }
      if ($line=~/^PHENOTYPE_ID:/) {
       ($key,$phenoid)=split(/\s+/,$line);
       $phenol= {'label'=>'PHENOTYPE_ID','value'=>$phenoid};
       push(@phenol,$phenol);
       $self->_addPhenotypeToStone(\@phenol,_trim($'),$s,\%ok);
       next;
      } 
   } elsif ($line=~/^SUMMARY:/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone($key,$value,$s,\%ok);
   } elsif ($line=~/^UNIGENE:/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone($key,$value,$s,\%ok);
   } elsif ($line=~/^OMIM:/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone($key,$value,$s,\%ok);
   } elsif ($line=~/^CHR:/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone('Chromosome',$value,$s,\%ok);
   } elsif ($line=~/^MAP:/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone('Cytogenetic_location',$value,$s,\%ok);
   } elsif ($line=~/^STS/) {
       undef @ststab,@stsraw,$stsr,$markname,$chrnum,$sts_id,$d_seg,$a;
       ($key,$stsr)=split(/\s+/,$line);
       ($markname,$chrnum,$sts_id,$d_seg)=split(/\|/,$stsr);
       $a= {'label'=>'Marker_Name','value'=>$markname};
       push(@ststab,$a);
       $a= {'label'=>'Chromosome_Number','value'=>$chrnum};
       push(@ststab,$a);
       $a= {'label'=>'Sts_id','value'=>$sts_id};
       push(@ststab,$a);
       $a= {'label'=>'D_Segment','value'=>$d_seg};
       push(@ststab,$a);
       $self->_addStsToStone(\@ststab,_trim($'),$s,\%ok);
   } elsif ($line=~/^ECNUM/) {
       ($key,$value)=split(/:\s+/,$line);
       $self->_addToStone('EC',$value,$s,\%ok);
   } elsif ($line=~/^BUTTON:/..$line=~/^LINK:/) {
      if ($line=~/^BUTTON:/) {
       undef @pheno;
       ($key,$pheno)=split(/\s+/,$line);
       $phenol= {'label'=>'BUTTON','value'=>$pheno};
       push(@phenol,$phenol);
      }
      if ($line=~/^LINK:/) {
       ($key,$phenoid)=split(/\s+/,$line);
       $phenol= {'label'=>'LINK','value'=>$phenoid};
       push(@phenol,$phenol);
       $self->_addButtonToStone(\@phenol,_trim($'),$s,\%ok);
       next;
      } 
   } elsif ($line=~/^DB_DESCR:/..$line=~/^DB_LINK:/) {
      if ($line=~/^DB_DESCR:/) {
       undef @pheno;
       ($key,$pheno)=split(/\s+/,$line);
       $phenol= {'label'=>'DB_DESCR','value'=>$pheno};
       push(@phenol,$phenol);
      }
      if ($line=~/^DB_LINK:/) {
       ($key,$phenoid)=split(/\s+/,$line);
       $phenol= {'label'=>'DB_LINK','value'=>$phenoid};
       push(@phenol,$phenol);
       $self->_addDBToStone(\@phenol,_trim($'),$s,\%ok);
       next;
      } 
   } elsif ($line=~/^PMID:/) {
       ($key,$value)=split(/:\s+/,$line);
       (@medlinearray)=split(/\,/,$value);
       foreach $medlineid (@medlinearray) {
         $self->_addToStone('MedlineID',$medlineid,$s,\%ok);
       }
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

sub _addLocassToStone {
    my($self,$features,$basecount,$stone,$ok) = @_;
    if (!%{$ok} || $ok->{'LocAss'}) {
	# now add the features
	my($f) = new Stone;
	my %qualifiers;
	foreach (@$features) {
 	  my($q) = $_->{'value'};
	  my($label) = _canonicalize($_->{'label'});
          $f->insert($label,$q);
	}
        $stone->insert('LocAss',$f);
    }
}

sub _addAccSymToStone {
    my($self,$features,$basecount,$stone,$ok) = @_;
    if (!%{$ok} || $ok->{'AccSym'}) {
	# now add the features
	my($f) = new Stone;
	my %qualifiers;
	foreach (@$features) {
 	  my($q) = $_->{'value'};
	  my($label) = _canonicalize($_->{'label'});
          $f->insert($label,$q);
	}
        $stone->insert('AccSym',$f);
    }
}

sub _addPhenotypeToStone {
    my($self,$features,$basecount,$stone,$ok) = @_;
    if (!%{$ok} || $ok->{'PhenoTable'}) {
	# now add the features
	my($f) = new Stone;
	my %qualifiers;
	foreach (@$features) {
 	  my($q) = $_->{'value'};
	  my($label) = _canonicalize($_->{'label'});
          $f->insert($label,$q);
	}
        $stone->insert('PhenoTable',$f);
    }
}

sub _addStsToStone {
    my($self,$features,$basecount,$stone,$ok) = @_;
    if (!%{$ok} || $ok->{'StsTable'}) {
	# now add the features
	my($f) = new Stone;
	my %qualifiers;
	foreach (@$features) {
 	  my($q) = $_->{'value'};
	  my($label) = _canonicalize($_->{'label'});
          $f->insert($label,$q);
	}
        $stone->insert('StsTable',$f);
    }
}

sub _addButtonToStone {
    my($self,$features,$basecount,$stone,$ok) = @_;
    if (!%{$ok} || $ok->{'ButtonTable'}) {
	# now add the features
	my($f) = new Stone;
	my %qualifiers;
	foreach (@$features) {
 	  my($q) = $_->{'value'};
	  my($label) = _canonicalize($_->{'label'});
          $f->insert($label,$q);
	}
        $stone->insert('ButtonTable',$f);
    }
}

sub _addDBToStone {
    my($self,$features,$basecount,$stone,$ok) = @_;
    if (!%{$ok} || $ok->{'DBTable'}) {
	# now add the features
	my($f) = new Stone;
	my %qualifiers;
	foreach (@$features) {
 	  my($q) = $_->{'value'};
	  my($label) = _canonicalize($_->{'label'});
          $f->insert($label,$q);
	}
        $stone->insert('DBTable',$f);
    }
}
# -------------------------- DEFINITION OF ACCESSOR OBJECTS ------------------------------
#<LIGT>
#only name changes for avoid namespace collisions
#</LIGT>
package LocusLinkAccessor;
use Carp;

sub new {
    my($class,@parameters) = @_;
    croak "LocusLinkAccessor::new:  Abstract class\n";
}

sub fetch_next {
    my($self) = @_;
    croak "LocusLinkAccessor::fetch_next: Abstract class\n";
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
@ISA=qw(LocusLinkAccessor);
$DEFAULT_PATH = Boulder::LocusLink::DEFAULT_LOCUSLINK_PATH();

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
    croak "File::new(): $path doesn't look like a LocusLink flat file"
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
    local($/)=">>";
    my($line);
    my($fh) = $self->{'fh'};
    chomp($line = <$fh>);
    return $line;
}

1;

__END__

