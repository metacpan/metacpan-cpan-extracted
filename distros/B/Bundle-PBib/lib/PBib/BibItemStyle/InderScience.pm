# --*-Perl-*--
# $Id: InderScience.pm 23 2005-07-17 19:28:02Z tandler $
#

package PBib::BibItemStyle::InderScience;
use strict;
use warnings;
#use English;

=head1 package PBib::BibItemStyle::InderScience;

Based on the sample files from http://www.inderscience.com/
Adapted from the ElsevierJSS style:
- title with singleQuotes
- year with ()
- spaceConnect for authors, year, title
- use Vol. v, No. n, instead of v(n) for journals

=cut

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 23 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use base qw(PBib::BibItemStyle);
#  use vars qw(@ISA);
#  @ISA = qw(PBib::BibItemStyle);

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
  $self->{'keywords'} = $self->InderScience_keywords();
  return $self;
}


#
#
# access methods
#
#

sub InderScience_keywords {
  return {
	'editor' => 'Ed.',
	'editors' => 'Eds.',
	"page" => "p.",
	"pages" => "pp.",
	"volume" => "Vol.",
	"number" => "No.",
	"chapter" => "ch.",
	"PhD thesis" => "Ph.D. thesis",
	"Technical Report" => "Tech. Rep.",
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
  return $self->format_names_last_initials($names);
}

sub format_editors { my ($self, $check) = @_;
  my $eds = $self->entry('Editors', $check);
  return undef unless defined $eds;
  my $num = $self->num_names($eds);
  return $num == 0 ? () :
	($self->format_names($eds) .
	 " (" .
	 $self->format_keyword($num == 1 ? "editor" : "editors") .
	 ")"
	);
}

sub format_title { my ($self, $check) = @_;
  my $Title = $self->outDoc()->singleQuotes($self->entry('Title', $check));
  return $Title;
}
sub format_journal { my ($self) = @_;
  return $self->entry('Journal', 1);
}

sub format_date { my ($self, $check) = @_;
  my $Year = $self->entry('Year', $check);
  return () unless defined($Year);
  my $postfix = $self->labelStyle()->postfix($self->refID());
  return "($Year$postfix)";
}

sub format_in_ed_booktitle { my ($self, $check) = @_;
  my $Booktitle = $self->entry('SuperTitle', $check);
  return () unless $Booktitle;
  $Booktitle = $self->outDoc()->italic($Booktitle);
  return
	$self->entryNotEmpty('Editors') ?
		$self->format_editors() . ", $Booktitle" :
		$Booktitle;
}

sub format_vol_num_pages { my ($self) = @_;
# return "volume(number):pages" or "pp. pages"
	my $Volume = $self->entry('Volume');
	my $Number = $self->entry('Number');
	return $self->format_pages()
		unless ($Volume || $Number);
	my $Pages = $self->outDoc->formatRange($self->entry('Pages'));
	return (
		$self->tieOrSpaceConnect(
			$self->format_keyword("volume"),
			$Volume),
		$self->tieOrSpaceConnect(
			$self->format_keyword("number"),
			$Number),
		$self->format_pages(),
		);
}

sub format_addr_pub { my ($self, $check) = @_;
  my $Publisher = $self->entry('Publisher', $check);
  my $Address = $self->entry('Address');
  return () unless ($Publisher);
  return $Address ?
	"$Publisher, $Address" :
	$Publisher;
}

#
#
# sorting ...
#
#


sub sortkey_names { my ($self, $names) = @_;
  my @all_names = $self->split_names($names);
  return () unless( @all_names );
  @all_names = map( $self->last_name($_), @all_names );
  return join(" ", @all_names);
}

#
#
# formating methods for different bib types
#
#


sub format_article { my ($self) = @_;
  return [
	[
		[
			$self->spaceConnect(
				$self->format_authors(1),
				$self->format_date(1),
				$self->format_title(1),
			),
			$self->format_journal(1),
			$self->format_vol_num_pages(),
			$self->format_language(),
		]
	],
	$self->format_trailer(),
	];
}
sub format_book { my ($self) = @_;
  return [
	[
		[
			$self->spaceConnect(
				$self->format_authors_or_editors(),
				$self->format_date(1),
				$self->format_title(1),
			),
			$self->format_volume_number_series(),
			$self->format_addr_pub(1),
			$self->format_edition(),
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
	[
		[
			$self->spaceConnect(
				$self->format_authors_or_editors(),
				$self->format_date(1),
				$self->format_title(1),
			),
			$self->format_volume_number_series(),
			$self->format_addr_pub(1),
			$self->format_edition(),
			$self->format_chapter_pages(),
			$self->format_language(),
		]
	],
	$self->format_trailer(),
	];
}

sub format_incollection { my ($self) = @_;
  return [
	[
		[
			$self->spaceConnect(
				$self->format_authors(1),
				$self->format_date(1),
				$self->format_title(1),
			),
#		], [
			$self->format_in_ed_booktitle(1),
			$self->format_volume_number_series(),
			$self->format_addr_pub(1),
			$self->format_edition(),
			$self->format_chapter_pages(),
			$self->format_language(),
		]
	],
	$self->format_trailer(),
	];
}

sub format_inproceedings { my ($self) = @_;
  return $self->format_incollection();
}

sub sortkey_manual { my ($self) = @_; return $self->sortkey_authors(); }
sub format_manual { my ($self) = @_;
  ## well, free-style ...
  return [
	[ [
		$self->spaceConnect(
			$self->format_authors(),
			$self->format_title_for_book(1),
			$self->format_volume_number_series(),
		),
	#  ] ],
	#  [ [
		$self->format_organization(),
		$self->format_address(),
		$self->format_edition(),
		$self->format_date(),
		$self->format_language(),
	] ],
	$self->format_trailer(),
	];
}

sub format_thesis { my ($self, $default_type) = @_;
  return [
	[
		[
			$self->spaceConnect(
				$self->format_authors(1),
				$self->format_date(1),
				$self->format_title(1),
			),
			$self->format_type($default_type || "thesis"),
			$self->format_school(1),
			$self->format_address(),
			$self->format_language(),
		]
	],
	$self->format_trailer(),
	];
}

#sub format_masterthesis { my ($self) = @_;
#  return $self->format_thesis("Master's thesis");
#}

sub format_misc { my ($self) = @_;
  return [
	[
		[
			$self->spaceConnect(
				$self->format_authors(),
				$self->format_date(1),
				$self->format_title(),
			),
			$self->format_howpublished(),
			$self->format_language(),
		]
	],
	$self->format_trailer(),
	];
}

#sub format_phdthesis { my ($self) = @_;
#  return $self->format_thesis("PhD thesis");
#}

sub format_proceedings { my ($self) = @_;
  return $self->format_book();
}

sub format_report { my ($self) = @_;
  return [
	[
		[
			$self->spaceConnect(
				$self->format_authors(1),
				$self->format_date(1),
				$self->format_title(1),
			),
			$self->format_techrep_number(),
			$self->format_institution(1),
			$self->format_address(),
			$self->format_language(),
		]
	],
	$self->format_trailer(),
	];
}

sub format_unpublished { my ($self) = @_;
  return $self->format_misc();
}

sub format_talk { my ($self) = @_;
# a talk here is just like a conference paper, but with
# an optional publisher.
# I'd recommend to use this for workshop position paper etc.
  return [
	[
		[
			$self->spaceConnect(
				$self->format_authors(1),
				$self->format_date(1),
				$self->format_title(1),
			),
		#  ], [
			$self->format_in_ed_booktitle(1),
			$self->format_volume_number_series(),
			$self->format_addr_pub(),
			$self->format_edition(),
			$self->format_chapter_pages(),
			$self->format_language(),
		]
	],
	$self->format_trailer(),
	];
}


1;

#
# $Log: ElsevierJSS.pm,v $
# Revision 1.3  2003/05/22 11:56:06  tandler
# the "talk" is now formatted just like a inproceedings (paper), but with optional publisher.
#
# Revision 1.2  2002/11/05 18:30:44  peter
# format vol/nr (space/tie connect)
# minor fixes
#
# Revision 1.1  2002/11/03 22:16:07  peter
# new JSS style (Elsevier)
#
