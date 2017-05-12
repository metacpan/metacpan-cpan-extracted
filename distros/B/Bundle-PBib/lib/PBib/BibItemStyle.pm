# --*-Perl-*--
# $Id: BibItemStyle.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBib::BibItemStyle;

=head1 package PBib::BibItemStyle;

This is more or less the converted plain.bst bibtex style.

=head2 What has changed?

=over

=item It is still incomplete ...

=item All field names start with a captial letter.

This is mainly because the default StarOffice bibliography database
uses Capital letters ...

=item The "Type" field is the bibtex entry type like article etc.

It (i.e. StarOffice) uses a numerical encoding with article=0 and
so on.

=item Field "type" is called "ReportType"

(e.g. used to give a different name to "chapter", "Technical Report")

=back

=head2 Options

=over

=item debug-undef-entries -- write missing entries to out-file

=back

=cut

use strict;
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use PBib::Style;
use vars qw(@ISA);
@ISA = qw(PBib::Style);

# used modules
#use ZZZZ;

# used own modules
use Biblio::Util;

#
#
# access methods
#
#


sub options { my $self = shift; return $self->converter()->itemOptions(); }

sub etalNumber { my ($self, $options) = @_;
# how many authors until I use the "et al." style?
  return $self->fieldOption("etal", $options) || -1;
}
sub itemBookmark { my ($self, $options) = @_;
# should bookmarks be generated for each item?
  return ! $self->fieldOption("nobookmarks", $options);
}
sub forceKey { my ($self) = @_;
# should the 'Key' field take precedence over the default label?
  return $self->labelStyle()->forceKey();
}

sub includeLabel { my ($self) = @_;
# should the Cite label be included in the bibliography?
	my $opt = $self->option("include-label");
	return defined($opt) ? $opt : 1;
}
sub labelSeparator {
# which text should I use to separate the label from the rest of the item
# special values: {tab}, {return} (case-independent)
	return shift->option("label-separator") || " ";
}


sub defaultLanguage { my ($self) = @_;
  return $self->option('language') || 'English';
}
my $keywordStyles = {
	'English' => {},
	'EnglishAbbrev' => {
		'editor' => 'ed.',
		'editors' => 'eds.',
		"page" => "p.",
		"pages" => "pp.",
		"volume" => "vol.",
		"number" => "no.",
		"chapter" => "ch.",
		"Technical Report" => "Tech. Rep.", # only IEEE CS-style, not IEEE TR-style ...
		},
	'German' => {qw/
		English		Englisch
		German		Deutsch
		page		Seite
		pages		Seiten
		chapter		Kapitel
		/
		### ToDo ...
		},
	'GermanAbk' => {qw/
		English		Englisch
		German		Deutsch
		page		S.
		pages		S.
		chapter		Kap.
		/
		### ToDo ...
		},
	};

#
# add extremely abbrev. style
#
### ah, well, this doesn't work yet, as journal and proceedings names are not yet replaced!
#

my %_xabbrev = (%{$keywordStyles->{'EnglishAbbrev'}}, qw/
	Proceedings		Proc.
	International	int'l
	Conference		Conf.
	Transactions	Trans.
	/);
addKeywordStyle(undef, 'English', 'XAbbrev', \%_xabbrev);

sub keywordStyle { my ($self) = @_;
  return $self->defaultLanguage() . ($self->option('keywordStyle') || '');
}
sub addKeywordStyle { my ($self, $language, $style, $keywords) = @_;
# register a new style
  $keywordStyles->{"$language$style"} = $keywords;
}
sub keywords { my $self = shift; return $self->{'keywords'} || {}; }
sub keyword { my ($self, $opt) = @_;
  my $style = $keywordStyles->{$self->keywordStyle()};
  return $self->keywords()->{$opt} ||
    ($style ? $style->{$opt} : undef);
}


#
#
# formating shorthand methods
#
#

sub italic { my $self = shift; return $self->outDoc()->italic(@_); }
sub bold { my $self = shift; return $self->outDoc()->bold(@_); }
sub underlined { my $self = shift; return $self->outDoc()->underlined(@_); }

sub spaceConnect { my $self = shift; return $self->outDoc()->spaceConnect(@_); }
sub tieConnect { my $self = shift; return $self->outDoc()->tieConnect(@_); }
sub tieOrSpaceConnect { my $self = shift; return $self->outDoc()->tieOrSpaceConnect(@_); }


#
#
# methods
#
#

use vars qw/%SupportedCiteTypes $DefaultCiteType %CiteTypeAliases
			%ReportTypeDefaults/;

%SupportedCiteTypes = qw/
	article		1
	book		1
	inbook		1
	incollection	1
	inproceedings	1
	journal		1
	manual		1
	misc		1
	patent		1
	proceedings	1
	report		1
	talk		1
	thesis		1
	unpublished	1
	web		1
	/;

$DefaultCiteType = 'inproceedings';

#	incollection	inbook -- is formated slightly differnt ...
%CiteTypeAliases = qw/
	journal		article
	techreport	report
	conference	inproceedings
	booklet		book
	speech		talk
	slides		talk
	masterthesis	thesis
	phdthesis	thesis
	cdrom		avmaterial
	video		avmaterial
	poster		avmaterial
	email		unpublished
	/;

#### ToDo: use the default report types!
%ReportTypeDefaults = (
	'techreport'	=> "Technical Report",
	'masterthesis'	=> "Master's thesis",
	'phdthesis'	=> "Ph.D. thesis",
	'cdrom'		=> 'CD-ROM',
	'video'		=> 'Video',
	'poster'	=> 'Poster',
	'email'		=> 'E-Mail',
);


sub OrigCiteType { my $self = shift;
  my $Type = $self->entry('CiteType');
  if( not defined($Type) ) { return $PBib::BibItemStyle::DefaultCiteType }
  return $Type;
}

sub CiteType { my $self = shift;
  my $Type = $self->OrigCiteType();
  if( exists $PBib::BibItemStyle::CiteTypeAliases{$Type} ) {
    $Type = $PBib::BibItemStyle::CiteTypeAliases{$Type};
  }
  if( exists $PBib::BibItemStyle::SupportedCiteTypes{$Type} ) {
    return $Type;
  }
  $self->warn("Unsupported cite type '$Type' found in ", $self->refID(),
	" -- change to $PBib::BibItemStyle::DefaultCiteType\n");
  return $PBib::BibItemStyle::DefaultCiteType;
}


sub formatWith {
  my ($self, $refID) = @_;
  $self->{'refID'} = $refID;

  my $Type = $self->CiteType();
  my $f = "format_$Type";
#print "$refID -- $Type -- $f\n";
  my $blocks = $self->$f();
  return "" unless defined($blocks);
  print Dumper $blocks if( $self->option('debug-blocks') );
  my @block = map( (ref($_) eq 'ARRAY' ) ?
			$self->format_block($_) : $_, @{$blocks} );
#print "block\n"; print Dumper @block;

  # should we include the cite label for each item?
  my $label = '';
  if( $self->includeLabel() ) {
#print "include-label\n";
  	$label = $self->labelStyle()->text($refID);
  	my $sep = $self->labelSeparator();
  	##### ToDo: use outDoc to get \t or \n
  	$sep =~ s/{space}/ /ig;
  	$sep =~ s/{tab}/\t/ig;
  	$sep =~ s/{return}/\n/ig;
  	$label = "[$label]$sep";
  }
  

  my $outDoc = $self->converter()->outDoc();
  my $text = $outDoc->block_start() . $label .
	join($outDoc->block_separator(), @block) .
	$outDoc->block_end();
  
  # fix double dots after et al.
  #  $text =~ s/et\.? al\.\./et al./g;
  # fix all double dots
  $text =~ s/\.\././g;
  
  ##***
  if( $self->itemBookmark() ) {
	  my $id = $self->converter()->refStyle()->bookmarkID($refID);
	  return $outDoc->bookmark($text, $id);
	}
	return $text;
}
sub format_block {
  my ($self, $sentences) = @_;
  my @sentence = map( (ref($_) eq 'ARRAY' ) ?
			$self->format_sentence($_) : $_, @{$sentences} );
  return () unless @sentence;
#print "sentence\n"; print Dumper @sentence;
  my $outDoc = $self->converter()->outDoc();
  return $outDoc->sentence_start() .
	join($outDoc->sentence_separator(), @sentence) .
	$outDoc->sentence_end();
}
sub format_sentence {
  my ($self, $phrases) = @_;
  return () unless $phrases;
  return () unless @{$phrases};
#print "phrases\n"; print Dumper @{$phrases};
  my $outDoc = $self->converter()->outDoc();
  return $outDoc->phrase_start() .
	join($outDoc->phrase_separator(), @{$phrases}) .
	$outDoc->phrase_end();
}

#
# sorting
#

sub sortkeyFor {
# return an array of sort keys, most important first, additional key following
  my ($self, $refID) = @_;
  $self->{'refID'} = $refID;

  my $Type = $self->CiteType();
  my $f = "sortkey_$Type";
#print "$refID -- $Type -- $f\n";
  my @sortkeys = $self->$f();
  @sortkeys = $self->sortkey_general(@sortkeys);
  my $sortkey = lc("@sortkeys");
  # replace umlaute etc.
  $sortkey =~ tr/äáàâëéèêïíìîöóòôüúùûß/aaaaeeeeiiiioooouuuus/;
  # strip all remaining non-alpha characters
  $sortkey =~ s/[^a-z]//;
  print STDERR "$refID -> sortkey: '$sortkey'\n" if( $self->option('debug-sortkey') );
  return $sortkey;
}


#
# formating helper methods
#

# FUNCTION {format.names}
sub format_names { my ($self, $names) = @_;
  return () unless( defined($names) );
  return $self->format_names_first_last($names);
}
sub format_names_first_last { my ($self, $names) = @_;
  # currently just return as is ...
  return $names;
}
sub format_names_etal {
	my ($self, $names, $initials_space, $etal_no, $format_name) = @_;
	$initials_space = 1 unless defined $initials_space;
	$etal_no = $self->etalNumber() unless defined $etal_no; ###
	my @n = $self->split_names($names);
	my $etal = $etal_no > 0 && scalar(@n) > $etal_no;
	if( $n[-1] eq "et al." ) {
		$etal = 1;
		pop @n;
	}
	
	@n = map( $self->$format_name($_, $initials_space), @n);
	
	if( $etal ) {
		my $first = shift @n;
		return "$first et al.";
	}
	return Biblio::Util::join_and_list(@n);
}
sub format_names_initials_last {
	my ($self, $name_array, $initials_space, $etal_no) = @_;
	return $self->format_names_etal($name_array, $initials_space, $etal_no, 'format_name_initials_last');
}
sub format_name_initials_last {
	my ($self, $name_array, $initials_space) = @_;
#print Dumper $name_array;
	my $initials = $self->first_initials($name_array, $initials_space);
	my $last = $self->last_name($name_array);
	return $last unless $initials;	# company name or undef for et al.
	return "$initials $last";
}
sub format_names_last_initials {
	my ($self, $name_array, $initials_space, $etal_no) = @_;
	return $self->format_names_etal($name_array, $initials_space, $etal_no, 'format_name_last_initials');
}
sub format_name_last_initials {
	my ($self, $name_array, $initials_space) = @_;
#print Dumper $name_array;
	my $initials = $self->first_initials($name_array, $initials_space);
	my $last = $self->last_name($name_array);
	return $last unless $initials;	# company name or undef for et al.
	return "$last, $initials";
}

sub split_names { shift; return Biblio::Util::split_names(@_); }
sub num_names { shift; return Biblio::Util::num_names(@_); }
sub first_names { shift; return Biblio::Util::first_names(@_); }
sub first_initials { shift; return Biblio::Util::first_initials(@_); }
sub last_name { shift; return Biblio::Util::last_name(@_); }
sub multi_page_check { shift; return Biblio::Util::multi_page_check(@_); }

sub format_keyword { my ($self, $default) = @_;
## NEW: allow to overwrite non-terminal texts
## with the bibitems options!
  my $opt = $self->option($default);
  my $style = $self->keyword($default);
  return $opt || $style || $default;
}
sub format_type { my ($self, $default_type) = @_;
# this is a combined version of
# format.chapter.pages
# format.thesis.type
## NEW: the default names can be overwrittern using
## the bibitems options!
  my $ReportType = $self->entry('ReportType');
  if( $default_type eq $self->CiteType() ) {
    my $OrigType = $self->OrigCiteType();
	my $default = $ReportTypeDefaults{$OrigType};
    $default_type = $default if defined($default);
  }
  return $ReportType ||
	$self->format_keyword($default_type);
}


#
#
# sortkey helper functions
#
#

sub sortkey_names { my ($self, $names) = @_;
  my @all_names = $self->split_names($names);
  return () unless( @all_names );
  my $first_author = shift(@all_names);
  return $self->last_name($first_author);
}
sub sortkey_authors { my ($self) = @_;
  my $names = $self->entry('Authors');
  return $self->sortkey_names($names);
}
sub sortkey_authors_or_editors { my ($self) = @_;
  my $names = $self->entry('Authors');
  $names = $self->entry('Editors') unless( $names );
  return $self->sortkey_names($names);
}
sub sortkey_authors_or_organization { my ($self) = @_;
  my $names = $self->entry('Authors');
  my $org = $self->entry('Organization');
  return $self->sortkey_names($names) if( $names );
  return $org ? $org : ();
}
sub sortkey_editors_or_organization { my ($self) = @_;
  my $names = $self->entry('Editors');
  my $org = $self->entry('Organization');
  return $self->sortkey_names($names) if( $names );
  return $org ? $org : ();
}

sub sortkey_year { my ($self) = @_;
  my $Year = $self->entry('Year');
  return $Year ? $Year : ();
}
sub sortkey_title { my ($self) = @_;
  my $Title = $self->entry('Title');
  $Title =~ s/^(A |An |The )//i;
  return $Title ? $Title : ();
}


sub sortkey_general { my ($self, @sortkeys) = @_;
  my $notempty = scalar(@sortkeys);
  if( $self->entryNotEmpty('Key') ) {
    unshift @sortkeys, $self->entry('Key') if $self->forceKey();
    push @sortkeys, $self->entry('Key') unless $self->forceKey();
  }
  push @sortkeys, $self->sortkey_title() unless( $notempty );
  push @sortkeys, $self->sortkey_year();
  push @sortkeys, $self->sortkey_title() if( $notempty );
  if( $self->includeLabel() ) {
  	unshift @sortkeys, $self->labelStyle()->text($self->refID());
  }
  
  return @sortkeys;
}

#
#
# format methods for entries
#
#

sub format_authors { my ($self, $check) = @_;
  return $self->format_names($self->entry('Authors', $check));
}
sub format_editors { my ($self, $check) = @_;
  my $eds = $self->entry('Editors', $check);
  return undef unless defined $eds;
  my $num = $self->num_names($eds);
#print "$eds = $num names\n";
  return $num == 0 ? () :
	($self->format_names($eds) . ", " .
	$self->format_keyword($num == 1 ? "editor" : "editors"));
}
sub format_authors_or_editors { my ($self) = @_;
# NEW: print authors || editors
### ToDo: give warning if both are defined!!!!
  return $self->entryNotEmpty('Authors') ?
	$self->format_authors(1) :
	$self->format_editors(1);
}
sub format_title { my ($self, $check) = @_;
  my $Title = $self->entry('Title', $check);
#  my $id = $self->converter()->refStyle()->bookmarkID($self->refID());
  return $self->spaceConnect(
  	$Title ? $Title : '',
#	  ? $self->outDoc->bookmark($Title, $id)
#	  : $self->outDoc->bookmark('', $id),
	$self->format_language());
}
sub format_title_for_book { my ($self, $check) = @_;
# CAUTION: bibtex takes the booktitle from the 'Title' field!
# I renamed format.btitle to format_title_for_book
  my $Title = $self->entry('Title', $check);
#  my $id = $self->converter()->refStyle()->bookmarkID($self->refID());
  return $self->spaceConnect(
  	$Title ? $self->outDoc()->italic($Title) : '',
#	  ?	$self->outDoc()->bookmark($self->outDoc()->italic($Title), $id)
#	  :	$self->outDoc()->bookmark('', $id),
	$self->format_language());
}
sub format_volume { my ($self) = @_;
  my $Volume = $self->entry('Volume');
  return $Volume ?
	$self->tieOrSpaceConnect(
	  $self->format_keyword("volume"), $Volume) : ();
}
sub format_volume_series { my ($self) = @_;
  my $Volume = $self->entry('Volume');
  my $Series = $self->entry('Series');
### volume xor number check missing
  return $Volume ?
	$self->tieOrSpaceConnect(
		$self->format_keyword("volume"),
		$Volume
	) .
	($Series ? " " . $self->format_keyword("of") . " " .
		$self->outDoc->italic($Series) : ''
	)
	: ();
}
sub format_number { my ($self) = @_;
  my $Number = $self->entry('Number');
  return $Number ?
	$self->tieOrSpaceConnect(
		$self->format_keyword("number"),
		$Number
	) : ();
}
sub format_number_series { my ($self) = @_;
#  my $Volume = $self->entry('Volume');
  my $Number = $self->entry('Number');
  my $Series = $self->entry('Series');
### use "Number" when at start of sentence ....
  if( ! defined $Number ) { return (); }
  return
  	$self->tieOrSpaceConnect(
		$self->format_keyword("number"),
		$Number
	) .
	($Series ? " in $Series" : "");
}
sub format_volume_number_series { my ($self) = @_;
# NEW: allow both vol. and no. and series in proceedings
# (needed for CHI Letters)
  my $number = $self->entryNotEmpty('Number');
  my $series = $self->entryNotEmpty('Series');
  if( $series && not $number ) {
    return $self->format_volume_series();
  }
  my @form = ($self->format_volume(), $self->format_number_series());
  return @form;
}
sub format_edition { my ($self) = @_;
  my $Edition = $self->entry('Edition');
  return () unless defined($Edition);
  my $num = Biblio::Util::ordnumber($Edition);
  #print "edition: $Edition ", ($num ? "is number $num" : "is no number");
  # if it's no number, just return the entry
  return $Edition unless defined($num);
  return $self->tieOrSpaceConnect($Edition, $self->format_keyword("edition"));
}
sub format_date { my ($self, $check) = @_;
  my $Month = $self->outDoc->formatRange($self->entry('Month'));
  my $Year = $self->entry('Year', $check);
  return ($Year && $Month) ? "$Month $Year" :
	($Year ? $Year : ());
}
sub format_pages { my ($self) = @_;
  my $Pages = $self->entry('Pages');
  return $Pages ?
	 $self->tieOrSpaceConnect(
	  $self->format_keyword(
	   $self->multi_page_check($Pages) ? "pages" : "page"),
	  $self->outDoc->formatRange($Pages))
	: ();
}
sub format_vol_num_pages { my ($self) = @_;
# return "volume(number):pages" or "pp. pages"
  my $Volume = $self->entry('Volume');
  my $Number = $self->entry('Number');
  return $self->format_pages()
	unless ($Volume || $Number);
  my $Pages = $self->outDoc->formatRange($self->entry('Pages'));
  return ($Volume ? $Volume : '') .
	($Number ? "($Number)" : '') .
	($Pages ? ":$Pages" : '');
}
sub format_chapter_pages { my ($self) = @_;
  my $Chapter = $self->entry('Chapter');
  my $Pages = $self->entry('Pages');
  return $self->format_pages()
	unless $Chapter;
  return ($self->tieOrSpaceConnect(
		$self->format_keyword("chapter"),
		$Chapter),
	($Pages ? $self->format_pages() : ()));
}
sub format_booktitle { my ($self, $check) = @_;
  my $SuperTitle = $self->entry('SuperTitle', $check);
  return $SuperTitle ?
	$self->outDoc->italic($SuperTitle) :
	();
}
sub format_in_ed_booktitle { my ($self, $check) = @_;
  my $SuperTitle = $self->entry('SuperTitle', $check);
  $SuperTitle = $SuperTitle ? $self->outDoc->italic($SuperTitle) : ();
  return () unless $SuperTitle;
  return $self->entryNotEmpty('Editors') ?
	"In " . $self->format_editors() . ", $SuperTitle" :
	"In $SuperTitle";
}
sub format_techrep_number { my ($self) = @_;
# FUNCTION {format.tr.number}
  my $type = $self->format_type("Technical Report");
  my $Number = $self->entry('Number');
  return $Number ?
	$self->tieOrSpaceConnect($type, $Number) :
	$type;
}

# new methods

sub format_address { my ($self) = @_;
  #### CAUTION: This currently looks both for address and location ..... well ....
  return $self->entryNotEmpty('Address') ?
	$self->entry('Address') :
	$self->entry('Location');
}
sub format_publisher { my ($self) = @_;
  return $self->entry('Publisher');
}
sub format_institution { my ($self) = @_;
# an institution could also be an organization or school.
# no idea, why this is separated in bibtex ...
  return $self->entry('Institution')
	  || $self->entry('Organization')
	  || $self->entry('School');
}
sub format_journal { my ($self) = @_;
  return $self->outDoc->italic($self->entry('Journal', 1));
}
sub format_organization { my ($self) = @_;
  return $self->entry('Organization')
  	  || $self->entry('Institution')
	  || $self->entry('School');
}
sub format_school { my ($self) = @_;
  return $self->entry('School');
}
sub format_howpublished { my ($self, $check) = @_;
	if( $self->entryNotEmpty('HowPublished') ) {
		return $self->entry('HowPublished');
	}
	if( $self->entryNotEmpty('SuperTitle') ) {
		$self->warn("Using SuperTitle instead of HowPublished in ". $self->refID());
		return $self->entry('SuperTitle');
	}
	return $self->entry('HowPublished', $check);
}

sub format_language { my ($self) = @_;
# for IEEE(TR) -- support for non-english sources
  my $lang = $self->entry('Language');
  return () unless( defined($lang) );
  my $default_lang = $self->defaultLanguage();
  return $lang eq $default_lang
    ? ()
	: '(in ' . $self->format_keyword($lang) . ')';
}

sub format_urldate { my ($self, $check) = @_;
# date of URL access
  my $date = $self->format_date();
  return $date ? "($date)" : ();
}
sub format_url { my ($self, $check) = @_;
  my $url = $self->entry('Source', $check);
  return () unless( $url );
  # try to look for hyperlinks
  my @urls = split(/,\s*/, $url);
  return join(", ",
	map($self->outDoc->hyperlink($_), @urls));
}
sub format_annote { my ($self) = @_;
  return $self->entry('Annote');
}
sub format_trailer { my ($self, @exclude) = @_;
# write additional information:
# URL, file, annotation etc.
  my %include = map(($_ => $self->option("include$_")), (
	'URL',
	'Annote',
	));
  my $x; foreach $x (@exclude) { $include{$x} = 0 }
  return (
	($include{'URL'} ? [ $self->format_url() ] : ()),
	($include{'Annote'} ? [ $self->format_annote() ] : ()),
	);
}


#
#
# formating methods for different bib types
#
#

sub sortkey_article { my ($self) = @_; return $self->sortkey_authors(); }
sub format_article { my ($self) = @_;
  return [
	[ $self->format_authors() ], # if it's a journal, authors is empty
	[ $self->format_title() ],	 # if it's a journal, the title is empty
	[ [
		$self->format_journal(1),
		$self->format_vol_num_pages(),
		$self->format_date(1),
	] ],
	$self->format_trailer(),
	];
}
sub sortkey_book { my ($self) = @_; return $self->sortkey_authors_or_editors(); }
sub format_book { my ($self) = @_;
  return [
	[ $self->format_authors_or_editors()
	],
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_series(),
	] ],
	[
	  $self->format_number_series(),
	  [
		$self->format_publisher(1),
		$self->format_address(),
		$self->format_edition(),
		$self->format_date(1),
	  ],
	],
	$self->format_trailer(),
	];
}

sub sortkey_booklet { my ($self) = @_; return $self->sortkey_authors(); }
sub format_booklet { my ($self) = @_;
### this is simplyfied: always generate a new block
### between title and howpublished/address ...
  return [
	[ $self->format_authors() ],
	[ $self->format_title() ],
	[ [
		$self->format_howpublished(),
		$self->format_address(),
		$self->format_date(),
	] ],
	$self->format_trailer(),
	];
}

sub sortkey_inbook { my ($self) = @_; return $self->sortkey_authors_or_editors(); }
sub format_inbook { my ($self) = @_;
  return [
	[ $self->format_authors_or_editors()
	],
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_series(),
		$self->format_chapter_pages(),
	] ],
	[
	  $self->format_number_series(),
	  [
		$self->format_publisher(1),
		$self->format_address(),
		$self->format_edition(),
		$self->format_date(1),
	  ],
	],
	$self->format_trailer(),
	];
}

sub sortkey_incollection { my ($self) = @_; return $self->sortkey_authors(); }
sub format_incollection { my ($self) = @_;
  return [
	[ $self->format_authors(1) ],
	[ $self->format_title(1) ],
	[ [
		$self->format_in_ed_booktitle(1),
		$self->format_volume_number_series(),
		$self->format_chapter_pages(),
	  ],
	  [
		$self->format_publisher(1),
		$self->format_address(),
		$self->format_edition(),
		$self->format_date(1),
	] ],
	$self->format_trailer(),
	];
}

sub sortkey_inproceedings { my ($self) = @_; return $self->sortkey_authors(); }
sub format_inproceedings { my ($self) = @_;
  return [
	[ $self->format_authors(1) ],
	[ $self->format_title(1) ],
  (($self->entryNotEmpty('Address') ||
   ($self->entryNotEmpty('Location'))) ? #### see format_address
	[ [
		$self->format_in_ed_booktitle(1),
		$self->format_volume_number_series(),
		$self->format_pages(),
		$self->format_address(),
		$self->format_date(1),
	  ],
	  [
		$self->format_organization(),
		$self->format_publisher(),
	] ]
  : # Address empty
    (($self->entryNotEmpty('Organization') ||
      $self->entryNotEmpty('Publisher')) ?
	[ [
		$self->format_in_ed_booktitle(1),
		$self->format_volume_number_series(),
		$self->format_pages(),
	  ],
	  [
		$self->format_organization(),
		$self->format_publisher(),
		$self->format_date(1),
	] ]
    : # Publisher and Organization empty
	[ [
		$self->format_in_ed_booktitle(1),
		$self->format_volume_number_series(),
		$self->format_pages(),
		$self->format_date(1),
	] ],
    )
  ),
	$self->format_trailer(),
	];
}

sub sortkey_manual { my ($self) = @_; return $self->sortkey_authors_or_organization(); }
sub format_manual { my ($self) = @_;
  my $author = $self->entryNotEmpty('Authors');
  my $org = $self->entryNotEmpty('Organization');
  my $addr = $self->entryNotEmpty('Address');

  if($author) {
    return [
	[ $self->format_authors(1) ],
    ($org || $addr ? (
	[ $self->format_title_for_book(1) ],
	[ [
		$self->format_organization(),
		$self->format_address(),
		$self->format_edition(),
		$self->format_date(),
	] ]
    ) : ( # no org and no addr
	[ [
		$self->format_title_for_book(1),
		$self->format_edition(),
		$self->format_date(),
	] ]
    ) ),
	$self->format_trailer(),
	];
  }
  if( $org ) {
    return [
	[ [
		$self->format_organization(),
		$self->format_address(),
	] ],
	[ [
		$self->format_title_for_book(1),
		$self->format_edition(),
		$self->format_date(),
	] ],
	$self->format_trailer(),
	];
  }
  # no author and no organization, but an address
  if( $addr ) {
    return [
	[ [
		$self->format_title_for_book(1),
	] ],
	[ [
		$self->format_address(),
		$self->format_edition(),
		$self->format_date(),
	] ],
	$self->format_trailer(),
	];
  }
  # no author, org., addr ...
  return [
	[ [
		$self->format_title_for_book(1),
		$self->format_edition(),
		$self->format_date(),
	] ],
	$self->format_trailer(),
	];
}

sub sortkey_thesis { my ($self) = @_; return $self->sortkey_authors(); }
sub format_thesis { my ($self, $default_type) = @_;
### NEW -> combined masterthesis and phdthesis
### and new StarOffice plain thesis
  return [
	[ $self->format_authors(1) ],
	[ $self->format_title(1) ],
	[ [
		$self->format_type($default_type || "thesis"),
		$self->format_school(1),
		$self->format_address(),
		$self->format_date(1),
	] ],
	$self->format_trailer(),
	];
}

sub sortkey_masterthesis { my ($self) = @_; return $self->sortkey_thesis(); }
sub format_masterthesis { my ($self) = @_;
  return $self->format_thesis("Master's thesis");
}

sub sortkey_misc { my ($self) = @_; return $self->sortkey_authors(); }
sub format_misc { my ($self) = @_;
### this is simplyfied: always generate a new block
### between authors, title, and howpublished ...
### MISSING: check
  return [
	[ $self->format_authors() ],
	[ $self->format_title() ],
	[ [
		$self->format_howpublished(1),
		$self->format_date(1),
	] ],
	[ $self->format_annote() ],
	$self->format_trailer('Annote'), # exclude Annote
	];
}

sub sortkey_phdthesis { my ($self) = @_; return $self->sortkey_thesis(); }
sub format_phdthesis { my ($self) = @_;
  return $self->format_thesis("PhD thesis");
}

sub sortkey_proceedings { my ($self) = @_; return $self->sortkey_editors_or_organization(); }
sub format_proceedings { my ($self) = @_;
  my $editor = $self->entryNotEmpty('Editors');
  my $addr = $self->entryNotEmpty('Address') || $self->entryNotEmpty('Location');
  my $org = $self->entryNotEmpty('Organization');
  my $publ = $self->entryNotEmpty('Publisher');
  return [
	[
  ($editor ?
	$self->format_editors() :
	$self->format_organization()
  )
	],
  ($addr ?
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_number_series(),
		$self->format_address(),
		$self->format_date(1),
	  ],
	  [
    ($editor ?
		$self->format_organization()
    : () # no editor, the organization is already placed at the top
    ),
		$self->format_publisher(),
	] ]
  : # no addr
    ($editor ?
      ($org || $publ ?
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_number_series(),
	  ],
	  [
 		$self->format_organization(),
		$self->format_publisher(),
		$self->format_date(1),
	] ]
      : # no org, no publ
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_number_series(),
		$self->format_date(1),
	] ]
      )
    : # no editor, the organization is already placed at the top
      ($publ ?
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_number_series(),
	  ],
	  [
		$self->format_publisher(),
		$self->format_date(1),
	] ]
      : # no publ
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_number_series(),
		$self->format_date(1),
	] ]
      )
    ),
  ),
	$self->format_trailer(),
	];
}

sub sortkey_report { my ($self) = @_; return $self->sortkey_authors(); }
sub format_report { my ($self) = @_;
  return [
	[ $self->format_authors(1) ],
	[ $self->format_title(1) ],
	[ [
		$self->format_techrep_number(),
		$self->format_institution(1),
		$self->format_address(),
		$self->format_date(1),
	] ],
	$self->format_trailer(),
	];
}

sub sortkey_unpublished { my ($self) = @_; return $self->sortkey_authors(); }
sub format_unpublished { my ($self) = @_;
  return [
	[ $self->format_authors(1) ],
	[ $self->format_title(1) ],
	$self->format_trailer(),
	$self->format_date(),
	];
}

sub sortkey_email { my ($self) = @_; return $self->sortkey_unpublished(); }
sub format_email { my ($self) = @_; return $self->format_unpublished(); }

sub sortkey_web { my ($self) = @_; return $self->sortkey_authors(); }
sub format_web { my ($self) = @_;
  return [
	[ [
		$self->format_authors(),
		$self->format_title(1),
		$self->format_booktitle(),
		$self->format_edition(),
		$self->format_organization(),
		$self->format_address(),
		$self->spaceConnect(
		  $self->format_url(1),
		  $self->format_urldate()
		  ),
	] ],
	$self->format_trailer('URL'), # exclude URL
	];
}

sub sortkey_video { my ($self) = @_; return $self->sortkey_misc(); }
sub format_video { my ($self) = @_; return $self->format_misc(); }

sub sortkey_talk { my ($self) = @_; return $self->sortkey_misc(); }
sub format_talk { my ($self) = @_; return $self->format_misc(); }
#  sub format_talk { my ($self) = @_; return $self->format_misc(); }

sub sortkey_poster { my ($self) = @_; return $self->sortkey_inproceedings(); }
sub format_poster { my ($self) = @_; return $self->format_inproceedings(); }

sub sortkey_patent { my ($self) = @_; return $self->sortkey_misc(); }
sub format_patent { my ($self) = @_;
# <Title>. <ReportType[United States Patent]> no. <Number>, <Month>, <Year>.
# Inventors: <Authors>. Assignee: <Institution|Organization>, <Address>
  return $self->format_misc();
}

sub sortkey_cdrom { my ($self) = @_; return $self->sortkey_misc(); }
sub format_cdrom { my ($self) = @_; return $self->format_misc(); }

1;

#
# $Log: BibItemStyle.pm,v $
# Revision 1.1.1.1  2004/09/02 13:53:36  tandler
# Version 2.0 with new dir structure (thanks to krugar)
#
# Revision 1.21  2004/03/29 13:11:37  tandler
# fix double dots in output
#
# Revision 1.20  2003/12/22 21:52:53  tandler
# new function "first_initials" to format first names as initials
#
# Revision 1.19  2003/12/01 11:20:21  tandler
# HowPublished has a capital "P" ...
# bugfix for formatting keyword ("chapter") -- this is toni's change
# use "Location" as well as "Address" at several places, even if this might be wrong ... ok, not nice, but anyway ...
#
# Revision 1.17  2003/06/12 22:03:40  tandler
# support for logMessage() and warn()
# fields: Organization, Institution, School more tolerant
# fix in et al. handling
#
# Revision 1.16  2003/05/22 11:55:49  tandler
# the "talk" is now formatted just like a inproceedings (paper), but with optional publisher.
#
# Revision 1.15  2003/04/14 09:47:31  ptandler
# new options "etalNumber", "itemBokmark"
#
# Revision 1.14  2003/01/27 21:12:03  ptandler
# move split_names etc. to Bib::Util
#
# Revision 1.13  2003/01/14 11:08:09  ptandler
# {space} as label separator
#
# Revision 1.12  2002/11/05 18:28:55  peter
# names
# format vol/nr (space/tie connect)
#
# Revision 1.11  2002/11/03 22:15:33  peter
# format names
#
# Revision 1.10  2002/10/01 21:25:09  ptandler
# - bookmarks in IEE style
# - format names started (initials, last)
# - number_series works now without series
#
# Revision 1.9  2002/09/22 11:00:02  peter
# allow ';' as separator for names (author, editor etc.)
#
# Revision 1.8  2002/08/22 10:40:05  peter
# - fix option "include-label"
#
# Revision 1.7  2002/08/08 08:25:23  Diss
# - new option "include-label"
# - new option "label-separator"
# - improved sorting: transform umlaute, skip non-alpha chars
# - renamed field "URL" to "Source"
#
# Revision 1.6  2002/05/27 10:23:43  Diss
# small fixes ...
#
# Revision 1.5  2002/04/03 10:17:58  Diss
# - keyword styles + language (e.g. EnglishAbbrev)
# - sortkeys with special chars (äöü etc)
# - use correct keyword for phdthesis etc. (OrigCiteType)
# - support 'Key' field
# - include 'Language' in bibitem
# - fix. chapter + pages if chapter is undef
# - put URL-access date in parentheses
#
# Revision 1.4  2002/03/28 13:23:00  Diss
# added pbib-export.pl, with some support for bp
#
# Revision 1.3  2002/03/27 10:00:50  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.2  2002/03/22 17:31:02  Diss
# small changes
#
# Revision 1.1  2002/03/18 11:15:47  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#