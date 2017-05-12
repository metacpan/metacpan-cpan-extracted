# --*-Perl-*--
# $Id: Main.pm 23 2005-07-17 19:28:02Z tandler $
#

=head1 NAME

PBibTk::Main - GUI for PBib, a tool for managing and processing bibliographic data

=head1 SYNOPSIS

	# taken from PBibTk.pl
	use PBibTk::LitRefs;
	use PBibTk::Main;
	
	my $litrefs = new PBibTk::LitRefs();
	$litrefs->processArgs();
	
	my $ui = new PBibTk::Main($litrefs);
	$ui->main();

=head1 DESCRIPTION

I wrote PBib to have something like BibTex for MS Word that can use a various sources for bibliographic references, not just BibTex files, but also database systems.

F<PBibTk.pl> / C<PBibTk::Main> is a simple GUI written with Perl's Tk package.

See the L<PBibTk.pl> documentation for more information.

=cut

package PBibTk::Main;
use strict;
use warnings;

use File::Basename;

use Tk;
use Tk::LabFrame;
use Tk::LabEntry;
use Tk::DropSite;
use Tk::FileSelect;
use Tk::DialogBox;
use Tk::ErrorDialog;
use Tk::BrowseEntry;

#use Win32::Process;
use Win32::Clipboard;

# for debugging
use Data::Dumper;

# Biblio modules
use Biblio::BP;

# PBib modules
use PBib::PBib;
use PBib::Document;

# own modules
use PBibTk::LitRefs;
use PBibTk::SearchDialog;
use PBibTk::RefDialog;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 23 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}


use vars qw($rootWindow $filename);
#use vars qw($fileselect);
use vars qw($editNewRefsProcess);
our ($queryAuthorItem, @queryAuthorHistory);
our ($queryKeywordItem, @queryKeywordHistory);

# options for processing documents.
our $pbibDocToRtf = 1; # should a .doc file be converted to a .rtf file before processing?
our $pbibShowResult = 1; # should the processed document be opened in an editor?
our $pbibOptions = ''; # options to pass to pbib


#
#
#

sub new {
  my $class = shift;
  my ($litrefs) = @_;
  my $ui = {
    'litRefs' => $litrefs,
  };
  return bless $ui, $class;
}

sub main {
  my $self = shift;
  my $litrefs = $self->litRefs();

  $filename = $litrefs->filename();
  $filename = "" unless defined($filename);

  $self->window();
  $self->updateBiblioRefs();

  MainLoop;
}


sub DESTROY ($) {
  my $self = shift;
  $self->saveQueryHistory();
}

#
# access methods
#

sub window {
  my $self = shift;
  my $win = $self->{'window'};
  return $win if defined($win);

  if( defined($rootWindow) ) {
    # open second window
    $win = $rootWindow->Toplevel();
  } else {
    $win = $rootWindow = MainWindow->new();
#    $fileselect = $win->FileSelect(-directory => $ENV{'DISSDIR'});
    $win->fontCreate(qw/T_bold    -family times  -size 9  -weight bold/);
    $win->fontCreate(qw/H_bold    -family helvetica  -size 9  -weight bold/);
    $win->fontCreate(qw/H_big_bold    -family helvetica  -size 11  -weight bold/);
  }
  $win->configure(
	-title => "PBib",
	);
  $self->{'window'} = $win;
  $self->initWidgets($win);
  $self->initDropSite($win);
#myline zur beschleunigung wird der converter nur bei fensteraktualisierung erstellt
  $self->{'conv'} = $self->make_converter();
  return $win;
}

sub rootWindow {
  my $self = shift;
  my $win = $rootWindow;
  $win = $self->window unless defined($win);
  return $win;
}

sub biblio { my $self = shift; return $self->litRefs()->biblio(); }
sub refs { my $self = shift; return $self->biblio()->queryPapers(); }
#  sub refs { my $self = shift; return $self->litRefs()->refs(); }
sub conv { my $self = shift;
	my $conv = $self->{'conv'};
	if( @_ ) {
		$conv->setArgs(@_);
	}
	return $conv
}

sub make_converter {
	my $self = shift;
	my %args =@_;

	my $doc = new PBib::Document;
#	my $doc = new PBib::Document::PBib;
	my $conv = new PBib::ReferenceConverter(
		'inDoc' => $doc,
		'outDoc' => $doc,
		'refStyle'	=> new PBib::ReferenceStyle::BookmarkLink,
		'labelStyle'	=> new PBib::LabelStyle,
#		'labelStyle'	=> new PBib::LabelStyle::CiteKey,
		'bibStyle'	=> new PBib::BibliographyStyle,
		#  'itemStyle'	=> new PBib::BibItemStyle,
		'refs' => $self->refs(),
		'itemOptions' => {
			'include-label' => 0,
		},
		'itemStyle'	=> new PBib::BibItemStyle::IEEETR,
		%args
	);
	return $conv;
}



#
# widgets
#


sub initWidgets {
  my ($self, $win) = @_;
  my $f2=$win;
  my $cmd;

  # biblio and paper frames

  my $l3=$f2->LabFrame(-label => 'choose a Ref', -labelside => "acrosstop")->pack(qw/-expand yes -fill both -side bottom/);	#myline
  $self->{'chosenLabel'} = $l3;											                #myline
  my $l1=$f2->LabFrame(-label => 'Biblio Refs', -labelside => "acrosstop")->pack(qw/-expand yes -fill both -side left/);
  $self->{'refListLabel'} = $l1;
  my $l2=$f2->LabFrame(-label => 'Paper Refs', -labelside => "acrosstop")->pack(qw/-expand yes -fill both -side right/);
  $self->{'foundListLabel'} = $l2;
  my $off = -100;

  # biblio frame

  my $list = $l1->Scrolled('Listbox',
  	  -scrollbars => 'e',
	  -width => 32,
	  -height => 16,
	)->form(
	-t => ['%0',0],
	-l => ['%0',0],
	-r => ['%100',0],
	-b => ['%100', $off]);
  $self->{'refList'} = $list;
  $cmd = [$self, 'showSelectedBiblioReference'];
  $list->bind('<Return>' => $cmd);
  $list->bind('<Double-Button-1>' => $cmd);
#  $list->bind('<Button-1>' => [ $list, 'focus' ] );                    #focus wird in updateExpandedSelectedBiblioReference ausgefuehrt
  $list->bind('<Button-1>' => [$self, 'updateExpandedSelectedBiblioReference']);
  $list->bind('<Up>' => [$self, 'selectionMove', $list, -1]);
  $list->bind('<Down>' => [$self, 'selectionMove', $list, 1]);
  $list->bind('<Control-Home>' => [$self, 'selectionMove', $list, 0]);
  $list->bind('<Control-End>' => [$self, 'selectionMove', $list, 'end']);
  for( my $c = ord('a'); $c <= ord('z'); $c++ ) {
#   $win->bind(('<Key-' . chr($c) . '>') => [$self, 'keyPressed', Ev('A'), Ev('s')]);
   $list->bind(('<Key-' . chr($c) . '>') => [$self, 'keyPressed', Ev('A'), Ev('s'), $list, 'refListIds']);
  }

  my $b1=$l1->Frame()->form(
	-t => [$list,0],
	-l => ['%0',0],
	-r => ['%100',0],
	-b => ['%100',0]);
  my $bf1 = $b1->Frame()->pack(qw/-fill both -expand 1/);
#  $bf1->Button(-text => "Update", -command => sub{$self->updateBiblioRefs()} )->pack();

  $self->loadQueryHistory();
  $cmd = [ $self, 'queryAuthor' ];
#  $bf1->Button(-text => "Query Author", -command => $cmd )->pack(qw/-side left/);
  $list = $bf1->BrowseEntry(-label => "Author",
  		-variable => \$queryAuthorItem,
  		-choices => \@queryAuthorHistory,
#  		-listcmd => sub { print "popup list"; },
  		-browsecmd => $cmd,
  		)->pack(qw/-side top/);
  $list->bind('<Return>' => $cmd);
  $self->{'queryAuthorList'} = $list;
  
  #  $list->PrintConfig();
  
  $cmd = [ $self, 'queryKeyword' ];
#  $bf1->Button(-text => "Query Keyword", -command => $cmd )->pack(qw/-side left/);
  $list = $bf1->BrowseEntry(-label => "Keyword",
  		-variable => \$queryKeywordItem,
  		-choices => \@queryKeywordHistory,
#  		-listcmd => sub { print "popup list"; },
  		-browsecmd => $cmd,
  		)->pack(qw/-side top/);
  $list->bind('<Return>' => $cmd);
  $self->{'queryKeywordList'} = $list;
  
  $b1->Button(-text => "Quit", -command => sub{ Tk::exit(0); } )->pack(-side => 'bottom', -padx => 10);#myline "..right', -padx => 10.." statt "..bottom.."
  
  # paper frame

  $list = $l2->Scrolled('Listbox',
      -scrollbars => 'e',
	  -width => 48,
	  -height => 16,
	)->form(
	-t => ['%0',0],
	-l => ['%0',0],
	-r => ['%100',0],
	-b => ['%100', $off]);
  $self->{'foundList'} = $list;
  $cmd = [$self, 'showSelectedPaperReference'];
  $list->bind('<Return>' => $cmd);
  $list->bind('<Double-Button-1>' => $cmd);
#  $list->bind('<Button-1>' => [ $list, 'focus' ] );                    #focus wird in updateExpandedSelectedBiblioReference ausgefuehrt
  $list->bind('<Button-1>' => [$self, 'updateExpandedSelectedPaperReference']);		#myline
  $list->bind('<Up>' => [$self, 'selectionMove', $list, -1]);
  $list->bind('<Down>' => [$self, 'selectionMove', $list, 1]);
  $list->bind('<Control-Home>' => [$self, 'selectionMove', $list, 0]);
  $list->bind('<Control-End>' => [$self, 'selectionMove', $list, 'end']);
  for( my $c = ord('a'); $c <= ord('z'); $c++ ) {
#   $win->bind(('<Key-' . chr($c) . '>') => [$self, 'keyPressed', Ev('A'), Ev('s')]);
   $list->bind(('<Key-' . chr($c) . '>') => [$self, 'keyPressed', Ev('A'), Ev('s'), $list, 'foundListIds']);
  }

  my $b2=$l2->Frame()->form(
	-t => [$list,0],
	-l => ['%0',0],
	-r => ['%100',0],
	-b => ['%100',0]);
  $b2->LabEntry(-label => "File: ",
	     -labelPack => [-side => "left", -anchor => "w"],
#	     -width => 20,
	     -textvariable => \$filename)->pack(-expand => 1, -fill => 'x');
  my $bf2 = $b2->Frame()->pack();
  $bf2->Button(-text => "Browse", -command => sub{$self->browsePaperFile()} )->pack(qw/-side left/);
  $bf2->Button(-text => "Edit", -command => sub { openFile($filename); } )->pack(qw/-side left/);
  $bf2->Button(-text => "Update", -command => sub{$self->readPaperFile()} )->pack(qw/-side left/);
  $bf2->Button(-text => "Process", -command => [ $self, 'processPaperFile' ] )->pack(qw/-side left/);
#  $bf2->Button(-text => "Write newrefs.txt", -command => sub{$self->writeNewRefs()})->pack();

#myline runter ---------------------------------------------------
  # chosen frame

  $list = $l3->Scrolled('TextUndo',
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

  my $b3=$l3->Frame()->form(
	-t => [$list,0],
	-l => ['%0',0],
	-r => ['%100',0],
	-b => ['%100',0]);
  my $bf3 = $b3->Frame()->pack();
#myline hoch ---------------------------------------------------

  # menu inside a menu frame

  my $mf = $win->Menu(-type => 'menubar');
  $win->configure(-menu => $mf);
  $self->initMenu($mf, $win);

}
sub initMenu {
  my ($self, $mf, $win) = @_;
  $self->initFileMenu($mf, $win);
  $self->initBiblioMenu($mf, $win);
  $self->initPaperMenu($mf, $win);
}
sub initFileMenu {
  my ($self, $mf, $win, $model) = @_;
  my $cmd;
  $model = $self unless defined $model;
  my $mb = $mf->cascade(-label => '~File'); ###, -tearoff => 0);

  $cmd = [ $model, 'browsePaperFile' ];
  $mb->command(-label => "~Open New Paper", -command => $cmd,
  				-accelerator => 'Ctrl-O' );
  $win->bind('<Control-Key-o>' => $cmd);

  $mb->separator();

  $cmd = [ $model, 'importBiblioRefs' ];
  $mb->command(-label => "~Import References ...", -command => $cmd );
  #$win->bind('<Control-w>' => $cmd);

  $cmd = [ $model, 'exportBiblioRefs' ];
  $mb->command(-label => "~Export References ...", -command => $cmd );
  #$win->bind('<Control-w>' => $cmd);

  $mb->separator();

  $cmd = sub { Tk::exit(0); };
  $mb->command(-label => '~Quit', -command => $cmd,
  				-accelerator => 'Ctrl-Q');
  $win->bind('<Control-q>' => $cmd);
}
sub initBiblioMenu {
  my ($self, $mf, $win, $model) = @_;
  my $cmd;
  $model = $self unless defined $model;
  my $mb = $mf->cascade(-label => '~Biblio'); ###, -tearoff => 0);

#  $cmd = sub { $model->showSelectedBiblioReference(); };
  $cmd = [$model, 'showSelectedBiblioReference'];
  $mb->command(-label => 'Show ~Reference', -command => $cmd,
				-accelerator => 'Ctrl-R' );
  $win->bind('<Control-r>' => $cmd);
#  $win->bind('<Return>' => $cmd);

  $cmd = [ $model, 'clipboardSelectedBiblioReferenceId'];
  $mb->command(-label => '~Copy CiteKey to Clipboard', -command => $cmd,
				-accelerator => 'Ctrl-C' );
  $win->bind('<Control-c>' => $cmd);

  $cmd = sub { $model->searchSelectedBiblioReferenceId(); };
  $mb->command(-label => '~Search CiteKey in Paper', -command => $cmd,
  				-accelerator => 'Ctrl-J' );
  $win->bind('<Control-j>' => $cmd);

  $cmd = sub { $model->refList()->focus(); };
  $mb->command(-label => 'Keyboardfocus to ~Biblio', -command => $cmd,
  				-accelerator => 'Ctrl-B' );
  $win->bind('<Control-b>' => $cmd);

  $mb->separator();

  # $cmd = sub{$model->queryAuthor()}; # start search via menu
  # better: set focus to queryAutor input field
  $cmd = [ $model, 'entryFocusAndSelectAll',
						$self->queryAuthorList() ];
  $mb->command(-label => "Query ~Author", -command => $cmd,
				-accelerator => 'Ctrl-A' );
  $win->bind('<Control-a>' => $cmd);

  #$cmd = sub{$model->queryKeyword()};
  # instead of start query: set focus to keyword input field
  $cmd = [ $model, 'entryFocusAndSelectAll',
						$self->queryKeywordList(), ];
  $mb->command(-label => "Query ~Keyword", -command => $cmd,
				-accelerator => 'Ctrl-F' );
  $win->bind('<Control-f>' => $cmd);

  $mb->separator();

  $cmd = sub{$model->updateBiblioRefs()};
  $mb->command(-label => "~Update from database",
				-command => $cmd,
  				-accelerator => 'Ctrl-N' );
  $win->bind('<Control-n>' => $cmd);
}

sub initPaperMenu {
  my ($self, $mf, $win) = @_;
  my $cmd;
  my $mb = $mf->cascade(-label => '~Paper');

  $cmd = sub { $self->showSelectedPaperReference(); };
  $mb->command(-label => 'Show ~Reference', -command => $cmd,
  				-accelerator => 'Ctrl-T' );
  $win->bind('<Control-Key-t>' => $cmd);

  $cmd = sub { $self->clipboardSelectedPaperReferenceId(); };
  $mb->command(-label => '~Copy CiteKey to Clipboard', -command => $cmd,
  				-accelerator => 'Ctrl-X' );
  $win->bind('<Control-Key-x>' => $cmd);

  $cmd = sub { $self->searchSelectedPaperReferenceId(); };
  $mb->command(-label => '~Search CiteKey in Paper', -command => $cmd,
  				-accelerator => 'Ctrl-G' );
  $win->bind('<Control-Key-g>' => $cmd);

  $cmd = sub { $self->foundList()->focus(); };
  $mb->command(-label => 'Keyboardfocus to ~Paper', -command => $cmd,
  				-accelerator => 'Ctrl-P' );
  $win->bind('<Control-p>' => $cmd);

  $mb->separator();

  $cmd = sub { openFile($filename); };
  $mb->command(-label => '~Edit Paper', -command => $cmd,
  				-accelerator => 'Ctrl-E' );
  $win->bind('<Control-Key-e>' => $cmd);

  $mb->separator();

  $mb->command(-label => "Read & ~Analyze Paper", -command => [ $self, 'readPaperFile' ]);

  $cmd = [ $self, 'processPaperFile' ];
  $mb->command(-label => "Pr~ocess Paper", 
				  -command => $cmd,
				  -accelerator => 'Ctrl-S' );
  $win->bind('<Control-Key-s>' => $cmd);

  $mb->command(-label => "~Write newrefs file", -command => [$self => 'writeNewRefs']);
}

sub refList {
  my $self = shift;
  # access window first, to ensure it's created.
  $self->window();
  return $self->{'refList'};
}
sub foundList {
  my $self = shift;
  # access window first, to ensure it's created.
  $self->window();
  return $self->{'foundList'};
}
sub queryAuthorList { return shift->{'queryAuthorList'}; }
sub queryKeywordList { return shift->{'queryKeywordList'}; }
sub chosenLabel { my $self = shift; return $self->{'chosenLabel'}; }
sub refListLabel { my $self = shift; return $self->{'refListLabel'}; }
sub foundListLabel { my $self = shift; return $self->{'foundListLabel'}; }
sub refListSelection { my $self = shift; return $self->refList()->curselection(); }
sub foundListSelection { my $self = shift; return $self->foundList()->curselection(); }

sub litRefs { my $self = shift; return $self->{'litRefs'}; }



sub initDropSite {
# I guess this doesn't qork jet under Win32 ...
  my ($self, $win) = @_;
  $win->DropSite(
	-entercommand => sub{print "enter @_\n";},
	-leavecommand  => sub{print "leave @_\n";},
	-motioncommand  => sub{print "motion @_\n";},
	-dropcommand  => sub{print "drop @_\n";},
	);
}


#
# button / menu methods
#

sub keyPressed {
  my ($self, $key, $mod, $list, $refsName) = @_;
  return if $mod && $mod ne '';
  my $refs = $self->{$refsName};
  my $idx = $self->indexOfRefStartingWith($refs, $key);
print "keyPressed $key ($mod) --> $idx\n";
  $list->focus();
  $list->activate($idx);
  $list->selectionClear(0, 'end');
  $list->selectionAnchor($idx);
  $list->selectionSet($idx);
  $list->see($idx);
  $self->selectionMove($list, undef);
}
sub indexOfRefStartingWith {
  my ($self, $refs, $char) = @_;
  return undef unless defined($char);
  my $idx = 0;
  for( ; $idx < scalar(@$refs); $idx++ ) {
###  print ord(lc($char)), ' ', ord(lc(substr($refs->[$idx], 0, 1))), " $idx - $refs->[$idx]\n";
    last if( ord(lc($char)) <= ord(lc(substr($refs->[$idx], 0, 1))) );
  }
  return $idx;
}

sub entryFocusAndSelectAll {
	my ($self, $list) = @_;
	$list->focus();
	$list->selectionRange(0, "end");
}

sub selectionMove {
	# called on UP and Down key presses to be able to adjust the printed ref.
	my ($self, $list, $inc) = @_;
	if( $list == $self->refList() ) {
		$self->updateExpandedSelectedBiblioReference();
	} else {
		$self->updateExpandedSelectedPaperReference();
	}
}


# updateing

sub updateBiblioRefs {
# re-load all refs and re-analyze paper!
  my $self = shift;
  my $litrefs = $self->litRefs();
  $litrefs->readRefs();
  $litrefs->analyzeFile($filename) if $filename;
  $self->updateLists();
}

sub updateLists {
  my $self = shift;
  $self->updateBiblioList();
  $self->updatePaperList();
  $self->{'conv'} = $self->make_converter();
  #  $self->conv()->setArgs(
	  #  'refs' => $self->refs(),
	  #  );
}
sub updateBiblioList {
# re-load all refs and everything!
  my $self = shift;
  $self->refList()->delete(0, "end");
  $self->addBiblioRefs();
}
sub updatePaperList {
# re-load all refs and everything!
  my $self = shift;
  $self->foundList()->delete(0, "end");
  $self->addPaperRefs();
}

# read/browse paper

sub readPaperFile {
  my $self = shift;
  $self->updateBiblioRefs();
#  my $litrefs = $self->litRefs();
#  $litrefs->analyzeFile($filename) if $filename;
#  $self->updateLists();
}
sub browsePaperFile {
  my $self = shift;
# orig:
#  $filename = $fileselect->Show;

  my $types = [
		['All Files',	'*'],
		['Text Files',	'.txt'],
		['TeX / LaTeX',	'.tex'],
		['Word Files',       ['.doc', '.rtf']],
	];
  print Dumper {
	'$filename' => $filename,
	'dir' => dirname($filename),
	'name' => basename($filename),
	-initialdir => $filename ? dirname($filename) : $ENV{'HOME'},
	};
  my $file = $self->window()->getOpenFile(
  	-filetypes => $types,
	-defaultextension => '.txt',
	-initialdir => $filename ? dirname($filename) : $ENV{'HOME'},
	-initialfile => basename($filename),
	-title => 'Select Document ...',
	);

  if( $file ) {
    $filename = $file;
    $self->updateBiblioRefs();
  }
}
sub writeNewRefs {
	my ($self, $file) = @_;
	$file = $filename unless defined $file;
	my $litrefs = $self->litRefs();
	my @refs = @{$litrefs->newrefs()};
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $date = sprintf("%02d-%02d-%02d", ($year+1900) % 100, $mon+1, $mday);
	my $outfilename = "$filename-refs-$date.txt";
	print scalar(@refs), " new references found in $filename ($date)\n";
	open OUT,"> $outfilename";
	my $ref; my $i = 0;
	print OUT scalar(@refs), " new references found in $filename ($date)\n\n\n";
	foreach $ref (sort(@refs)) { print OUT "[", ++$i, "] $ref\n"; }
	close OUT;
	print "done.\n";
	openFile($outfilename);
}
sub processPaperFile {
	my ($self, $file, $refs) = @_;
	$file = $filename unless defined $file;
	$refs = $self->biblio()->queryPapers() unless $refs;
# $pbibOptions = ''; # options to pass to pbib
	my $config = new PBib::Config();
	my $pbib = new PBib::PBib(
		'refs' => $refs,
		'config' => $config,
		);
	my $outDoc = $pbib->processFile($file);
}


# query

#my $authorDialog; my $authorPattern;
#sub queryAuthor {
#  my $self = shift;
#  $self->queryDialog(\$authorDialog, \$authorPattern, "Search Author:", ['Author']);
#}
#my $keywordDialog; my $keywordPattern;
#sub queryKeyword {
#  my $self = shift;
#  $self->queryDialog(\$keywordDialog, \$keywordPattern, "Search Keyword:", [
#	'Keywords', 'Annote', 'Note', 'Title',
#	'CiteKey', 'Category',
#	]);
#}

sub addToHistory { my ($history, $item) = @_;
	my @oldHistory = @$history;
	# remove duplicates
	@$history = ();
	foreach my $old (@oldHistory) {
		push @$history, $old if $old ne $item;
	}
	# add new item
	unshift @$history, $item;
}

sub queryAuthor { my ($self) = @_;
	print "query $queryAuthorItem\n";
	addToHistory(\@queryAuthorHistory, $queryAuthorItem);
	$self->queryAuthorList()->delete(0, "end");
	$self->queryAuthorList()->insert(0, @queryAuthorHistory);
	my $q = new PBibTk::SearchDialog ($self,
		"Search Author: $queryAuthorItem",
		"%$queryAuthorItem%",
		['Authors', 'Editors']);
	$q->show();
}

sub queryKeyword { my ($self) = @_;
	print "query $queryKeywordItem\n";
	addToHistory(\@queryKeywordHistory, $queryKeywordItem);
	$self->queryKeywordList()->delete(0, "end");
	$self->queryKeywordList()->insert(0, @queryKeywordHistory);
	my $q = new PBibTk::SearchDialog ($self,
		"Search Keyword: $queryKeywordItem",
		"\%$queryKeywordItem\%",
		[
		'Keywords', 'Annotation', 'Note', 'Title',
		'CiteKey', 'Category',
		'PBibNote', ##### 'Project', 'Subject', 'BibNote',
		]);
	$q->show();
}

sub saveQueryHistory {
	my ($self) = @_;
	open OUT, "> .pbibtk-author-history.txt";
	foreach my $a (@queryAuthorHistory) { print OUT "$a\n"; }
	close OUT;
	open OUT, "> .pbibtk-keyword-history.txt";
	foreach my $a (@queryKeywordHistory) { print OUT "$a\n"; }
	close OUT;
}
sub loadQueryHistory {
	my ($self) = @_;
	if( open IN, "< .pbibtk-author-history.txt" ) {
		chomp(@queryAuthorHistory = <IN>);
		close IN;
	}
	if( open IN, "< .pbibtk-keyword-history.txt" ) {
		chomp(@queryKeywordHistory = <IN>);
		close IN;
	}
}

sub queryDialog {
  my ($self, $dialogRef, $patternRef, $msg, $queryFields) = @_;
  if( not defined($$dialogRef) ) {
    $$dialogRef = $self->rootWindow()->DialogBox(-title => "Lit UI", -buttons => ["OK", "Cancel"]);
    $$dialogRef->LabEntry(-label => $msg,
	     -labelPack => [-side => "left", -anchor => "w"],
	     -textvariable => $patternRef)->pack(-expand => 1, -fill => 'x');
  }
  my $button = $$dialogRef->Show();
  return if( $button eq "Cancel" );
  my $pattern = $$patternRef;
  return if( not defined($pattern) or $pattern eq "" );
  my $q = new PBibTk::SearchDialog ($self, "$msg $pattern", "%$pattern%", $queryFields);
  $q->show();
}

# show refs

sub showSelectedBiblioReference {
  my $self = shift;
  my $idx = $self->refListSelection();
  return if !defined($idx) || $idx eq "";
  my $paper = $self->litRefs()->queryPaperWithId($self->biblioRefAt($idx));
  PBibTk::RefDialog->new($self, $paper)->show();
}
sub showSelectedPaperReference {
  my $self = shift;
  my $idx = $self->foundListSelection();
  return if !defined($idx) || $idx eq "";
  my $paper = $self->litRefs()->queryPaperWithId($self->paperRefAt($idx));
  PBibTk::RefDialog->new($self, $paper)->show();
}

sub clipboardSelectedBiblioReferenceId {
  my $self = shift;
  my $idx = $self->refListSelection();
  return if !defined($idx) || $idx eq "";
  my $ref = $self->biblioRefAt($idx);
  Win32::Clipboard()->Set("[$ref]");
}
sub clipboardSelectedPaperReferenceId {
  my $self = shift;
  my $idx = $self->foundListSelection();
  return if !defined($idx) || $idx eq "";
  my $ref = $self->paperRefAt($idx);
  Win32::Clipboard()->Set("[$ref]");
}

sub searchSelectedBiblioReferenceId {
  my $self = shift;
  my $idx = $self->refListSelection();
  return if !defined($idx) || $idx eq "";
  $self->searchReferenceId($self->biblioRefAt($idx));
}
sub searchSelectedPaperReferenceId {
  my $self = shift;
  my $idx = $self->foundListSelection();
  return if !defined($idx) || $idx eq "";
  $self->searchReferenceId($self->paperRefAt($idx));
}
sub searchReferenceId {
  my ($self, $ref) = @_;
#  print "searchReferenceId {$filename, $ref)\n";
  searchInFile($filename, "[$ref]") if $filename && $ref;
}

#myline runter ---------------------------------------------------
sub updateExpandedSelectedBiblioReference {
  my ($self) = @_;
  my $idx = $self->refListSelection();
  return if !defined($idx) || $idx eq "";
  my $paper = $self->litRefs()->queryPaperWithId($self->biblioRefAt($idx));
  $self->updateExpandedSelectedReference($paper);
  $self->{'refList'}->focus();
}
sub updateExpandedSelectedPaperReference {
  my ($self) = @_;
  my $idx = $self->foundListSelection();
  return if !defined($idx) || $idx eq "";
  my $paper = $self->litRefs()->queryPaperWithId($self->paperRefAt($idx));
  $self->updateExpandedSelectedReference($paper);
  $self->{'foundList'}->focus();
}
sub updateExpandedSelectedReference {
  my ($self, $paper) = @_;
  return if !defined($paper) || $paper eq "";
  my @entry = PBibTk::RefDialog->new($self)->formatRefInfos($paper);
  $self->chosenLabel()->configure(-label => $entry[0]);
  my $list = $self->chosen();
  $list->delete("0.0", "end");
  $list->insert("end", $entry[1]);
}
sub chosen {
  my $self = shift;
  # access window first, to ensure it's created.
  $self->window();
  return $self->{'chosenfromlist'};
}
#myline hoch ---------------------------------------------------


#
# reference handling
#

sub addBiblioRefs {
# add for each ref a prefix with some additional information
# (like this ref's state)
  my $self = shift;
  my $litrefs = $self->litRefs();
  my $list = $self->refList();
### ToDO: sort case-independent!!
  my @refListIds = sort {uc($a) cmp uc($b)} @{$litrefs->refs()};
  $self->{'refListIds'} = \@refListIds;
  $list->insert("end", map($self->biblioRefLabel($_), @refListIds));
  $self->refListLabel()->configure(
	-label => ('Biblio Refs (' .
		scalar(@{$litrefs->refs()}) . ", " .
		scalar(@{$litrefs->used()}) . " used, " .
		scalar(@{$litrefs->unused()}) . " unused" .
		')')
	);
}
sub biblioRefLabel {
# return the label for a biblio ref
  my ($self, $ref) = @_;
  my $litrefs = $self->litRefs();
  my %status = %{$litrefs->statusOf($ref)};
  return ($status{'used'} ? '+' : '  ') .
          " $ref ($status{'occurances'})";
}
sub biblioRefAt {
# return reference at idx
  my ($self, $idx) = @_;
  return undef unless defined($idx);
  return $self->{'refListIds'}->[$idx];
}

sub addPaperRefs {
# add for each ref a prefix with some additional information
# (like this ref's state)
  my $self = shift;
  my $litrefs = $self->litRefs();
  my $list = $self->foundList();
  my @foundListIds = sort {uc($a) cmp uc($b)} @{$litrefs->found()};
  $self->{'foundListIds'} = \@foundListIds;
  $list->insert("end", map($self->paperRefLabel($_), @foundListIds));
  $self->foundListLabel()->configure(
	-label => ('Paper Refs (' .
		scalar(@{$litrefs->found()}) . ", " .
		scalar(@{$litrefs->known()}) . " known, " .
		scalar(@{$litrefs->unknown()}) . " unknown, " .
		scalar(@{$litrefs->newrefs()}) . " new" .
		')')
	);
}
sub paperRefLabel {
# return the label for a biblio ref
  my ($self, $ref) = @_;
  my $litrefs = $self->litRefs();
  my %status = %{$litrefs->statusOf($ref)};
  return ($status{'new'} ? '*' :
          ($status{'unknown'} ? '?' : '  ')) .
          " $ref ($status{'occurances'})";
}
sub paperRefAt {
# return reference at idx
  my ($self, $idx) = @_;
  return undef unless defined($idx);
  return $self->{'foundListIds'}->[$idx];
}


#
#
# export
#
#

sub exportBiblioRefs {
	my ($self, $file, $refs) = @_;
	unless( $file ) {
		my $types = [
			['BibTeX',		'.bib'],
			['All Files',	'*'],
		];
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
			localtime(time);
		my $date = sprintf("%02d-%02d-%02d",
			($year+1900) % 100, $mon+1, $mday);
		$file = "refs-$date.bib";
		$file = $self->window()->getSaveFile(
			-filetypes => $types,
			-defaultextension => '.bib',
			-initialdir => $filename
				? dirname($filename)
				: $ENV{'HOME'},
			-initialfile => $file,
			-title => 'Export References ...',
			);
	}
	if( $file ) {
		$refs = $self->biblio()->queryPapers() unless $refs;
		Biblio::BP::export($file, $refs);
	}
}

#
#
# import
#
#

sub importBiblioRefs {
	my ($self, $file, $refs) = @_;
	unless( $file ) {
		my $types = [
			['BibTeX',		'.bib'],
			['All Files',	'*'],
		];
		$file = $self->window()->getOpenFile(
			-filetypes => $types,
			-defaultextension => '.bib',
			-initialdir => $filename
				? dirname($filename)
				: $ENV{'HOME'},
			-title => 'Import References ...',
			);
	}
	if( $file ) {
		my $refs = Biblio::BP::import(	{}, $file);
		my $bib = $self->biblio();
		print STDERR "storing ", scalar(@$refs), " references\n";
		foreach my $ref (@$refs) { $bib->storePaper($ref) }
		$bib->commit();
		$self->updateBiblioRefs();
	}
}



#
# win stuff
#


#sub Win32ErrorReport{
#  print Win32::FormatMessage( Win32::GetLastError() );
#}

sub openFile {
  my ($filename) = @_;
  print STDERR "open $filename\n";
  my $doc = new PBib::Document(
	'filename' => $filename,
	'mode' => 'r',
	);
  $doc->openInEditor();
}

sub searchInFile {
  my ($filename, $text) = @_;
  print STDERR "search $text in $filename\n";
  my $doc = new PBib::Document(
	'filename' => $filename,
	'mode' => 'r',
	);
  $doc->searchInEditor($text);
}





1;

__END__

=head1 AUTHOR

Peter Tandler <pbib@tandlers.de>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002-2004 P. Tandler

For copyright information please refer to the LICENSE file included in this distribution.

=head1 SEE ALSO

Modules: L<PBib::PBib>, L<PBibTk::RefDialog>, L<PBibTk::SearchDialog>

Scripts: F<bin/pbib.pl>, F<bin/PBibTk.pl>

URL: L<http://tandlers.de/peter/pbib/>
