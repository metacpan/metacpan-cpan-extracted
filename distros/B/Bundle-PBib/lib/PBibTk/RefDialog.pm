# --*-Perl-*--
# $Id: RefDialog.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBibTk::RefDialog;
use strict;
use warnings;

use Tk;
use Tk::LabFrame;
use Tk::LabEntry;
use Tk::TextUndo;

# for debugging
use Data::Dumper;

# PBib modules
use PBib::ReferenceConverter;
use PBib::ReferenceStyle;
use PBib::ReferenceStyle::BookmarkLink;
use PBib::BibliographyStyle;
use PBib::BibItemStyle;
use PBib::BibItemStyle::IEEE;
use PBib::BibItemStyle::IEEETR;
use PBib::BibItemStyle::ElsevierJSS;
use PBib::LabelStyle;
use PBib::LabelStyle::CiteKey;
use PBib::Document;
use PBib::Document::PBib;

# own modules
use PBibTk::Main;
#  use LitRefs;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}


#
#
#

sub new {
  my $class = shift;
  my ($ui, $paper) = @_;
  my $dialog = {
    'pBibTkUI' => $ui,
    'paper' => $paper,
  };
  return bless $dialog, $class;
}

sub show {
  my $self = shift;
  $self->window()->focus();
}

#
# access methods
#

sub window {
	my $self = shift;
	my $win = $self->{'window'};
	return $win if defined($win);
	
	my $ui = $self->pBibTkUI();
	$win = $ui->rootWindow()->Toplevel();
        my $titel = $self->title();
	$win->configure(
		-title => $titel,
		-width => 700,
		-height => 600,
	);
	$self->{'window'} = $win;
	$self->initWidgets($win);
	$self->addPaperHeading();
	$self->addPaperRefIEEETR();
	$self->addPaperFields();
	$self->textWidget()->mark(qw/set insert 0.0/);
	$self->textWidget()->see("0.0");
	return $win;
}

#  sub litRefs { my $self = shift; return $self->litUI()->litRefs(); }
sub pBibTkUI { my $self = shift; return $self->{'pBibTkUI'}; }
sub title {
	my $self = shift; my $title = $self->{'title'};
	return defined($title) ? $title : $self->defaultTitle();
}
sub defaultTitle { my ($self, $paper) = @_;
	$paper = $self->paper() unless defined $paper;
	my $CiteKey = $paper->{'CiteKey'} || '<<no CiteKey>>';
	my $Category = $paper->{'Category'} || '<<no Category>>';
	my $Recommendation = $paper->{'Recommendation'};
	my $Identifier = $paper->{'Identifier'} || '<<no Identifier>>';
	return "$CiteKey [$Category] " . ($Recommendation ? "($Recommendation) " : '' )  . $Identifier;
}
sub paper {
	my $self = shift;
#	$self->{'paper'} = $self->converter('refs' => $self->refs())->entries($self->{'paper'}->{'CiteKey'});
	return $self->{'paper'};
#	return $self->{'paper'} = $self->converter('refs' => $self->refs())->entries($self->{'paper'}->{'CiteKey'});
	#  return $self->{'paper'};
}

sub refs {
	my $self = shift;
	my $refs = $self->{'refs'};
	unless( defined($refs) ) {
		$refs = $self->pBibTkUI()->refs();
	}
	return $refs;
}
sub biblio { my $self = shift; $self->pBibTkUI()->biblio(); }

#
# widgets
#


sub initWidgets {
  my ($self, $win) = @_;

  # menu inside a menu frame

  #  my $mf = $win->Frame()->grid(-sticky => 'ew');
  #  $mf->gridColumnconfigure(1, -weight => 1);
  #  $self->initMenu($mf, $win);
  my $mf = $win->Menu(-type => 'menubar');
  $win->configure(-menu => $mf);
  $self->initMenu($mf, $win);

  # text widget

  my $off = 0;
  my $list = $win->Scrolled('TextUndo',
		-scrollbars => 'se',
		-wrap => 'word',
		-setgrid => 'true',
		-exportselection => 'true',
#		-font => $FONT,
	)->form(
	-t => ['%0',0],
	-l => ['%0',0],
	-r => ['%100',0],
	-b => ['%100', $off]);
  $self->{'textWidget'} = $list;
  $list->tag(qw/configure list
			-lmargin1 20m
			-lmargin2 20m
			-spacing1 1p
		/);
  $list->tag(qw/configure field
			-tabs 20m
			-spacing1 3p
			-spacing2 0p
			-spacing3 0p
			-font T_bold
		/);
  $list->tag(qw/configure head
			-font H_big_bold
		/);
}
sub initMenu {
	my ($self, $mf, $win) = @_;
	my $cmd;
	
	# ref menu
	
	#  my $mbr = $mf->Menubutton(-text => 'References');
	#  $mbr->grid(-row => 0, -column => 0, -sticky => 'w');
	my $mbr = $mf->cascade(-label => '~References'); ###, -tearoff => 0);
	$mbr->command(-label => 'Insert Fields', -command => [ $self, 'addPaperFields' ] );
	$mbr->command(-label => 'Insert All Fields', -command => [ $self, 'addPaperFields', undef, 1 ] );
	$mbr->command(-label => 'Insert CSCW Ref.', -command => [ $self, 'addPaperRefCSCW' ] );
	$mbr->command(-label => 'Insert IEEE Ref.', -command => [ $self, 'addPaperRef', undef, 'IEEE' ] );
	$mbr->command(-label => 'Insert IEEETR Ref.', -command => [ $self, 'addPaperRef', undef, 'IEEETR' ] );
	$mbr->command(-label => 'Insert ElsevierJSS Ref.', -command => [ $self, 'addPaperRef', undef, 'ElsevierJSS' ] );
	$mbr->separator;
	$mbr->command(-label => 'Close', -command => sub {$win->destroy();});
	
	# Biblio::BP format menu
	
	my $mb = $mf->cascade(-label => '~Format'); ###, -tearoff => 0);
	$cmd = [ $self, 'importText' ];
	$mb->command(-label => "~Store reference", -command => $cmd,
				 -accelerator => 'Ctrl-S' );
	$win->bind('<Control-Key-S>' => $cmd);
	
	$mb->separator();
	
	my %unsupported_export = qw(
		auto 1 canon 1
		cstra 1
		inspec 1
		inspec4 1
		medline 1
		melvyl 1
		);
	foreach my $f (Biblio::BP::querySupportedFormats()) {
		next if exists($unsupported_export{$f});
		$mb->command(-label => "Export as $f", -command => [$self, "exportAsText", $f]);
	}
}

sub textWidget { my $self = shift; return $self->{'textWidget'}; }


#
# text
#


sub addPaperHeading {
	my ($self, $paper) = @_;
	$paper = $self->paper() unless defined($paper);
	my $title = $self->defaultTitle($paper);
	my $t = substr($paper->{'Title'} || '<<no title>>', 0, 70);
	my $a = substr($paper->{'Authors'} || '<<no author(s)>>', 0, 70);
	my $s = substr($paper->{'SuperTitle'} || $paper->{'Journal'} 
		|| '', 0, 65);
	my $y = $paper->{'Year'} || '<<no year>>';
	my $summary = "$t\n$a\n$s\n$y";
#	$self->textWidget()->insert("end", "$title:\n\n$summary\n\n");
	$self->textWidget()->insert("end", "$title:\n\n", "head");
}
sub addPaperFields {
	my ($self, $paper, $allFields) = @_;
	$paper = $self->paper() unless defined($paper);
	my $textWidget = $self->textWidget();
	my %fields = %{$paper};
	unless( $allFields ) {
		# this is displayed elsewhere (e.g.title)
		delete $fields{'CiteKey'};
		delete $fields{'CiteType'};
		delete $fields{'Category'};
		delete $fields{'Identifier'};
		delete $fields{'Recommendation'};
		# internal & uninteresting
		delete $fields{'CrossRef__expanded__'};
		delete $fields{'BibDate'};
		delete $fields{'BibSource'};
		delete $fields{'OrigFormat'};
	}
	$textWidget->insert("end", $paper->{'CiteType'}. "\n", "head");
	foreach my $f (sort(keys(%fields))) {
		if( defined($paper->{$f}) ) {
			$textWidget->insert("end", "$f", "field");
			$textWidget->insert("end", "\t$paper->{$f}\n",
						"list");
		}
	}
	$textWidget->insert("end", "\n");
}

sub addPaperRefIEEE {
	my ($self, $paper, $style) = @_;
	$self->addPaperRef($paper, $style,
		'itemStyle'	=> new PBib::BibItemStyle::IEEE,
	);
}
sub addPaperRefIEEETR {
	my ($self, $paper, $style) = @_;
	$self->addPaperRef($paper, $style,
		'itemStyle'	=> new PBib::BibItemStyle::IEEETR
	);
}
sub addPaperRefElsevierJSS {
	my ($self, $paper, $style) = @_;
	$self->addPaperRef($paper, $style,
		'itemStyle'	=> new PBib::BibItemStyle::ElsevierJSS,
	);
}
sub addPaperRefCSCW {
	my ($self, $paper, $style) = @_;
	$self->addPaperRef($paper, $style);
}

sub addPaperRef {
	my $self = shift;
	my $paper = shift;
	my $style = shift;
	my %args = @_;
	$paper = $self->paper() unless defined($paper);
	if( $style ) {
		$args{'itemStyle'} = "PBib::BibItemStyle::$style"->new();
	}
	
	my $conv = $self->conv(
		#  'refs' => {
			#  $paper->{'CiteKey'} => $paper
		#  },
#		'refs' => $self->refs(),
#		'itemOptions' => {
#			'include-label' => 0,
#		},
#		%args
	);
	my $text = $conv->itemStyle()->formatWith($paper->{'CiteKey'});
#	$text = $conv->outDoc()->replace_xchars($text);
	$self->textWidget()->insert("end", "$text\n\n");
	$self->textWidget()->mark(qw/set insert end/);
	#  $self->textWidget()->yview(-pickplace, "end"); # or use "see"
	$self->textWidget()->see("end");
}



#
#
# BP
#
#

sub importText {
	my ($self, $format) = @_;
	print STDERR "importText\n";
	my $text = $self->textWidget()->get("0.0", "end");
	$text =~ s/^\s*>+\s*(\w+).*\n//;
	$format = $1 unless $format;
	unless( $format ) {
		$format = 'bibtex' if $text =~ /^\s*@/;
		$format = 'endnote' if $text =~ /^\s*%/;
		$format = 'rfc1807' if $text =~ /\w::\s/;
	}
	unless( $format ) {
		print STDERR "cannot identify format!\n";
		return;
	}
	print STDERR "import using format $format\n";
	print STDERR $text;
	
	Biblio::BP::format($format, 'canon:8859-1');
	%bp_util::glb_keyreg = (); # clear key registry
print "tocanon - explode\n";
	my %rec = Biblio::BP::tocanon(Biblio::BP::explode($text));
print "--> ", Dumper(\%rec);
print "canon_to_pbib\n";
	%rec = Biblio::BP::canon_to_pbib(%rec);
print "--> ", Dumper(\%rec);
	$self->biblio()->storePaper(\%rec)
}

sub exportAsText {
	my ($self, $format) = @_;
	print STDERR "export as $format\n";
	
	Biblio::BP::format('canon:8859-1', $format);
	%bp_util::glb_keyreg = (); # clear key registry
	my %rec = Biblio::BP::pbib_to_canon(%{$self->paper()});
	my $text = Biblio::BP::implode(Biblio::BP::fromcanon(%rec));
	
	#  print "delete:\n";
	$self->textWidget()->delete("0.0", "end");
	#  print "insert:\n";
	$self->textWidget()->insert("end", "\n> $format\n\n$text\n\n");
	#  print "mark:\n";
	$self->textWidget()->mark(qw/set insert end/);
	$self->textWidget()->see("0.0"); # move cursor to beginning
	#  $self->textWidget()->tagAdd('sel', "0.0", 'end'); # set selection??
}


#
#
# access to PBib
#
#

sub conv {
	my $self = shift;
	return $self->pBibTkUI()->{'conv'};
}


#myline runter --------------------------------------------------------
sub formatRefInfos {
	my $self = shift;
	my $paper = shift;
	my $conv = shift;

	my $head = $self->defaultTitle($paper);
	my $ref = $self->formattedRefIEEETR($paper, $conv);
	return ($head, $ref);
}

sub formattedRefIEEETR {
	my ($self, $paper) = @_;
	my $back = $self->formattedRef($paper,
		'itemStyle'	=> new PBib::BibItemStyle::IEEETR
	);
	return $back;
}
sub formattedRef {
	my $self = shift;
	my $paper = shift;
	my %args = @_;
	my $text = $self->conv()->itemStyle()->formatWith($paper->{'CiteKey'});
	return $text;
}
#myline hoch --------------------------------------------------------


1;

#
# $Log: LitUIRefDialog.pm,v $
# Revision 1.21  2004/03/30 19:19:39  krugar
# refactored: 
# 	LitUIRefDialog -> LitUI::RefDialog 
#	LitUISearchDialog -> LitUI::SearchDialog 
#

# Revision 1.20  2004/03/29 13:12:34  tandler
# box to see refs
#
# Revision 1.19  2003/12/22 21:59:41  tandler
# toni's changes: include explaination field in UI
#
# Revision 1.18  2003/11/20 17:33:44  gotovac
# reveals entry by clicking on citekey (fast)
#
# Revision 1.17  2003/06/12 22:18:03  tandler
# use native menubar widgets
# support for export reference as several different formats (using bp)
# new importText() is not yet very stable ...
#
# Revision 1.16  2003/04/16 15:02:02  tandler
# show correctly expanded references (CrossRef)
#
# Revision 1.15  2003/02/20 09:19:26  ptandler
# ignore null recommendation in title & search list
#
# Revision 1.14  2003/01/21 10:23:08  ptandler
# small fix
#
# Revision 1.13  2003/01/14 11:10:17  ptandler
# fonts and export
#
# Revision 1.12  2002/10/11 10:12:45  peter
# use PBib to write paper's reference in different styles (yet only plain text)
#
# Revision 1.11  2002/06/29 18:28:32  Diss
# new query style, focus + jump-to-by-key for all ref lists
#
# Revision 1.10  2002/06/24 10:44:27  Diss
# also show booktitle/journal
#
# Revision 1.9  2002/06/19 15:59:45  Diss
# - window is opened with focus
#
# Revision 1.8  2002/06/11 11:14:43  Diss
# fix: avoid undef warnings
#
# Revision 1.7  2002/06/06 10:34:09  Diss
# minor change
#
# Revision 1.6  2002/06/06 08:59:34  Diss
# minor change
#
# Revision 1.5  2002/06/06 07:26:04  Diss
# use Biblio::Biblio (instead of old version Biblio)
#
# Revision 1.4  2002/06/03 11:35:38  Diss
# show short paper info in window title and before the paper fields
#
# Revision 1.3  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#
# Revision 1.2  2002/03/07 12:01:21  Diss
# first version
#
# Revision 1.1  2002/02/25 12:15:56  Diss
# a kind of first start, not working yet ...
#