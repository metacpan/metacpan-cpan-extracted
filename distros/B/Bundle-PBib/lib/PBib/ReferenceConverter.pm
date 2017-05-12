# --*-Perl-*--
# $Id: ReferenceConverter.pm 18 2004-12-12 07:41:44Z tandler $
#

=head1 NAME

PBib::ReferenceConverter - Main controller class for processing references within documents

=head1 SYNOPSIS

	use PBib::ReferenceConverter;
	my $inDoc = new PBib::Document(
		'filename' => 'sample.xml',
		'mode' => 'r',
		);
	my $outDoc = new PBib::Document(
		'filename' => 'sample-pbib.xml',
		'mode' => 'w',
		);
	my $conv = new PBib::ReferenceConverter(
		'inDoc'		=> $inDoc,
		'outDoc'	=> $outDoc,
		'refStyle'	=> new PBib::ReferenceStyle(),
		'labelStyle'	=> new PBib::LabelStyle(),
		'bibStyle'	=> new PBib::BibliographyStyle(),
		'itemStyle'	=> new PBib::BibItemStyle(),
		'verbose' => 1,
		'quiet' => 0,
		);
	$conv->convert($refs);
	$inDoc->close();
	$outDoc->close();

=head1 DESCRIPTION

Main controller class of the PBib system for processing references within documents.

See module L<PBib::PBib> for an example how to use it.

=cut

package PBib::ReferenceConverter;
use strict;
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 18 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#use YYYY;
#use vars qw(@ISA);
#@ISA = qw(YYYY);

# used modules
# used own modules
use PBib::Document;

# module variables
#use vars qw(mmmm);


=head1 METHODS

=over

=cut

#
#
# constructor
#
#

sub new {
# see access methods below for list of valid args
#  print STDERR "\n1: ", localtime(), "\n";
  my $self = shift;
  my %args = @_;
  #  foreach my $arg qw/inDoc outDoc refStyle labelStyle bibStyle itemStyle/ {
    #  print STDERR "argument $arg missing in call to new $self\n"
	#  unless exists $args{$arg};
  #  }

  my $class = ref($self) || $self;
  # hook for documents to choose different converter ...
#print "def. class $class\n";
  $class = $args{'inDoc'}->referenceConverterClass($class) || $class;
  print STDERR "converter class $class\n" if $args{'verbose'};

  $self = \%args;
  print STDERR Dumper {
  		"refStyle" => $args{'refStyle'},
  		"refOptions" => $args{'refOptions'}, 
		"bibStyle" => $args{'bibStyle'},
  		"bibOptions" => $args{'bibOptions'},
		"itemStyle" => $args{'itemStyle'},
  		"itemOptions" => $args{'itemOptions'}, 
  		"labelStyle" => $args{'labelStyle'},
  		"labelOptions" => $args{'labelOptions'},
  		} if $args{'verbose'} && $args{'verbose'} > 1;
  $self = bless $self, $class;
  $self->refStyle()->setConverter($self) if defined $self->refStyle();
  $self->labelStyle()->setConverter($self) if defined $self->labelStyle();
  $self->bibStyle()->setConverter($self) if defined $self->bibStyle();
  $self->itemStyle()->setConverter($self) if defined $self->itemStyle();
  return $self;
}

sub setArgs {
	my $self = shift;
	my %args = @_;
	foreach my $arg (keys %args) {
		$self->{$arg} = $args{$arg};
	}
}

#
#
# access methods
#
#

sub inDoc { my $self = shift; return $self->{'inDoc'}; }
sub outDoc { my $self = shift; return $self->{'outDoc'}; }

# options for the ref' converter share the ref'style's options.
sub option { my ($self, $opt) = @_; return $self->refOptions()->{$opt}; }

sub refOptions { my $self = shift; return $self->{'refOptions'} || {}; }
sub labelOptions { my $self = shift; return $self->{'labelOptions'} || {}; }
sub bibOptions { my $self = shift; return $self->{'bibOptions'} || {}; }
sub itemOptions { my $self = shift; return $self->{'itemOptions'} || {}; }

sub refStyle { my $self = shift; return $self->{'refStyle'}; }
sub labelStyle { my $self = shift; return $self->{'labelStyle'}; }
sub bibStyle { my $self = shift; return $self->{'bibStyle'}; }
sub itemStyle { my $self = shift; return $self->{'itemStyle'}; }



sub messages {
    my ($self) = @_;
    return $self->{'messages'} if $self->{'messages'};
    return $self->{'messages'} = [];
}

sub clearMessages {
    my ($self) = @_;
    delete $self->{'messages'}
}

sub logMessage {
    my $self = shift;
    print STDERR utf8_to_ascii("@_\n") unless $self->{'quiet'};
    push @{$self->messages()}, "@_";
}

sub traceMessage {
    my $self = shift;
    print STDERR utf8_to_ascii("@_\n") if $self->{'verbose'};
    push @{$self->messages()}, "@_";
}

sub warn {
    my $self = shift;
    $self->logMessage("WARNING: @_");
}


sub utf8_to_ascii {
	# on my system (win), STDERR does not support utf8 (per default)
	# this function maps unicode to plain ascii to avoid warnings 
	# about unprintable wide characters.
   return join("",
	 map { $_ > 255 ?                  # if wide character...
		   sprintf("&#x%04X;", $_) :   # \x{...}
		   chr($_)                    # else as themselves
	 } unpack("U*", $_[0]));         # unpack Unicode characters
}


#
#
# scanning methods
#
#

# all information about found references
sub foundInfo { my ($self) = @_; $self->scan(); return $self->{'foundInfo'}; }

# all information about found paragraphs with references
sub parInfo { my ($self) = @_; $self->scan(); return $self->{'parInfo'}; }

# all indexes of paragraphs containing refs
sub parIndexes { my ($self) = @_; return [keys(%{$self->parInfo()})]; }

# all ID of found references
sub foundIDs { my ($self) = @_; return [keys(%{$self->foundInfo()})]; }

sub knownIDs {
#
# return known and found ref IDs => the items for the bibliography
#
  my ($self) = @_;
  my @items;
  my $refs = $self->refs();

  # remove unknown reference IDs
  foreach my $ref (@{$self->foundIDs()}) {
    push @items, $ref
		if defined($refs->{$ref});
  }
  return \@items;
}

sub unknownIDs {
#
# return unknown and found ref IDs => possible errors!
#
  my ($self) = @_;
  my @items;
  my $refs = $self->refs();

  # remove known reference IDs
  foreach my $ref (@{$self->foundIDs()}) {
    push @items, $ref
		unless defined($refs->{$ref});
  }
  return \@items;
}


=item $rc->scan()

Scan $rc's inDoc for used references and paragraphs that need to be converted.
This does preprocessing for convert().

The fields "parInfo" and "foundInfo" are set.

=cut

sub scan {
# look for all paragraphs that might have references
# return an array with all found refs
	my ($self) = @_;
	my $inDoc = $self->inDoc();
	
	# have we scanned already?
	return $self->{'foundInfo'} if( defined($self->{'foundInfo'}) );
	
	my (%parInfo, %foundInfo, %fields);
	my $par;
	my $numPars = $inDoc->paragraphCount();
	$self->traceMessage("scanning $numPars paragraphs in ", $inDoc->filename());
	$inDoc->processParagraphs(\&scanParagraph, $self, undef,
				\%parInfo, \%foundInfo, \%fields);
	$self->traceMessage("scanning done");
	
	$self->{'parInfo'} = \%parInfo;
	$self->{'foundInfo'} = \%foundInfo;
	#print Dumper \%parInfo, \%foundInfo;
	return \%foundInfo;
}

#
# some definitions to make pattern construction easier for me ...
#
# $B = no bracket char (everything not [ nor ]
my $B = "(?:[^\\[\\]])";
# $bb = [...] with no embedded []
my $bb = "(?:\\[$B*\\])";
my $opt = "(?:\\s*:$B*\\|\\s*)";
# now define pattern for ref and bib
my $fieldPattern = "(?:$B|$bb)+";
my $refPattern = "(?:$B*$bb(?:$B|$bb)*)";
my $bibPattern = "(?:$opt?\{$B*\})";
my $optionPattern = "(?::$B*:)";
my $todoPattern = "(?:(?:<$B*>)|(?:\#$B*\#))";
my $todoMarker = "(?:#+)|(?:\\?{2,})|(?:[<>]{3,})";


=item $rc->scanParagraph($par, $i, $parInfo, $foundInfo, $fields)

Scan the inDoc for paragraphs with references and collect information
on which references are used, how often they are used, and in which 
parahraphs they are used.

This method is called by scan() via inDoc's processParagraphs().

=cut

sub scanParagraph {
# look for reference ids in the given string
	my ($self, $par, $i, $parInfo, $foundInfo, $fields) = @_;
	my $ref;
	#  print $par;
	return unless( $par =~ /\[/ );
	
	while ( $par =~ s/\[($B+)\]/\[\]/ ) {
		$ref = $self->unquote($1);
		#  print "-- $ref\n";
		$foundInfo->{$ref} = 0 unless defined($foundInfo->{$ref});
		$foundInfo->{$ref} ++;
		$parInfo->{$i} = {} unless defined($parInfo->{$i});
		$parInfo->{$i}->{$ref} = 1;
	}
}


#
#
# converting methods
#
#


sub refs { my $self = shift; return $self->{'refs'} || {}; }
sub refPattern { my $self = shift; return $self->{'refPattern'} || ''; }
sub currentParagraph { my ($self) = @_; return $self->inDoc()->{currentParagraph}; }


=item $rc->convert($refs, $inDoc, $outDoc)

Convert $inDoc to $outDoc.

This is the main method of ReferenceConverter.

=cut

sub convert {
# $refs points to a hash with all refId => bibitem hash (bp-canonical form)
	my ($self, $refs, $inDoc, $outDoc) = @_;
	$self->{'refs'} = $refs;
	$self->{inDoc} = $inDoc if $inDoc;
	$self->{outDoc} = $outDoc if $outDoc;
	$inDoc = $self->{inDoc} = $self->inDoc()->prepareConvert($self);
	return undef unless $inDoc;
	$outDoc = $self->outDoc(); # get outDoc after prepareConvert as it might have been changed ...
	$outDoc->close(); # in case it is still open (e.g. in Word)
	
	my $knownIDs = $self->knownIDs();
	
	# refPattern is used by the ReferenceStyle for matching.
	my $refPattern = '(?:' . join("|",
		map('(?:'.quotePattern($_).')', @$knownIDs)) . ')';
	#  print "$refPattern\n";
	$self->{'refPattern'} = $refPattern;
	
	$self->traceMessage(scalar(keys %{$refs}), " known references\n");
	$self->traceMessage(scalar(@{$knownIDs}), " found references\n");
	$self->traceMessage("converting ", scalar(keys %{$self->parInfo()}), " paragraphs ...\n");
	#  print Dumper $self->parInfo();
	$inDoc->processParagraphs(\&convertParagraph, $self, $outDoc,
				$self->option("final"));
	$self->traceMessage("\n... converting done\n");
	
	$self->{'outDoc'} = $outDoc->finalizeConvert($self);
	$outDoc->write();
}

=item $rc->convertParagraph($par, $i, $final)

Replace references in $par. $i is the index of this paragraph (as used in parInfo().

This method is called by convert() via inDoc's processParagraphs().

=cut

sub convertParagraph {
	my ($self, $par, $i, $final) = @_;
	# convert only paragraphs that contain at least one reference
	if( exists($self->parInfo()->{$i}) ) {
		print STDERR "o" unless $self->{'quiet'};
		# my $refPattern = $self->{'refPattern'};
		# look for all [...] where ... is
		#	- non-zero length
		#	- has no more then one-level of embedded [...]
		# $par =~ s/\[((?:(?:[^\[\]])|(?:\[[^\[\]]*\]))+)\]/
		# there must be at least on embedded $bb, maybe more
		#  print substr($par, 0, 150), "\n";
		#if( $par =~ /\[.*\{.*\}.*\]/ ) { print $par; }
		#  $par =~ s/\[($ref|$bib)\]/
		$par =~ s/\[($fieldPattern)\]/ $self->expandField($1) /ge;
	}# else { print STDERR "."; }
	if( $final ) {
		print STDERR "." unless $self->{'quiet'};
		# check for some todo items that might remain in the document.
		if( $par =~ /($todoMarker)/ ) {
			$self->addToDoItem("ToDo Marker $1 found");
		}
	}
	return $par;
}


### ToDo: refactor different kind of fields into different field classes!
### each field class (1) knows its pattern (2) knows how to be replaced
sub expandField {
# return text for the given reference
  my ($self, $refField) = @_;

#  print STDERR "found field [$refField]\n";
  # convert field to standard char set
  my $text = $self->unquote($refField);

#  print STDERR "[$text] ";
  # is it a bibliography field?
  if( $text =~ /^$bibPattern$/ ) {
    $text = $self->bibStyle()->text($text);
  } elsif( $text =~ /^$optionPattern$/ ) {
    ##### s.th. like: $self->refStyle()->processOption($text);
	return ''; # remove options
  } elsif( $text =~ /^$refPattern$/ ) {
    $text = $self->refStyle()->text($text);
  } elsif( $text =~ /^$todoPattern$/ ) {
    return $self->processToDoItem($text);
  } else {
    # nothing supported --> better leave unchanged!
#	print STDERR "=> (unchanged)\n";
    return "[$refField]";
  }
#  print STDERR "=> ", substr($text, 0, 40), "\n";
  return $self->quote($text);
}

sub toDoItems { my $self = shift;
	$self->{'todo'} = [] unless defined($self->{'todo'});
	return $self->{'todo'};
}
sub addToDoItem { my ($self, $text, %keys) = @_;
	$self->logMessage("todo: $text\n");
	my $todo = $self->toDoItems();
	push @$todo, {'text' => $text, 'par' => $self->currentParagraph(), %keys};
}
sub processToDoItem { my ($self, $text) = @_;
	# remove todo delimiters of the form:
	$text =~ s/(?:^[#<]+\s*)|(?:\s*[#>]+$)//g;
	$self->addToDoItem($text);
	return $self->outDoc()->highlight(
			$self->outDoc()->quote("<<$text>>"));
}


sub unquote {
  my ($self, $text) = @_;
  $text = $self->inDoc()->unquote($text);
  $text =~ s/\c//g;
  return $text;
}
sub quote {
  my ($self, $text) = @_;
  $text = $self->outDoc()->quote($text);
  return $text;
}

#
#
# reference entry access methods
#
#

sub entries {
#
# return the entries for a given reference ID
#
	my ($self, $refID) = @_;
	my $ref = $self->refs()->{$refID};
	if( $ref ) {
#print Dumper $ref if $refID eq "Phidgets-PhysicalWidgets";
#print Dumper $ref if $refID eq 'iRoom-PointRight';
		if( exists $ref->{'CrossRef'} ) {
			$self->expandCrossRef($ref);
		}
	} else {
		$self->warn("Can't find CiteKey $refID");
	}
	return $ref;
}
sub entry { my ($self, $refID, $entry, $check) = @_;
  my $e = $self->entries($refID)->{$entry};
#
# I could include a return-once-only check, i.e.
# if called a second time, it will return ().
# this could make the writing of some style a lot
# easier, I guess ...
#
  if( !$e ) {
    if( $check ) {
      $self->warn("entry '$entry' not defined in $refID");
      return "{\\b \\i <<$entry missing>>}" if
	$self->refOptions()->{'debug-undef-entries'};
    }
    return ();
  }
  if( $e eq '{}' ) {
    return ();
  }
  return defined($e) && $e ne '' ? $e : ();
}
sub entryExists { my ($self, $refID, $entry) = @_;
  return exists($self->entries($refID)->{$entry});
}
sub entryNotEmpty { my ($self, $refID, $entry) = @_;
  my $e = $self->entries($refID)->{$entry};
  return defined($e) && $e ne '';
}


# when expanding crossref, move data among fields, e.g. 
# the Title of a book will be the SuperTitle of a incollection
my %crossRefFields = qw(
	Title		SuperTitle
	);
# when expanding crossref, adapt the CiteType of the reference
# e.g. a part of a proceedings will be inproceedings
# or an "article" is a part of a "journal".
my %crossRefTypes = qw(
	book	incollection
	proceedings	inproceedings
	journal	article
	);

sub expandCrossRef {
#
# support for CrossRef entry: get all referenced field values
#
	my ($self, $ref) = @_;
	if( exists $ref->{'CrossRef__expanded__'} ) { return $ref; }
	$self->traceMessage("expand crossref $ref->{'CiteKey'} --> $ref->{'CrossRef'}");
	foreach my $xrefID (split(/,/, $ref->{'CrossRef'})) {
		my $xref = $self->entries($xrefID);
		# adapt CiteType
		if( ! defined($ref->{'CiteType'}) && defined($xref->{'CiteType'}) ) {
			# print STDERR Dumper({'ref', $ref, 'xref', $xref});
			$ref->{'CiteType'} = $crossRefTypes{$xref->{'CiteType'}} 
					|| $xref->{'CiteType'};
		}
		foreach my $xentry (keys %{$xref}) {
			my $entry = $crossRefFields{$xentry} || $xentry;
			if( !exists $ref->{$entry} ) {
				# print STDERR "$xentry->$entry; ";
				$ref->{$entry} = $xref->{$xentry};
			}
		}
	}
	#  print STDERR "\n";
	$ref->{'CrossRef__expanded__'} = 1;
	return $ref;
}

#
#
# class methods
#
#

sub quotePattern {
  my $pattern = shift;
  $pattern =~ s/([\-\[\]\*\+\{\}\.\\\$\^])/\\$1/g;
  return $pattern;
}

=back

=cut

#
#
# extension of package PBib::Document;
#
#

package PBib::Document;

sub referenceConverterClass {
#
# return which class of reference converter to use (undef for default)
#
  my ($self, $rcClass) = @_;
#print "sub referenceConverterClass\n";
  return undef;
}


1;

#
# $Log: ReferenceConverter.pm,v $
# Revision 1.20  2004/03/29 13:10:40  tandler
# setArgs
#
# Revision 1.19  2003/12/22 21:59:41  tandler
# toni's changes: include explaination field in UI
#
# Revision 1.18  2003/11/20 16:07:57  gotovac
# reveals clicked CiteKey
#
# Revision 1.17  2003/06/12 22:04:38  tandler
# support for logMessage() and warn()
# support prepareConvert() / finalizeConvert()
#
# Revision 1.16  2003/05/22 11:53:38  tandler
# expand cross ref: also adapt CiteType if the referenced CiteType is used.
# - warn, if a referenced CiteKey is not found.
#
# Revision 1.15  2003/01/21 10:26:00  ptandler
# log warnings/messages
#
# Revision 1.14  2002/11/05 18:29:51  peter
# multiple IDs in CrossRef field
#
# Revision 1.13  2002/11/03 22:13:28  peter
# minor
#
# Revision 1.12  2002/10/01 21:25:48  ptandler
# new status query accessor: unknownIDs
#
# Revision 1.11  2002/09/22 10:59:07  peter
# CrossRef support
#
# Revision 1.10  2002/08/22 10:40:41  peter
# - changed debug output
#
# Revision 1.9  2002/08/08 08:22:08  Diss
# minor changes
#
# Revision 1.8  2002/07/16 17:35:20  Diss
# allow documents to specify a different ref-converter + small changes
#
# Revision 1.7  2002/05/27 10:21:48  Diss
# small fixes ...
#
# Revision 1.6  2002/04/03 10:19:08  Diss
# - started support for "final" check, todo-items, comments etc.
#
# Revision 1.5  2002/03/28 13:23:00  Diss
# added pbib-export.pl, with some support for bp
#
# Revision 1.4  2002/03/27 10:23:15  Diss
# small fixes ...
#
# Revision 1.3  2002/03/27 10:00:51  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.2  2002/03/22 17:31:01  Diss
# small changes
#
# Revision 1.1  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#