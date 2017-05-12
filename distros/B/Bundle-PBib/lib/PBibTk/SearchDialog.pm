# --*-Perl-*--
# $Id: SearchDialog.pm 11 2004-11-22 23:56:20Z tandler $
#

package PBibTk::SearchDialog;
use strict;

use Tk;
use Tk::LabFrame;
use Tk::LabEntry;

use Data::Dumper;

use PBibTk::Main;
# use LitRefs;
use PBibTk::RefDialog;
#use LitUI::SearchDialog;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 11 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

#
# constants
#

our $defwidth_list = 96;
our $defheight_list = 16;
our $maxheight_list = 20;
our $maxlength_title = 40;
our $maxlength_author = 32;


#
#
#

sub new {
  my $class = shift;
  my ($ui, $title, $pattern, $queryFields, $resultFields) = @_;
  my $dialog = {
    'pBibTkUI' => $ui,
    'title' => $title,
    'queryFields' => $queryFields,
    'resultFields' => $resultFields,
    'pattern' => $pattern,
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
  my $title = $self->{'title'};
  $win = $ui->rootWindow()->Toplevel();
  $win->configure(
	-title => $self->title(),
	-width => 700,
	-height => 600,
	);
  $self->{'window'} = $win;
  $self->initWidgets($win);
  $self->updateResults();
  return $win;
}

# sub litRefs { my $self = shift; return $self->litUI()->litRefs(); }
sub biblio { my $self = shift; return $self->pBibTkUI()->biblio(); }
sub pBibTkUI { my $self = shift; return $self->{'pBibTkUI'}; }
sub title { my $self = shift; my $title = $self->{'title'};
		return defined($title) ? $title : "Search Results"; }
sub pattern { my $self = shift; return $self->{'pattern'}; }
sub queryFields { my $self = shift; return $self->{'queryFields'}; }
sub resultFields { my $self = shift; return $self->{'resultFields'}; }
sub results { my $self = shift; return $self->{'results'}; }

sub conv { my $self = shift; return $self->pBibTkUI()->conv(@_); }

#
# widgets
#


sub initWidgets {
  my ($self, $win) = @_;
  my $cmd;

  # menu inside a menu frame

#  my $mf = $win->Frame()->grid(-sticky => 'ew');
#  $mf->gridColumnconfigure(1, -weight => 1);
##  my $mf = $win->Frame()->pack(qw/-fill x -side top/);
##  $mf->gridColumnconfigure(1, -weight => 1);
  my $mf = $win->Menu(-type => 'menubar');
  $win->configure(-menu => $mf);
  $self->initMenu($mf, $win);

  # result list

  my $list = $win->Scrolled('Listbox',            
  		-scrollbars => 'se',
		-width => $defwidth_list,
		-height => $defheight_list,
    )->form(
		-t => ['%0', 0],
		-l => ['%0', 0],
		-r => ['%100', 0],
		#-b => [$do, 0],
	);
  $self->{'resultList'} = $list;
  $cmd = [$self, 'showSelectedBiblioReference'];
  $list->bind('<Double-Button-1>' => $cmd);
  $list->bind('<Return>' => $cmd);
  $list->bind('<Button-1>' => [$self, 'updateExpandedSelectedReference']);		#myline
#  $win->bind('<Return>' => $cmd); ## don't open two windows ...
  $list->bind('<Up>' => [$self, 'selectionMove', $list, -1]);
  $list->bind('<Down>' => [$self, 'selectionMove', $list, 1]);
  $list->bind('<Control-Home>' => [$self, 'selectionMove', $list, 0]);
  $list->bind('<Control-End>' => [$self, 'selectionMove', $list, 'end']);
  for( my $c = ord('a'); $c <= ord('z'); $c++ ) {
		$win->bind(('<Key-' . chr($c) . '>') => [$self, 'keyPressed', Ev('A'), Ev('s')]);
		$list->bind(('<Key-' . chr($c) . '>') => [$self, 'keyPressed', Ev('A'), Ev('s')]);
  }
  
#myline runter ---------------------------------------------------
  # chosen frame

  my $do=$win->LabFrame(-label => 'choose a Ref', -labelside => "acrosstop")->form(
		-t => [$list, 0],
		-l => ['%0', 0],
		-r => ['%100', 0],
		-b =>['%100', 0], 
		);#pack(qw/-expand yes -fill x -side bottom/);	#myline
  $self->{'searchchosen'} = $do;

  $list = $do->Scrolled('TextUndo',
		-scrollbars => 'se',
		-wrap => 'word',
		-setgrid => 'true',
		-exportselection => 'true',
		-height => 6,
	)->form(
	-t => ['%0',0],
	-l => ['%0',0],
	-r => ['%100',0],
	-b => ['%100', 0]);
  $self->{'chosenfromlist'} = $list;

  #  my $b3=$do->Frame()->form(
	#  -t => [$list,0],
	#  -l => ['%0',0],
	#  -r => ['%100',0],
	#  -b => ['%100',0]);
  #  my $bf3 = $b3->Frame()->pack();
#myline hoch ---------------------------------------------------

}

#myline runter ---------------------------------------------------
sub updateExpandedSelectedReference {
  my $self = shift;
  my $paper = $self->selectedBiblioReference();
  return if !defined($paper) || $paper eq "";
  my @entry = PBibTk::RefDialog->new($self->pBibTkUI())->formatRefInfos($paper);
  $self->chosenLabel()->configure(-label => $entry[0]);
  my $list = $self->chosen();
  $list->delete("0.0", "end");
  $list->insert("end", $entry[1]);

  $self->resultList()->focus();
}
sub selectedBiblioReference {
  my $self = shift;
  my $list = $self->resultList();
  my $idx = $list->curselection();
  return if !defined($idx) || $idx eq "";
  my $paper = $self->{'results'}->[$idx];
  return $paper;
#  print Dumper $paper;
}
sub chosenLabel { my $self = shift; return $self->{'searchchosen'}; }
sub chosen {
  my $self = shift;
  # access window first, to ensure it's created.
  $self->window();
  return $self->{'chosenfromlist'};
}
#myline hoch ---------------------------------------------------

sub initMenu {
  my ($self, $mf, $win) = @_;
  $self->pBibTkUI()->initBiblioMenu($mf, $win, $self);
}


sub resultList { return shift->{'resultList'}; }
sub refList { return shift->resultList(); }


#
# menu command methods
#

sub keyPressed {
  my ($self, $key, $mod) = @_;
  return if $mod && $mod ne '';
  my $list = $self->resultList();
  my $idx = $self->indexOfRefStartingWith($key); ##ord($key) - ord('a');
print "keyPressed $key ($mod) --> $idx\n";
  $list->selectionClear(0, 'end');
  $list->see($idx);
  $list->activate($idx);
  $list->selectionAnchor($idx);
  $list->selectionSet($idx);
}

sub selectionMove {
	# called on UP and Down key presses to be able to adjust the printed ref.
	my ($self, $list, $inc) = @_;
	$self->updateExpandedSelectedReference();
}

sub showSelectedBiblioReference {
	my $self = shift;
	my $paper = $self->selectedBiblioReference();
	return unless defined($paper);
	PBibTk::RefDialog
	  ->new($self->pBibTkUI(), $paper)
	  ->show();
}
sub clipboardSelectedBiblioReferenceId {
	my $self = shift;
	my $paper = $self->selectedBiblioReference();
	return unless defined($paper);
	my $ref = $paper->{'CiteKey'};
	Win32::Clipboard()->Set("[$ref]");
}
sub searchSelectedBiblioReferenceId {
	my $self = shift;
	my $paper = $self->selectedBiblioReference();
	return unless defined($paper);
	$self->pBibTkUI()->searchReferenceId($paper->{'CiteKey'});
}
sub queryAuthor {  my $self = shift;
  $self->pBibTkUI()->queryAuthor();
}
sub queryKeyword {  my $self = shift;
  $self->pBibTkUI()->queryKeyword();
}
sub updateBiblioRefs {  my $self = shift;
  $self->updateResults();
}


#
# updating
#


sub updateResults {
  my $self = shift;
  my $list = $self->resultList();
  $list->delete(0, "end");
  my $papers = $self->biblio()->queryPapers($self->pattern(),
	$self->queryFields(), $self->resultFields());
  $self->{'refs'} = $papers;
  my ($ref, $id, @results);
  my @refIDs = sort(keys %$papers);
  foreach $id (@refIDs) {
    $ref = $papers->{$id};
	push @results, $ref;
    my $key = $ref->{'CiteKey'} || '<<no CiteKey!?>>';
    my $cat = $ref->{'Category'} || '<<no Category>>';
    my $title = $ref->{'Title'} || '';
    my $author = $ref->{'Authors'} || $ref->{'Editors'} || $ref->{'Organization'} || '';
    my $recom = $ref->{'Recommendation'};
    my $year = $ref->{'Year'} || '';
	if( length($title) > $maxlength_title )
	  { $title = substr($title, 0, $maxlength_title) . ' ...' }
	if( $author ) {
	  if( length($author) > $maxlength_author )
	    { $author = substr($author, 0, $maxlength_author) . ' ...' }
	  if( $year )
	    { $author .= ', '; }
	}
    my $text = $key . ($recom ? " ($recom)" : '') . " \"$title\" ($author$year) [$cat]";
    $list->insert("end", $text);
  }
  $self->{'results'} = \@results;
  $self->window()->configure(
	-title => $self->title() . ' (' . scalar(@results) . ' found)',
	);
  my $height = $list->height();
  if( scalar @results > $height ) {
    # enlarge window
	$height = scalar @results;
	$height = $maxheight_list if $height > $maxheight_list;
	$list->configure(-height => $height);
  }
}

sub indexOfRefStartingWith {
  my ($self, $char) = @_;
  return undef unless defined($char);
  my $refs = $self->{'results'};
  my $idx = 0;
  for( ; $idx < scalar(@$refs); $idx++ ) {
		my $key = $refs->[$idx]->{'CiteKey'};
  #  print ord(lc($char)), ' ', ord(lc(substr($key, 0, 1))), " $idx - $key";
    last if( ord(lc($char)) <= ord(lc(substr($key, 0, 1))) );
  }
  return $idx;
}

1;

#
# $Log: LitUI::SearchDialog.pm,v $

# Revision 1.15  2004/03/30 19:20:10  krugar
# refactored: 
# 	LitUIRefDialog -> LitUI::RefDialog 
#	LitUISearchDialog -> LitUI::SearchDialog 
#

# Revision 1.14  2004/03/29 13:12:34  tandler
# box to see refs
#
# Revision 1.13  2003/12/22 21:59:41  tandler
# toni's changes: include explaination field in UI
#
# Revision 1.12  2003/06/12 22:19:21  tandler
# no significant change :-)
#
# Revision 1.11  2003/02/20 09:19:26  ptandler
# ignore null recommendation in title & search list
#
# Revision 1.10  2002/06/30 08:48:14  Diss
# bugfix: open only one ref window
#
# Revision 1.9  2002/06/29 18:28:32  Diss
# new query style, focus + jump-to-by-key for all ref lists
#
# Revision 1.8  2002/06/19 15:59:20  Diss
# - window is opened with focus
# - menus restuctred
# - menu keyboard shortcuts (Alt-B)
# - return and double-click to show reference details window
# - keys a-z to jump to ref in list
#
# Revision 1.7  2002/06/11 11:14:12  Diss
# sort search results
#
# Revision 1.6  2002/06/10 17:13:10  Diss
# adapted initial window sizes + minor "searchInEditor" fix
#
# Revision 1.5  2002/06/07 11:21:41  Diss
# bugfix: 'PaperID' -> 'CiteKey'
# new menus for search dialog
#
# Revision 1.4  2002/03/22 17:31:02  Diss
# small changes
#
# Revision 1.3  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#
# Revision 1.2  2002/03/07 12:01:06  Diss
# menu bar, use LitUIRefDialog
#
# Revision 1.1  2002/02/11 11:57:06  Diss
# lit UI with search dialog, script to start/stop biblio, and more ...
#