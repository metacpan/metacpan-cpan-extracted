package Boulder::Omim;
#
use Boulder::Stream;
require Exporter;
@ISA = qw(Exporter Boulder::Stream);
@EXPORT = ();
@EXPORT_OK = ();
use Carp;
$VERSION=1.01;
use constant DEFAULT_OMIM_PATH => '/data/omim/omim.txt';

=head1 NAME

Boulder::Omim - Fetch Omim data records as parsed Boulder Stones

=head1 SYNOPSIS

  # parse a file of Omim records
  $om = new Boulder::Omim(-accessor=>'File',
                             -param => '/data/omim/omim.txt');
  while (my $s = $om->get) {
    print $s->Identifier;
    print $s->Text;
  }

  # parse flatfile records yourself
  open (OM,"/data/omim/omim.txt");
  local $/ = "*RECORD*";
  while (<OM>) {
     my $s = Boulder::Omim->parse($_);
     # etc.
  }

=head1 DESCRIPTION

Boulder::Omim provides retrieval and parsing services for OMIM records

Boulder::Omim provides retrieval and parsing services for NCBI
Omim records.  It returns Omim entries in L<Stone>
format, allowing easy access to the various fields and values.
Boulder::Omim is a descendent of Boulder::Stream, and provides a
stream-like interface to a series of Stone objects.

Access to Omim is provided by one I<accessors>, which
give access to  local Omim database.  When you
create a new Boulder::Omim stream, you provide the
accessors, along with accessor-specific parameters that control what
entries to fetch.  The accessors is:

=over 2

=item File

This provides access to local Omim entries by reading from a flat file
(typically omim.txt file downloadable from NCBI's Ftp site).
The stream will return a Stone corresponding to each of the entries in 
the file, starting from the top of the file and working downward.  The 
parameter is the path to the local file.

=back

It is also possible to parse a single Omim entry from a text string 
stored in a scalar variable, returning a Stone object.

=head2 Boulder::Omim methods

This section lists the public methods that the I<Boulder::Omim>
class makes available.

=over 4

=item new()

   # Local fetch via File
   $om=new Boulder::Omim(-accessor  =>  'File',
                            -param     =>  '/data/omim/omim.txt');

The new() method creates a new I<Boulder::Omim> stream on the
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
Omim entries from.

=item get()

The get() method is inherited from I<Boulder::Stream>, and simply
returns the next parsed Omim Stone, or undef if there is nothing
more to fetch.  It has the same semantics as the parent class,
including the ability to restrict access to certain top-level tags.

=item put()

The put() method is inherited from the parent Boulder::Stream class,
and will write the passed Stone to standard output in Boulder format.
This means that it is currently not possible to write a
Boulder::Omim object back into Omim flatfile form.

=back

=head1 OUTPUT TAGS

The tags returned by the parsing operation are taken from the names shown in the network
Entrez interface to Omim.

=head2 Top-Level Tags

These are tags that appear at the top level of the parsed Omim
entry.

=over 4

=item Identifier

The Omim identifier of this entry.  Identifier is a single-value tag.

Example:
       
      my $identifierNo = $s->Identifier;

=item Title

The Omim title for this entry.

Example:
      my $titledef=$s->Title;

=item Text
The Text of this Omim entry

Example:
      my $thetext=$s->Text;

=item Mini
The text condensed version, also called "Mini" in Entrez interface

Example:
      my $themini=$s->Mini;

=item SeeAlso
References to other relevant work.

Example:
      my $thereviews=$s->Reviews;

=item CreationDate
This field contains the name of the person who originated the initial entry in OMIM and the date
it appeared in the database. The entry may have been subsequently added to, edited, or totally
rewritten by others, and their attribution is listed in the CONTRIBUTORS field.

Example:
      my $theCreation=$s->CreationDate;

=item Contributors
This field contains a list, in chronological order, of the persons who have contributed significantly
to the content of the MIM entry. The name is followed by "updated", "edited" or "re-created".

Example:
      my @theContributors=$s->Contributors;

=item History
This field contains the edit history of this record, with an identifier and a date in which minor changes
had been performed on the record.

Example:
      my @theHistory=$s->History;

=item References
The references cited in the entry.
Example:
      my @theReferences=$s->References;

=item ClinicalSynopsis
The content of the Clinical Synopsis data field.
Example:
      my @theClinicalSynopsis=$s->ClinicalSynopsis;

=item AllelicVariants
The Allelic Variants
Example:
      my @theAllelicVariants=$s->AllelicVariants;

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
   if      ($line=~/\*FIELD\* NO/) {
    $label="ID"; $i++; $omimid=@recordlines[$i];
   } elsif ($line=~/\*FIELD\* TI/) {
    $label="TI"; 
   } elsif ($line=~/\*FIELD\* TX/) {
    $label="TX"; 
   } elsif ($line=~/\*FIELD\* RF/) {
    $label="RF"; 
   } elsif ($line=~/\*FIELD\* CS/) {
    $label="CS"; 
   } elsif ($line=~/\*FIELD\* CD/) {
    $label="CD"; 
   } elsif ($line=~/\*FIELD\* ED/) {
    $label="ED"; 
   } elsif ($line=~/\*FIELD\* AV/) {
    $label="AV"; 
   } elsif ($line=~/\*FIELD\* SA/) {
    $label="SA"; 
   } elsif ($line=~/\*FIELD\* CN/) {
    $label="CN"; 
   } elsif ($line=~/\*FIELD\* MN/) {
    $label="MN";
   } else {
    if      ($label=~/TI/) {
     $ti{$omimid}.=$line;
    } elsif ($label=~/TX/) {
     $tx{$omimid}.=$line;
    } elsif ($label=~/RF/) {
     $rf{$omimid}.=$line."\n";
    } elsif ($label=~/CS/) {
     $cs{$omimid}.=$line."\n";
    } elsif ($label=~/CD/) {
     $cd{$omimid}.=$line."\n";
    } elsif ($label=~/ED/) {
     $ed{$omimid}.=$line."\n";
    } elsif ($label=~/AV/) {
      $av{$omimid}.=$line."\n";
    } elsif ($label=~/SA/) {
     $sa{$omimid}.=$line;
    } elsif ($label=~/CN/) {
     $cn{$omimid}.=$line."\n";
    } elsif ($label=~/MN/) {
     $mn{$omimid}.=$line;
    } else { 
    }
   }
  }
  if (defined($omimid)) {
# First add the single field records
  $self->_addToStone('Identifier',$omimid,$s,\%ok);
  $self->_addToStone('Title',$ti{$omimid},$s,\%ok);
  $self->_addToStone('Text',$tx{$omimid},$s,\%ok);
  $self->_addToStone('Mini',$mn{$omimid},$s,\%ok);
  $self->_addToStone('SeeAlso',$sa{$omimid},$s,\%ok);
  $self->_addToStone('CreationDate',$cd{$omimid},$s,\%ok);
#Then handle all other fields which may have multiple values
     (@EDs)=split(/\n/,$ed{$omimid});
     foreach $edi  (@EDs) {
      $edi=~s/\n//g;
      $self->_addToStone('History',$edi,$s,\%ok);
     }
#
     (@CNs)=split(/\n/,$cn{$omimid});
     foreach $cni  (@CNs) {
      $cni=~s/\n//g;
      $self->_addToStone('Contributors',$cni,$s,\%ok);
     }
#
     (@references)=split(/\n\n/,$rf{$omimid});
     foreach $reference (@references) {
      $reference=~s/\n//g;
      $self->_addToStone('References',$reference,$s,\%ok);
     }
#
      (@ClinicalSynopsis)=split(/\n\n/,$cs{$omimid});
      foreach $main (@ClinicalSynopsis) {
       $main=~s/\n//g;
       ($id,$values)=split(/:/,$main);
       (@lines)=split(/;/,$values);
       foreach (@lines) {
        $_=~s/\s+/ /g;
        (@toclean)=split(//,$_); $maxlen=$#toclean;
        for ($i=0; $i<=$maxlen; $i++ ) {
         $curchar=shift(@toclean);
         if ($curchar=~/\s/) {
         } else {
          unshift(@toclean,$curchar);
          $i=$maxlen+1000;
         }
        }
        $tmpval=join('',@toclean); 
        $self->_addToStone('ClinicalSynopsis',$tmpval,$s,\%ok);
       }
      }
#
     (@AllelicVariants)=split(/\n\n\./,$av{$omimid});
     foreach $variant (@AllelicVariants) {
       undef $variantf;
       (@details)=split(/\n/,$variant);
        $idtmp=@details[0];
        for ($i=1; $i<=$#details; $i++ ) {
         $variantf.=@details[$i]." ";
        }
       $self->_addToStone('AlelicVariants',$variantf,$s,\%ok);
     }
 undef $ti{$omimid}, $tx{$omimid}, $sa{$omimid}, $mn{$omimid};
 undef $cd{$omimid}, $ed{$omimid}, $cn{$omimid};
 undef $rf{$omimid}, $av{$omimid}, $cs{$omimid};
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
package OmimAccessor;
use Carp;

sub new {
    my($class,@parameters) = @_;
    croak "OmimAccessor::new:  Abstract class\n";
}

sub fetch_next {
    my($self) = @_;
    croak "OmimAccessor::fetch_next: Abstract class\n";
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
@ISA=qw(OmimAccessor);
$DEFAULT_PATH = Boulder::Omim::DEFAULT_OMIM_PATH();

#<LIGT>
# Following, removed the search for the string locus in the file
#   as validation that the input be compliant with parser
#</LIGT>
sub new {
    my($package,$path) = @_;
    $path = $DEFAULT_PATH unless $path;
    open (OM,$path) or croak "File::new(): couldn't open $path: $!";
    # read the junk at the beginning
    my $found; $found++;
    croak "File::new(): $path doesn't look like a Omim flat file"
	unless $found;
    $_ = <OM>;
    return bless {'fh'=>OM},$package;
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
