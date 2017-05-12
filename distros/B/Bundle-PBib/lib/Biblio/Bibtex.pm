# --*-Perl-*--
# $Id: Bibtex.pm 10 2004-11-02 22:14:09Z tandler $
#

package Biblio::Bibtex;
use strict;
use English;

=head1 package BiblioBibtex;

read/write bibtex databases

=cut

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#use YYYY;
#use vars qw(@ISA);
#@ISA = qw(YYYY);

# used modules
use FileHandle;

# module variables
#use vars qw(mmmm);

# bibtex type names
my @type_names = qw/
article
book
booklet
inproceedings
inbook
incollection
inproceedings
article
manual
masterthesis
misc
phdthesis
proceedings
techreport
unpublished
misc
misc
misc
misc
misc
phdthesis
/;

my %entry_names = (
	'RepType' => 'Type',
	'Annote' => 'BibNote', ### currently ...
	'Type' => 'pbibType',
	'Category' => 'Category',
	'PaperID' => 'CiteKey',
	'Identifier' => 'pbibSOCiteKey',
	);

#
#
# constructor
#
#

sub new {
  my $self = shift;
  my $bib = {
	'papers' => {},
	'shortcuts' => {}, # shortcut strings defined by style or bib
	'preamble' => '', # tex-preamble
	};
  my $class = ref($self) || $self;
  return bless $bib, $class;
}

#
#
# destructor
#
#

#sub DESTROY ($) {
#  my $self = shift;
#}



#
#
# access methods
#
#

sub filename { my $self = shift; return $self->{'filename'}; }


#
#
# paper access methods
#
#

sub papers { my $self = shift; return $self->{'papers'}; }
sub paper { my ($self, $id) = @_; return $self->papers()->{$id}; }

sub addPaper { my $self = shift; return $self->addPapers(@_); }
sub addPapers { my $self = shift;
  my $id;
  my $p; foreach $p (@_) {
    $id = $p->{'PaperID'};
    if( defined($id) ) {
#      print STDERR ($self->paper($id) ? "overwrite" : "add"), " paper $id\n";
      print STDERR "overwrite paper $id\n" if( $self->paper($id) );
      $self->papers()->{$id} = $p;
    } else {
      print STDERR "WARNING: no paper ID specified in @{$p}!\n"
    }
  }
}


#
#
# query paper methods
#
#

sub getPaperIDs {
# return all paper IDs
  my $self = shift;
  return keys(%{$self->papers()});
}

sub queryPapers ($, $, $, $) {
# query papers, look in $queryFields for $pattern
  my $self = shift;
  my ($pattern, $queryFields, $resultFields, $ignoreCase) = @_;
  $ignoreCase = 1 if not defined($ignoreCase);
  $pattern = lc($pattern) if($ignoreCase);
  $resultFields = $self->allPaperFields() unless defined($resultFields);
  $queryFields = $resultFields if not defined($queryFields);
  my $sql = 'SELECT ' . join(', ', map(quoteField($_), @{$resultFields})) .
	' FROM "biblio" WHERE ' .
	join(' OR ',
	  map('(' . quoteField($_, $ignoreCase) . " LIKE '$pattern')", @{$queryFields}));
  print "$sql\n";
  my $papers = $self->query($sql) or
    die "$DBI::errstr\nSelect failed for $sql\n";
  return $self->papersArrayToHash($resultFields, $papers);
}

sub queryPaperWithId ($, $) {
  my ($self, $id) = @_;
  my $resultFields = $self->allPaperFields();
  my $sql = 'SELECT ' . join(', ', map(quoteField($_, 0), @{$resultFields})) .
	' FROM "biblio" WHERE ' . quoteField("PaperID") . " = '$id'";
  print "$sql\n";
  my $papers = $self->query($sql) or
    die "$DBI::errstr\nSelect failed for $sql\n";
  return $self->papersArrayToHash($resultFields, $papers)->[0];
}




#
#
# shortcut access methods
#
#

sub shortcuts { my $self = shift; return $self->{'shortcuts'}; }

sub replaceShortcuts {
# look in $text and replace all shortcuts
  my ($self, $text) = @_;
  my $shortcuts = $self->shortcuts();
  my $pattern = join("|", map( /:$/ ? "$_.*" : $_, (keys(%{$shortcuts}))));
#print $pattern;
  $text =~ s/\{($pattern)\}/ expandShortcut($shortcuts, $1) /ge;
  return $text;
}
sub expandShortcut {
  my ($shortcuts, $text) = @_;
  my @pars = split(/:/, $text);
  my $k = shift @pars; if( @pars ) { $k = "$k:"; }
  my $v = $shortcuts->{$k};
  $v =~ s/%(\d)/ @pars[$1-1] /ge;
  return $v;
#  return $shortcuts->{$text};
}

#sub updateShortcuts {
#  my ($self) = @_;
#  delete $self->{'shortcuts'};
#}


#
#
# save methods
#
#

sub write {
  my ($self, $filename) = @_;
  $filename = $self->filename() unless defined($filename);
  return unless defined($filename);
  my $fh = new FileHandle("> $filename");
  if( not defined($fh) ) {
    print STDERR "Can't open $filename for writing.\n";
    return;
  }
  print STDERR "write bibtex db to $filename\n";
  $self->writeHeader($fh);
  $self->writePapers($fh);
  $fh->close();
}

sub writeHeader { my ($self, $fh) = @_;
  print $fh "%% bibtex database, written by pbib\n\n";
}

sub writePapers { my ($self, $fh) = @_;
  my @ids = $self->getPaperIDs();
  my $type; my $paper;
  my $p; foreach $p (sort(@ids)) {
    $paper = $self->paper($p);
    $type = typename($paper->{'Type'});
    print $fh "\@$type \{$p,\n";
    my $e; foreach $e (sort(keys(%{$paper}))) {
      if( defined($paper->{$e}) ) {
        print $fh "  ", $self->quoteEntry($e), " = ",
		$self->quoteValue($paper->{$e}), ",\n";
      }
    }
    print $fh "\}\n\n";
  }
}

sub quoteEntry { my ($self, $entry) = @_;
# I guess, I'm using bibtex names!?
  if( exists($entry_names{$entry}) ) {
    $entry = $entry_names{$entry};
  }
  return lc($entry);
}

sub quoteValue { my ($self, $text) = @_;
# not quite advanced yet ...
  return "\"$text\"";
}


#
#
# class methods
#
#

sub typename { my $type = shift;
  return "misc" if( not defined($type) );
  return "misc" if( $type < 0 || $type >= scalar(@type_names) );
  return @type_names[$type];
}

1;

#
# $Log: Bibtex.pm,v $
# Revision 1.2  2002/06/03 11:40:08  Diss
# fixed bug in package name
#
# Revision 1.1  2002/03/24 18:54:25  Diss
# simple package to write bibtex databases
#
# Revision 1.2  2002/03/22 17:31:02  Diss
# small changes
#
# Revision 1.1  2002/03/18 11:15:47  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#
