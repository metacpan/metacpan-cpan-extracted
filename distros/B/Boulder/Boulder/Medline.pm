package Boulder::Medline;
#
use Boulder::Stream;
require Exporter;
@ISA = qw(Exporter Boulder::Stream);
@EXPORT = ();
@EXPORT_OK = ();
use Carp;
$VERSION=08061999;
use constant DEFAULT_MEDLINE_PATH => '/data/medline/medline.txt';

=head1 NAME

Boulder::Medline - Fetch Medline data records as parsed Boulder Stones

=head1 SYNOPSIS

  # parse a file of Medline records
  $ml = new Boulder::Medline(-accessor=>'File',
                             -param => '/data/medline/medline.txt');
  while (my $s = $ml->get) {
    print $s->Identifier;
    print $s->Abstract;
  }

  # parse flatfile  yourself
  open (ML,"/data/medline/medline.txt");
  local $/ = "*RECORD*";
  while (<ML>) {
     my $s = Boulder::Medline->parse($_);
     # etc.
  }

=head1 DESCRIPTION

Boulder::Medline provides retrieval and parsing services for Medline records

Boulder::Medline provides retrieval and parsing services for NCBI
Medline records.  It returns Medline entries in L<Stone>
format, allowing easy access to the various fields and values.
Boulder::Medline is a descendent of Boulder::Stream, and provides a
stream-like interface to a series of Stone objects.

Access to Medline is provided by one I<accessors>, which
give access to  local Medline database.  When you
create a new Boulder::Medline stream, you provide the
accessors, along with accessor-specific parameters that control what
entries to fetch.  The accessors is:

=over 2

=item File

This provides access to local Medline entries by reading from a flat file.
The stream will return a Stone corresponding to each of the entries in 
the file, starting from the top of the file and working downward.  The 
parameter is the path to the local file.

=back

It is also possible to parse a single Medline entry from a text string 
stored in a scalar variable, returning a Stone object.

=head2 Boulder::Medline methods

This section lists the public methods that the I<Boulder::Medline>
class makes available.

=over 4

=item new()

   # Local fetch via File
   $ml=new Boulder::Medline(-accessor  =>  'File',
                            -param     =>  '/data/medline/medline.txt');

The new() method creates a new I<Boulder::Medline> stream on the
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
Medline entries from.

=item get()

The get() method is inherited from I<Boulder::Stream>, and simply
returns the next parsed Medline Stone, or undef if there is nothing
more to fetch.  It has the same semantics as the parent class,
including the ability to restrict access to certain top-level tags.

=item put()

The put() method is inherited from the parent Boulder::Stream class,
and will write the passed Stone to standard output in Boulder format.
This means that it is currently not possible to write a
Boulder::Medline object back into Medline flatfile form.

=back

=head1 OUTPUT TAGS

The tags returned by the parsing operation are taken from the MEDLARS definition file
MEDDOC.DOC


=head2 Top-Level Tags

These are tags that appear at the top level of the parsed Medline entry.

=over 4

ABSTRACT
ABSTRACT AUTHOR
ADDRESS
AUTHOR
CALL NUMBER
CAS REGISTRY/EC NUMBER
CLASS UPDATE DATE
COMMENTS
COUNTRY
DATE OF ENTRY
DATE OF PUBLICATION
ENGLISH ABSTRACT INDICATOR
ENTRY MONTH
GENE SYMBOL
ID NUMBER
INDEXING PRIORITY
ISSN
ISSUE/PART/SUPPLEMENT
JOURNAL SUBSET
JOURNAL TITLE CODE
LANGUAGE
LAST REVISION DATE
MACHINE-READABLE IDENTIFIER
MeSH HEADING
NO-AUTHOR INDICATOR
NOT FOR PUBLICATION
NUMBER OF REFERENCES
PAGINATION
PERSONAL NAME AS SUBJECT
PUBLICATION TYPE
RECORD ORIGINATOR
SECONDARY SOURCE ID
SPECIAL LIST INDICATOR
TITLE
TITLE ABBREVIATION
TRANSLITERATED/VERNACULAR  TITLE
UNIQUE IDENTIFIER
VOLUME ISSUE

=item Identifier

The Medline identifier of this entry.  Identifier is a single-value tag.

Example:
       
      my $identifierNo = $s->Identifier;

=item Title

The Medline title for this entry.

Example:
      my $titledef=$s->Title;

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
  for ($i=0; $i<=$#recordlines; $i++) {
   $line=@recordlines[$i];
   if       ($line=~/^UI/) { ($junk,$ui)=split(/  \- /,$line);$label="ID";
  }elsif ($line=~/^DA/) { ($junk,$da)=split(/  \- /,$line);$label="DA";
  }elsif ($line=~/^PMID/) { ($junk,$pmid)=split(/\- /,$line);$label="PMID";
  }elsif ($line=~/^AD/) { ($junk,$ad)=split(/  \- /,$line);$label="AD";
  }elsif ($line=~/^SO/) { ($junk,$so)=split(/  \- /,$line);$label="SO";
  }elsif ($line=~/^EM/) { ($junk,$em)=split(/  \- /,$line);$label="EM";
  }elsif ($line=~/^AA/) { ($junk,$aa)=split(/  \- /,$line);$label="AA";
  }elsif ($line=~/^JC/) { ($junk,$jc)=split(/  \- /,$line);$label="JC";
  }elsif ($line=~/^VI/) { ($junk,$vi)=split(/  \- /,$line);$label="VI";
  }elsif ($line=~/^IP/) { ($junk,$ip)=split(/  \- /,$line);$label="IP";
  }elsif ($line=~/^CY/) { ($junk,$cj)=split(/  \- /,$line);$label="CY";
  }elsif ($line=~/^DP/) { ($junk,$dp)=split(/  \- /,$line);$label="DP";
  }elsif ($line=~/^IS/) { ($junk,$is)=split(/  \- /,$line);$label="IS";
  }elsif ($line=~/^TA/) { ($junk,$ta)=split(/  \- /,$line);$label="TA";
  }elsif ($line=~/^PG/) { ($junk,$pg)=split(/  \- /,$line);$label="PG";
  }elsif ($line=~/^TI/) { ($junk,$ti)=split(/  \- /,$line);$label="TI";
  }elsif ($line=~/^AB/) { ($junk,$ab)=split(/  \- /,$line);$label="AB";
  }elsif ($line=~/^CA/) { ($junk,$ca)=split(/  \- /,$line);$label="CA";
  }elsif ($line=~/^CU/) { ($junk,$cu)=split(/  \- /,$line);$label="CU";
  }elsif ($line=~/^CY/) { ($junk,$cy)=split(/  \- /,$line);$label="CY";
  }elsif ($line=~/^DP/) { ($junk,$dp)=split(/  \- /,$line);$label="DP";
  }elsif ($line=~/^EA/) { ($junk,$ea)=split(/  \- /,$line);$label="EA";
  }elsif ($line=~/^PY/) { ($junk,$py)=split(/  \- /,$line);$label="PY";
  }elsif ($line=~/^LR/) { ($junk,$lr)=split(/  \- /,$line);$label="LR";
  }elsif ($line=~/^MRI/) { ($junk,$mri)=split(/  \- /,$line);$label="MRI";
  }elsif ($line=~/^NI/) { ($junk,$ni)=split(/  \- /,$line);$label="NI";
  }elsif ($line=~/^NP/) { ($junk,$np)=split(/  \- /,$line);$label="NP";
  }elsif ($line=~/^RF/) { ($junk,$rf)=split(/  \- /,$line);$label="RF";
  }elsif ($line=~/^PG/) { ($junk,$pg)=split(/  \- /,$line);$label="PG";
  }elsif ($line=~/^LI/) { ($junk,$li)=split(/  \- /,$line);$label="LI";
  }elsif ($line=~/^TT/) { ($junk,$tt)=split(/  \- /,$line);$label="TT";
# following are records which may appear multiple times 
  }elsif ($line=~/^RO/) { ($junk,$ro_tmp)=split(/  \- /,$line);$label="RO";$ro.=$ro_tmp."\n";
  }elsif ($line=~/^RN/) { ($junk,$rn_tmp)=split(/  \- /,$line);$label="RN";$rn.=$rn_tmp."\n";
  }elsif ($line=~/^LA/) { ($junk,$la_tmp)=split(/  \- /,$line);$label="LA";$la.=.$la_tmp."\n";
  }elsif ($line=~/^SB/) { ($junk,$sb_tmp)=split(/  \- /,$line);$label="SB";$sb.=$sb_tmp."\n";
  }elsif ($line=~/^GS/) { ($junk,$gs_tmp)=split(/  \- /,$line);$label="GS";$gs.=$gs_tmp."\n";
  }elsif ($line=~/^MH/) { ($junk,$mh_tmp)=split(/  \- /,$line);$label="MH";$mh.=$mh_tmp."\n";
  }elsif ($line=~/^PT/) { ($junk,$pt_tmp)=split(/  \- /,$line);$label="PT";$pt.=$pt_tmp."\n";
  }elsif ($line=~/^AU/) { ($junk,$au_tmp)=split(/  \- /,$line);$label="AU"; $au.=$au_tmp."\n";
  }elsif ($line=~/^PS/) { ($junk,$ps_tmp)=split(/  \- /,$line);$label="PS";$ps.=$ps_tmp."\n";
  }elsif ($line=~/^CM/) { ($junk,$cm_tmp)=split(/  \- /,$line);$label="CM";$cm.=$cm_tmp."\n";
  }elsif ($line=~/^SI/) { ($junk,$si_tmp)=split(/  \- /,$line);$label="SI";$si.=$si_tmp."\n";
  }elsif ($line=~/^ID/) { ($junk,$id_tmp)=split(/  \- /,$line);$label="ID";$id.=$id_tmp."\n";
  } else {
# handle multiline records with empty header
    if      ($label=~/TI/) {
     $ti.=$line;
    } elsif ($label=~/AB/) {
     $ab.=$line;
    } else { 
    }
   }
  }
# First add the single field records
  $self->_addToStone('Identifier',$ui,$s,\%ok);
  $self->_addToStone('Title',$ti,$s,\%ok);
  $self->_addToStone('Abstract',$ab,$s,\%ok);
  $self->_addToStone('AbstractAuthor',$aa,$s,\%ok);
  $self->_addToStone('Address',$ab,$s,\%ok);
  $self->_addToStone('CallNumber',$ca,$s,\%ok);
  $self->_addToStone('ClassUpdateDate',$cu,$s,\%ok);
  $self->_addToStone('Country',$cy,$s,\%ok);
  $self->_addToStone('DateOfEntry',$da,$s,\%ok);
  $self->_addToStone('DateOfPublication',$dp,$s,\%ok);
  $self->_addToStone('EnglishAbstractIndicator',$ea,$s,\%ok);
  $self->_addToStone('EntryMonth',$em,$s,\%ok);
  $self->_addToStone('IndexingPriority',$py,$s,\%ok);
  $self->_addToStone('ISSN',$is,$s,\%ok);
  $self->_addToStone('IssuePartSupplement',$is,$s,\%ok);
  $self->_addToStone('JournalTitleCode',$jc,$s,\%ok);
  $self->_addToStone('LastRevisionDate',$lr,$s,\%ok);
  $self->_addToStone('MachineReadableIdentifier',$mri,$s,\%ok);
  $self->_addToStone('NoAuthorIndicator',$ni,$s,\%ok);
  $self->_addToStone('NotForPublication',$np,$s,\%ok);
  $self->_addToStone('NumberOfReferences',$rf,$s,\%ok);
  $self->_addToStone('Pagination',$pg,$s,\%ok);
  $self->_addToStone('SpecialListIndicator',$li,$s,\%ok);
  $self->_addToStone('TitleAbbreviation',$ta,$s,\%ok);
  $self->_addToStone('TranslitteratedVernacularTitle',$tt,$s,\%ok);
  $self->_addToStone('VolumeIssue',$vi,$s,\%ok);

#Then handle all other fields which may have multiple values
     (@TMPs)=split(/\n/,$au);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('Author',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$rn);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('CASRegistryECNumber',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$cm);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('Comments',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$gs);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('GeneSymbol',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$id);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('IDNumber',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$sb);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('JournalSubset',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$la);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('Language',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$mh);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('MeSHHeading',$aui,$s,\%ok);
     }

     (@TMPs)=split(/\n/,$ps);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('PersonalNameAsSubject',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$pt);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('PublicationType',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$ro);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('RecordOriginator',$aui,$s,\%ok);
     }
     (@TMPs)=split(/\n/,$si);
     foreach $aui  (@TMPs) {
      $aui=~s/\n//g;
      $self->_addToStone('SecondarySourceId',$aui,$s,\%ok);
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
}



# -------------------------- DEFINITION OF ACCESSOR OBJECTS ------------------------------
#<LIGT>
#only name changes for avoid namespace collisions
#</LIGT>
package MedlineAccessor;
use Carp;

sub new {
    my($class,@parameters) = @_;
    croak "MedlineAccessor::new:  Abstract class\n";
}

sub fetch_next {
    my($self) = @_;
    croak "MedlineAccessor::fetch_next: Abstract class\n";
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
@ISA=qw(MedlineAccessor);
$DEFAULT_PATH = Boulder::Medline::DEFAULT_MEDLINE_PATH();

#<LIGT>
# Following, removed the search for the string locus in the file
#   as validation that the input be compliant with parser
#</LIGT>
sub new {
    my($package,$path) = @_;
    $path = $DEFAULT_PATH unless $path;
    open (ML,$path) or croak "File::new(): couldn't open $path: $!";
    # read the junk at the beginning
    my $found; $found++;
    croak "File::new(): $path doesn't look like a Medline flat file"
	unless $found;
    $_ = <ML>;
    return bless {'fh'=>ML},$package;
}

#<LIGT>
# Following, changed the record separator
#</LIGT>
sub fetch_next {
    my $self = shift;
    return undef unless $self->{'fh'};
    local($/)="*RECORD*\n";
    my($line);
    my($fh) = $self->{'fh'};
    chomp($line = <$fh>);
    return $line;
}

1;

__END__

