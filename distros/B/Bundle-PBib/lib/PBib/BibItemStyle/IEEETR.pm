# --*-Perl-*--
# $Id: IEEETR.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBib::BibItemStyle::IEEETR;
use strict;
#use English;

=head1 package PBib::BibItemStyle::IEEETR;

% IEEE Transactions bibliography style (29-Jan-88 version)
%    numeric labels, order-of-reference, IEEE abbreviations,
%    quotes around article titles, commas separate all fields
%    except after book titles and before "notes".  Otherwise,
%    much like the "plain" family, from which this is adapted.
%
%   History
%    9/30/85	(HWT)	Original version, by Howard Trickey.
%    1/29/88	(OP&HWT) Updated for BibTeX version 0.99a, Oren Patashnik;
%			THIS `ieeetr' VERSION DOES NOT WORK WITH BIBTEX 0.98i.

This is documented at http://computer.org/...transref.html (for transactions).
Note that other IEEE CS publications use a slightly different style
http://computer.org/...refer.html

=cut

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use PBib::BibItemStyle;
use vars qw(@ISA);
@ISA = qw(PBib::BibItemStyle);

# used modules
#use ZZZZ;

# module variables
#use vars qw(mmmm);

#
#
# constructor
#
#

sub new {
  my $self = PBib::Style::new(@_);
  $self->{'keywords'} = $self->IEEETR_keywords();
  return $self;
}


#
#
# access methods
#
#

sub IEEETR_keywords {
  return {
	'editor' => 'ed.',
	'editors' => 'eds.',
	"page" => "p.",
	"pages" => "pp.",
	"volume" => "vol.",
	"number" => "no.",
	"chapter" => "ch.",
	"Technical Report" => "Tech. Rep.", # only IEEE CS-style, not IEEE TR-style ...
	};
}

sub includeLabel { my ($self) = @_;
# should the Cite label be included in the bibliography?
#
# overwrite to set default to 0
#
  return $self->option("include-label") || 0;
}

#
#
# format methods for entries
#
#

sub format_names { my ($self, $names) = @_;
  return () unless( defined($names) );
  return $self->format_names_initials_last($names);
}

sub format_title { my ($self, $check) = @_;
  my $Title = $self->entry('Title', $check);
  return $Title ?
	$self->outDoc()->doubleQuotes($self->outDoc()->bookmark($Title)) :
	$self->outDoc()->bookmark('');
}

sub format_in_ed_booktitle { my ($self, $check) = @_;
  my $Booktitle = $self->entry('SuperTitle', $check);
  $Booktitle = $Booktitle ? $self->outDoc()->italic($Booktitle) : ();
  return () unless $Booktitle;
  return $self->entryNotEmpty('Editors') ?
#	"in $Booktitle (" . $self->format_editors() . ")" : # this is the ieeetr.bst version
	"in $Booktitle, " . $self->format_editors() : # this is the computer.org/.../transref.html version
	"in $Booktitle";
}


# new methods by ieeetr.bst

sub format_addr_pub { my ($self, $check) = @_;
  my $Publisher = $self->entry('Publisher', $check);
  my $Address = $self->entry('Address');
  return () unless ($Publisher);
  return $Address ?
	"$Address: $Publisher" :
	$Publisher;
}

sub format_paddress { my ($self) = @_;
  my $Address = $self->entry('Address');
  return $Address ? "($Address)" : ();
}


#
#
# formating methods for different bib types
#
#

sub format_article { my ($self) = @_;
  return [
	[ [
		$self->format_authors(1),
		$self->spaceConnect(
		  $self->format_title(1),
		  $self->format_journal(1)
		  ),
		$self->format_volume(),
		($self->entryNotEmpty('Month') ? () :
		  $self->format_number()),
		$self->format_pages(),
		$self->format_date(1),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}
sub format_book { my ($self) = @_;
  return [
	[ $self->format_authors_or_editors()
	],
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_series(),
	] ],
	[ [
		$self->format_number_series(),
		$self->format_addr_pub(1),
		$self->format_edition(),
		$self->format_date(1),
		$self->format_language(),
	  ],
	],
	$self->format_trailer(),
	];
}

sub format_booklet { my ($self) = @_;
### this is simplyfied: always generate a new block
### between title and howpublished/address ...
  return [
	[ $self->format_authors() ],
	[ [
		$self->format_title(1),
		$self->format_howpublished(),
		$self->format_address(),
		$self->format_date(),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}


sub format_inbook { my ($self) = @_;
  return [
	[ $self->format_authors_or_editors()
	],
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_series(),
		$self->format_chapter_pages(),
	] ],
	[ [
		$self->format_number_series(),
		$self->format_addr_pub(1),
		$self->format_edition(),
		$self->format_date(1),
		$self->format_language(),
	  ],
	],
	$self->format_trailer(),
	];
}

sub format_incollection { my ($self) = @_;
  return [
	[ [
		$self->format_authors(1),
		$self->spaceConnect(
		  $self->format_title(1),
		  $self->format_in_ed_booktitle(1)
		  ),
		$self->format_volume_number_series(),
		$self->format_chapter_pages(),
		$self->format_addr_pub(1),
		$self->format_edition(),
		$self->format_date(1),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}

sub format_inproceedings { my ($self) = @_;
  return [
	[ [
		$self->format_authors(1),
		$self->spaceConnect(
		  $self->format_title(1),
		  $self->format_in_ed_booktitle(1)
		  ),
		$self->format_volume_number_series(),
		$self->format_paddress(),
		$self->format_pages(),
		$self->format_organization(),
		$self->format_publisher(),
		$self->format_date(1),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}

sub sortkey_manual { my ($self) = @_; return $self->sortkey_authors(); }
sub format_manual { my ($self) = @_;
# The style described in computer.org...transref.html is different
# from the one implemented in ieeetr.bst
# I acutally use the refer.html version, not swapping organization and address ...
# and: the example given include number and volume
# I also changed it to give volume, number, and series ...
# please forgive me ... :-)
  return [
	[ [
		$self->format_authors(),
		$self->format_title_for_book(1),
		$self->format_volume_number_series(),
	] ],
	[ [
		$self->format_organization(),
		$self->format_address(),
		$self->format_edition(),
		$self->format_date(),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}
sub format_manual_bibtex { my ($self) = @_;
# this is the version implemented in ieeetr.bst
  my $author = $self->entryNotEmpty('Author');
  my $org = $self->entryNotEmpty('Organization');
  my $addr = $self->entryNotEmpty('Address');

  if($author) {
    return [
	[ [
		$self->format_authors(1),
		$self->format_title_for_book(1),
	] ],
    ($org || $addr ? (
	[ [
		$self->format_organization(),
		$self->format_address(),
		$self->format_edition(),
		$self->format_date(),
		$self->format_language(),
	] ]
    ) : ( # no org and no addr
	[ [
		$self->format_edition(),
		$self->format_date(),
		$self->format_language(),
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
		$self->format_language(),
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
		$self->format_language(),
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
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}

sub format_thesis { my ($self, $default_type) = @_;
### NEW -> combined masterthesis and phdthesis
### and new StarOffice plain thesis
  return [
	[ [
		$self->format_authors(1),
		$self->spaceConnect(
		  $self->format_title(1),
		  $self->format_type($default_type || "thesis")
		  ),
		$self->format_school(1),
		$self->format_address(),
		$self->format_date(1),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}

sub format_masterthesis { my ($self) = @_;
  return $self->format_thesis("Master's thesis");
}

sub format_misc { my ($self) = @_;
### this is simplyfied: always generate a new block
### between authors, title, and howpublished ...
### MISSING: check
  return [
	[ [
		$self->format_authors(),
		$self->format_title(),
		$self->format_howpublished(),
		$self->format_date(1),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}

sub format_phdthesis { my ($self) = @_;
  return $self->format_thesis("PhD thesis");
}

sub format_proceedings { my ($self) = @_;
  my $editors = $self->format_editors() || $self->format_authors();
  my $addr = $self->entryNotEmpty('Address');
  my $org = $self->format_organization();
  my $publ = $self->entryNotEmpty('Publisher');
  return [
	[
	  ( $editors ? $editors : $org )
	],
	[ [
		$self->format_title_for_book(1),
		$self->format_volume_number_series(),
		$self->format_paddress(),
		( $editors ? $org : () # no editor, the organization is already placed at the top
		),
		$self->format_publisher(),
		$self->format_date(1),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}

sub format_techreport { my ($self) = @_;
  return [
	[ [
		$self->format_authors(1),
		$self->spaceConnect(
		  $self->format_title(1),
		  $self->format_techrep_number()
		  ),
		$self->format_institution(1),
		$self->format_address(),
		$self->format_date(1),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}

sub format_unpublished { my ($self) = @_;
  return [
	[ [
		$self->format_authors(1),
		$self->format_title(1),
### blank.sep ....
	] ],
	$self->format_trailer(),
	$self->format_date(),
	];
}

1;

#
# $Log: IEEETR.pm,v $
# Revision 1.6  2004/03/29 13:11:56  tandler
# --
#
# Revision 1.5  2003/11/20 16:08:06  gotovac
# reveals clicked CiteKey
#
# Revision 1.4  2002/11/03 22:15:52  peter
# fix: Editors
#
# Revision 1.3  2002/10/01 21:27:51  ptandler
# works now again with new pbib version
#
# Revision 1.2  2002/08/08 08:26:04  Diss
# fixed package name
#
# Revision 1.1  2002/03/18 11:15:47  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#

