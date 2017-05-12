# --*-Perl-*--
# $Id: BibliographyStyle.pm 11 2004-11-22 23:56:20Z tandler $
#

package PBib::BibliographyStyle;
use strict;
use English;
use charnames ':full';	# enable \N{unicode char name} in strings

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 11 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#  use PBib::Style;
use base qw(PBib::Style);

# used modules
#use FileHandle;
#use File::Basename;


# module variables
#use vars qw(mmmm);

#
#
# access methods
#
#


sub options { my $self = shift; return $self->converter()->bibOptions(); }

sub includeAllRefs { return shift->fieldOption("all"); }


sub text {
#
# generate bibliography
#
  my ($self, $refField) = @_;
  $self->{'refID'} = $refField;
  $self->logMessage("bibliography item [", $self->refID(), "] found");
  my $rc = $self->converter();
  my $rf = $rc->refStyle();
  my $ri = $rc->itemStyle();
  my ($ref, $key);

  # check for options ...
  if( $refField =~ s/^\s*:\s*([^\|\[\]]*)\s*\|\s*// ) {
  	my $options = $self->parseFieldOptions($1);
  	$self->{'fieldOptions'} = $options;
#print Dumper $options;
  }
#print "$refField\n";

  my $items = $self->items();
  my $query = $self->convertQuery($refField);
  if( $query ) {
    $items = $self->selectItems($query, $items);
  }

  # sort items
#print "sort ...\n";
  my %item_keys;
  foreach $ref (@{$items}) {
    $key = $ri->sortkeyFor($ref);
    while( exists($item_keys{$key}) ) {
      $self->warn("duplicate sort key $key");
      $key = $key . "#";
    }
    $item_keys{$key} = $ref;
  }

  # format items
#print "format ...\n";
  my @bibitems;
  foreach $key (sort(keys(%item_keys))) {
    $ref = $item_keys{$key};
    push @bibitems, $ri->formatWith($ref);
  }

  my $outDoc = $rc->outDoc();
  return $outDoc->bibitems_start() .
	join($outDoc->bibitems_separator(), @bibitems) .
	$outDoc->bibitems_end();
}

#
#
# helper methods
#
#

sub items {
#
# return a list of items for bibliography
#
  my ($self) = @_;
  if( $self->includeAllRefs() ) {
	my @items = keys %{$self->converter()->refs()};
#print "@items\n";
	return \@items;
  }
  return $self->converter()->knownIDs();
}

sub selectItems { my ($self, $query, $items) = @_;
  my (@matches, $ref);
  foreach my $refID (@$items) {
    $ref = $self->converter()->entries($refID);
	#  print "$query: ";
	#  print $ref->{"Authors"}, " -> ";
    if( eval($query) ) {
	  #  print "!!!";
      push @matches, $refID;
	}
	#  print "\n";
  }
  return \@matches;
}

sub convertQuery { my ($self, $refField) = @_;
#
# convert field to a perl expression
#
  $refField =~ s/^\{|\}$//g; # strip braces
  $refField =~ s/\\[lr]quote ?/'/g; # convert quotes ##### hm ...
  $refField =~ s/\\[lr]dblquote ?/"/g; # convert quotes ##### hm ...
  $refField =~ s/[\N{LEFT DOUBLE QUOTATION MARK}\N{RIGHT DOUBLE QUOTATION MARK}\N{DOUBLE LOW-9 QUOTATION MARK}\N{DOUBLE HIGH-REVERSED-9 QUOTATION MARK}]/"/g;
  $refField =~ s/[\N{LEFT SINGLE QUOTATION MARK}\N{RIGHT SINGLE QUOTATION MARK}\N{SINGLE LOW-9 QUOTATION MARK}\N{LEFT SINGLE QUOTATION MARK}\N{SINGLE HIGH-REVERSED-9 QUOTATION MARK}]/'/g;
  $refField =~ s/%/(?:.*)/g; # convert wildcards
  $refField =~ s/\s*=\s*/ eq /gi;
  $refField =~ s/\s+LIKE\s+\'([^']*)\'/ =~ \/^$1\$\//gi;
  $refField =~ s/\s+OR\s+/ || /gi;
  
  # convert Entries to perl code
  $refField =~ s/("[a-z]+\")/\$ref->\{$1\}/gi;
  
  # some optimization: heading & trailing wildchars
  $refField =~ s/\/\^\(\?\:\.\*\)/\//g;
  $refField =~ s/\(\?\:\.\*\)\$\//\//g;
  
  $self->traceMessage("Converted query: {$refField}");
  return $refField;
}

1;

#
# $Log: BibliographyStyle.pm,v $
# Revision 1.5  2003/04/14 09:46:49  ptandler
# optimized query
#
# Revision 1.4  2002/08/08 08:23:28  Diss
# - support field options
# - field option "all" to include all refs in list (not only found refs)
#
# Revision 1.3  2002/05/27 10:24:23  Diss
# support for [{...}] queries
#
# Revision 1.2  2002/03/27 10:00:50  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.1  2002/03/18 11:15:47  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#