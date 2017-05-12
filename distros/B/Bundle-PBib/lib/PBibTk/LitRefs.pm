# --*-Perl-*--
# $Id: LitRefs.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBibTk::LitRefs;
use strict;
use warnings;
#use English;
use FileHandle;

# own packages
use Biblio::Biblio;
use PBib::Document;
use PBib::ReferenceConverter;
use PBib::Config;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

use vars qw($opt_r $opt_d);
#use Getopt::Std;
#getopts("d:r:");

#
#
# methods
#
#

sub new ($) {
  my $class = shift;
  return bless {}, $class;
}

sub DESTROY ($) {
  my $self = shift;
  $self->disconnectBiblio();
}

sub processArgs ($) {
  my $self = shift;

  # read + set refs

  if( defined($opt_d) ) {
    # use a different database .... maybe use par as DBI's DSN
    my $dsn = $opt_d;
    print STDERR "use $dsn for database access\n";
    $self->readRefsFromBiblio();
  } elsif( defined($opt_r) ) {
    $self->readRefsFromFile($opt_r);
  } else {
    $self->readRefsFromBiblio();
  }

  # read all file's paragraphs

  my @paragraphs;
  my $filename;
  foreach $filename (@ARGV) {
    @paragraphs = (@paragraphs, $self->readFile($filename));
  }

  # analyze pars

  $self->analyzePars(\@paragraphs);
}

#
# access methods
#

sub refs { my $self = shift; return $self->{'refs'}; }
sub occurances { my $self = shift; return $self->{'found'}; }
sub found { my $self = shift; my @keys = keys(%{$self->occurances()}); return \@keys; }
sub known { my $self = shift; return $self->{'known'}; }
sub unknown { my $self = shift; return $self->{'unknown'}; }
sub used { my $self = shift; return $self->known(); }
sub unused { my $self = shift; return $self->{'unused'}; }
sub newrefs { my $self = shift; return $self->{'newrefs'}; }

sub occurancesOf ($$) {
  my ($self, $ref) = @_;
  my $found = $self->occurances();
  return $found->{$ref} if( exists($found->{$ref}) );
  return 0;
}

sub statusOf ($$) {
  my ($self, $ref) = @_;
  my $found = $self->occurances();
  return {
    'occurances' => $self->occurancesOf($ref),
    'found' => $self->isFound($ref),
    'known' => $self->isKnown($ref),
    'unknown' => $self->isUnknown($ref),
    'used' => $self->isUsed($ref),
    'unused' => $self->isUnused($ref),
    'new' => $self->isNew($ref),
    };
}

sub filename { my $self = shift; return $self->{'filename'}; }

#
# test methods
#

sub isFound ($$) {
  my ($self, $ref) = @_;
  my $found = $self->occurances();
  return exists($found->{$ref});
}
sub isKnown ($$) {
  my ($self, $ref) = @_;
  return includes($ref, $self->known());
}
sub isUnknown ($$) {
  my ($self, $ref) = @_;
  return includes($ref, $self->unknown());
}
sub isUsed ($$) {
  my ($self, $ref) = @_;
  return includes($ref, $self->used());
}
sub isUnused ($$) {
  my ($self, $ref) = @_;
  return includes($ref, $self->unused());
}
sub isNew ($$) {
  my ($self, $ref) = @_;
  return includes($ref, $self->newrefs());
}

# private
sub includes {
  my ($val, $arrRef) = @_;
  my %hash = map( ($_, 0), @{$arrRef});
  return exists($hash{$val});
}

#
# biblio references
#

sub readRefs ($) {
  my $self = shift;
  my $src = $self->{'refSource'};
  SRC: {
    if( $src eq "File" ) { $self->readRefsFromFile(); last SRC; }
    $self->readRefsFromBiblio();
  }
}

sub readRefsFromFile ($$) {
  my ($self, $filename) = @_;
  $filename = $self->{'refFilename'} unless defined($filename);
  unless( defined($filename) ) { print STDERR "No filename given to read refs from.\n"; return; }
  my @paperIDs = readFileLines($filename);
  # strip quotes
  @paperIDs = map { stripQuotes($_) } @paperIDs;
  $self->setRefs(\@paperIDs);
  $self->{'refSource'} = 'File';
  $self->{'refFilename'} = $filename;
}

sub readRefsFromBiblio ($) {
  my $self = shift;
  my $b = $self->biblio();
  my @paperIDs = $b->getCiteKeys();
  $self->setRefs(\@paperIDs);
  $self->{'refSource'} = 'Biblio';
  delete $self->{'refFilename'};
}

sub setRefs ($$) {
  my ($self, $refs) = @_;
  $self->{'refs'} = $refs;
}

sub queryPapers ($;$$$) {
# query papers, look in $queryFields for $pattern
  my ($self, $pattern, $queryFields, $resultFields) = @_;
  return $self->biblio()->queryPapers($pattern, $queryFields, $resultFields);
}
sub queryPaperWithId ($$) {
  my ($self, $ref) = @_;
  return $self->biblio()->queryPaperWithId($ref);
}

#
# analyzing papers
#


#sub conv { shift->{'conv'} };
#my $conv = new PBib::ReferenceConverter;

sub analyzeFile ($$) {
  my ($self, $filename) = @_;
  my $paragraphs = $self->readFile($filename);
  print "analyze ", scalar(@$paragraphs), " paragraphs ... ";
  $self->analyzePars($paragraphs);
  print "done.\n";
}

sub analyzePars ($$) {
  my ($self, $pars) = @_;
  my $results = analyzeParagraphs($self->refs(), $pars);
  my $key;
  foreach $key (keys(%{$results})) {
    $self->{$key} = $results->{$key};
  }
}


#
#
#   helper functions
#
#


# look for refs in the given array of paragraphs
sub analyzeParagraphs ($$) {
  my ($refs, $pars) = @_;
  my $found = searchRefs(@{$pars});
  return analyzeRefs($refs, $found);
}



# return a hash with
#  'refs'	all existing/valid refs (array)
#  'found'	all refs within the document (hash with no of occurences)
#  'known'	all known/valid refs within the document (array)
#  'unknown'	all unknown/invalid refs within the document (array)
#  'unused'	all existing/valid refs that are not in the document (array)
#  'newrefs'	new papers without a paper ID yet (they have a quote or whitespace in the ref)
sub analyzeRefs ($$) {
  my ($refs, $found) = @_;
  my @known;
  my @unknown;
  my @newrefs;
  my %knownIDs = map( ($_, 0), @{$refs});
  my %unusedIDs = %knownIDs;
  my $ref;
  foreach $ref (keys(%{$found})) {
    if( exists $knownIDs{$ref} ) {
      push @known, $ref;
      delete $unusedIDs{$ref};
    } else {
      if( $ref =~ /["\@\/\~\#\$\§\%\&\(\)\{\}\\<>=]/ ) {
      	push @newrefs, $ref;
      } else {
      	push @unknown, $ref;
      }
    }
  }
  my @unused = keys(%unusedIDs);
print STDERR "refs (", scalar(@{$refs}), ") ";
print STDERR "found (", scalar(keys(%{$found})), ") ";
print STDERR "known (", scalar(@known), ") ";
print STDERR "unknown (", scalar(@unknown), ") ";
print STDERR "new (", scalar(@newrefs), ") ";
print STDERR "unused (", scalar(@unused), ") ";
print STDERR "\n";
  return {
    'refs' => $refs,
    'found' => $found,
    'known' => \@known,
    'unknown' => \@unknown,
    'newrefs' => \@newrefs,
    'unused' => \@unused
    };
}





# search for all references
# return a ref to hash mapping all found references to the number of occurences
sub searchRefs (@) {
  my $par;
  my %foundIDs;
  foreach $par (@_) {
    # find lines with [[ or ]]
    if( $par =~ /\[.*\]/ ) {
#      print "$par\n";
      extractRefs($par, \%foundIDs);
    }
  }
  return \%foundIDs;
}

# add all references in the given string
# to the given hash as keys (the value is unused)
sub extractRefs ($$) {
  my ($par, $foundIDs) = @_;
  my $ref;
  my $n;
  while ( $par =~ s/\[([^\[\]]+)\]/\[\]/ ) {
    $ref = $1;
    $n = $foundIDs->{$ref};
    $n = 0 unless defined($n);
    $foundIDs->{$ref} = ++ $n;
#    print "-- $ref ($n)\n";
  }
  return $foundIDs;
}



# strip quotes
# if the given string starts and ends with a quote, replace all
# occurences of "" with a single "
sub stripQuotes ($) {
  my ($s) = @_;
  if( $s =~ /^\".*\"$/ ) {
    $s =~ s/^\"//;
    $s =~ s/\"$//;
    $s =~ s/\"\"/\"/g;
  }
  return $s;
}


#
#
# read document
#
#

sub doc () { shift->{'doc'} }

sub readFile ($$) {
  my ($self, $filename) = @_;
  print "read $filename ...\n";
  my $doc = new PBib::Document(
	'filename' => $filename,
	'mode' => 'r',
	);

  $self->{'filename'} = $filename;
  $self->{'doc'} = $doc;
  return $doc->paragraphs();
}


sub readFileLines ($) {
  my ($filename) = @_;
# print "read $filename\n";
  my $file = new FileHandle("< $filename");
  my @lines;

  if( not defined($file) ) {
    print STDERR "Can't open file $filename\n";
    return ();
  }

  chomp(@lines = <$file>);
  $file->close();
  return @lines;
}


#
# biblio database access
#

sub biblio ($) {
  my $self = shift;
  my $b = $self->{'biblio'};
  if( not defined($b) ) {
    print STDERR "open connection to Biblio\n";
    my $config = new PBib::Config();
    $b = new Biblio::Biblio(%{$config->option('biblio')});
      defined($b) or die "$DBI::errstr\nCan't open database";
    $self->{'biblio'} = $b;
  }
  return $b;
}
sub disconnectBiblio ($) {
  my $self = shift;
  my $b = $self->{'biblio'};
  if( defined($b) ) {
    print STDERR "close connection to Biblio\n";
    $b->disconnect();
    $self->{'biblio'} = undef;
  }
}


1;

#
# $Log: LitRefs.pm,v $
# Revision 1.15  2003/04/14 09:50:26  ptandler
# fixed prototypes
#
# Revision 1.14  2003/01/21 10:23:02  ptandler
# use PBib::Config
#
# Revision 1.13  2002/08/22 10:35:57  peter
# - don't include new refs as unknown refs
#
# Revision 1.12  2002/06/06 08:56:58  Diss
# use PBib::Doc instead of ReadDoc: now I can use also RTF files
# TODO: switch to PBib::RefConverter instead of using own methods
#
# Revision 1.11  2002/06/06 07:25:34  Diss
# use Biblio::Biblio (instead of old version Biblio)
#
# Revision 1.10  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#
# Revision 1.9  2002/02/11 11:57:06  Diss
# lit UI with search dialog, script to start/stop biblio, and more ...
#
# Revision 1.8  2002/01/26 18:21:54  ptandler
# - disconnect from Biblio-DB in LitRef's destructor (DESTROY)
#   -> this allows to re-read the entries without re-connecting
# - moved Word-Doc support from LitUI to LitRef
#
# Revision 1.7  2002/01/24 22:44:10  ptandler
# moved .doc support to LitRefs.pm
#
# Revision 1.6  2002/01/24 21:38:35  ptandler
# use also several special chars to identify new refs in contrast to unknown
#
# Revision 1.5  2002/01/20 14:10:09  ptandler
# the UI is quite nice already!
#
# Revision 1.4  2002/01/19 00:47:58  ptandler
# - new LitUI.pm and litUI.pl
# - minor changes
#
# Revision 1.3  2002/01/17 08:05:07  ptandler
# LitRefs.pm, known.pl: small fixes
# new files: restats.pl, newrefs.pl, convertDoc.pl
#
# Revision 1.2  2002/01/14 08:30:26  ptandler
# new module "Biblio.pm" to access biblio database via DBI/ODBC
# LitRefs can get all defined paperIDs now from BIBLIO (using Biblio.pm)
#