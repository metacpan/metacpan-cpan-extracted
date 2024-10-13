package App::Codit::Plugins::SearchReplace;

=head1 NAME

App::Codit::Plugins::SearchReplace - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.11;

use base qw( Tk::AppWindow::BaseClasses::Plugin );
require Tk::LabFrame;
require Tk::ITree;

my $srchcur = 'Search in current document';
my $srchall = 'Search in all documents';
my $srchprj = 'Search in project files';
my $srchres = 'Search in results';

=head1 DESCRIPTION

Search and replace across multiple files.

=head1 DETAILS

This plugin allows you to do a search and replace across multiple files or just one file. 
After filling out the search and replace fields you first click Find. 

The list box will fill with the search results. When you click Replace the first item in 
the list is replaced and then removed from the list. 
You can skip replaces by pressing Skip. Clear deletes all search results.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
#	my $tp = $self->extGet('ToolPanel');
#	my $page = $tp->addPage('SearchReplace', 'edit-find-replace', undef, 'Search and replace');
	my $page = $self->ToolRightPageAdd('SearchReplace', 'edit-find-replace', undef, 'Search and replace', 350);

	my $searchterm = '';
	my $replaceterm = '';
	my $casesensitive = '-case';
	my $useregex = '-exact';
	my $searchmode = 'Search in current document';

	$self->{CASE} = \$casesensitive;
	$self->{FRESH} = {};
	$self->{LASTRESULTS} = [];
	$self->{MODE} = \$searchmode;
	$self->{OFFSET} = {};
	$self->{REPLACE} = \$replaceterm;
	$self->{REPLACED} = 0;
	$self->{REGEX} = \$useregex;
	$self->{SEARCH} = \$searchterm;
	$self->{SKIPPED} = 0;

	my @padding = (-padx => 2, -pady => 2);

	my $sa = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(@padding, -fill => 'x');

	my $sf = $sa->Frame->pack(-expand => 1, -fill => 'x');
	$sf->Label(
	   -text => 'Search',
	   -width => 7,
	   -anchor => 'e',
	)->pack(@padding, -side => 'left');
	my $se = $sf->Entry(
	   -textvariable => \$searchterm,
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');
	$se->bind('<Return>', [$self, 'Find']);

	my $rf = $sa->Frame->pack(-expand => 1, -fill => 'x');
	$rf->Label(
	   -text => 'Replace',
	   -width => 7,
	   -anchor => 'e',
	)->pack(@padding, -side => 'left');
	$rf->Entry(
	   -textvariable => \$replaceterm,
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');

	my $sb = $page->LabFrame(
		-labelside => 'acrosstop',
		-relief => 'groove',
		-label => 'Search options',
	)->pack(@padding, -fill => 'x');

	$sb->Checkbutton(
	   -variable => \$useregex,
	   -text => 'Regular expression',
		-onvalue => '-regexp',
		-offvalue => '-exact',
	   -anchor => 'w',
	)->pack(@padding, -fill => 'x');
	$sb->Checkbutton(
	   -variable => \$casesensitive,
		-onvalue => '-case',
		-offvalue => '-nocase',
	   -text => 'Case sensitive',
	   -anchor => 'w',
	)->pack(@padding, -fill => 'x');
	my $mb = $sb->Menubutton(
#		-relief => 'raised',
	   -anchor => 'w',
		-textvariable => \$searchmode,
	)->pack(@padding, -fill => 'x');
	my @menu = ();
	for ($srchcur, $srchall, $srchprj, $srchres) {
		my $mode = $_;
		push @menu, [command => $mode,
			-command => sub { $searchmode = $mode },
		];
	}
	$mb->configure(-menu => $mb->Menu(
		-menuitems => \@menu,
	));


	my $sc = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(@padding, -fill => 'x');
	$sc->Button(
		-command => ['Find', $self],
		-text => 'Find',
	)->pack(@padding, -fill => 'x');
	$sc->Button(
		-command => ['Replace', $self],
		-text => 'Replace',
	)->pack(@padding, -fill => 'x');
	$sc->Button(
		-command => ['Skip', $self],
		-text => 'Skip',
	)->pack(@padding, -fill => 'x');
	$sc->Button(
		-command => ['Clear', $self],
		-text => 'Clear',
	)->pack(@padding, -fill => 'x');


	my $tf = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(@padding, -expand => 1, -fill => 'both');
	my $bf = $tf->Frame->pack(-fill => 'x');
	$bf->Button(
		-text => 'Previous',
		-command => ['BrowsePrevious', $self],
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');
	$bf->Button(
		-text => '  Next  ',
		-command => ['BrowseNext', $self],
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');
	my $results = $tf->Scrolled('ITree',
		-height => 4,
		-browsecmd => ['Select', $self],
		-scrollbars => 'osoe',
		-separator => '@',
	)->pack(@padding, -expand => 1, -fill => 'both');
	$results->autosetmode;
	$self->{RESULTSLIST} = $results;

	return $self;
}

sub BrowseNext {
	my $self = shift;
	my $list = $self->{RESULTSLIST};
	my ($sel) = $list->infoSelection;

	#select the first hit if no selection is set
	unless (defined $sel) {
		$sel = $self->SelectFirst;
		return 
	}
	return unless defined $sel;

	#select the first hit is the last hit is selected
	my $last = $self->GetLast;
	if ($self->IsSelected($last)) {
		$sel = $self->SelectFirst;
		return 
	}

	my ($name, $index) = split(/@/, $sel);
	if (defined $index) {
		my $next = $list->infoNext($sel);
		return unless defined $next;
		my ($nname, $nindex) = split(/@/, $next);
		unless (defined $nindex) {
			my @d = $list->infoChildren($nname);
			if (@d) {
				$self->Select($d[0]);
				return 
			}
		} else {
			$self->Select($next);
		}
	}
}

sub BrowsePrevious {
	my $self = shift;
	my $list = $self->{RESULTSLIST};
	my ($sel) = $list->infoSelection;

	#select the last hit if no selection is set
	unless (defined $sel) {
		$self->SelectLast;
		return 
	}
	return unless defined $sel;

	#select the last hit is the first hit is selected
	my $first = $self->GetFirst;
	if ($self->IsSelected($first)) {
		$self->SelectLast;
		return 
	}
	my ($name, $index) = split(/@/, $sel);
	if (defined $index) {
		my $prev = $list->infoPrev($sel);
		return unless defined $prev;
		my ($nname, $nindex) = split(/@/, $prev);
		unless (defined $nindex) { #previous is a file entry;
			$prev = $list->infoPrev($prev);
			$self->Select($prev);
		} else { #previous is a hit entry
			$self->Select($prev);
		}
	}
}

sub Clear {
	my $self = shift;
	my $list = $self->{RESULTSLIST};
	my @c = $list->infoChildren('');
	$self->{LASTRESULTS} = \@c;
	$list->deleteAll;
	$self->{OFFSET} = {};
	$self->repl(0);
	$self->skipped(0);
}

sub ClearFresh {
	my ($self, $name) = @_;
	if (exists $self->{FRESH}->{$name}) {
		$self->DocWidget($name)->unselectAll;
		delete $self->{FRESH}->{$name};
	}
}

sub DocSelected {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	return $mdi->docSelected;
}

sub DocWidget {
	my ($self, $name) = @_;
	my $mdi = $self->extGet('CoditMDI');
	return $mdi->docGet($name)->CWidg if defined $name
}

sub Find {
	my $self = shift;
	my $search = $self->{SEARCH};
	if ($$search eq '') {
		$self->popMessage("Please enter a search phrase", 'dialog-warning', 32);
		return
	}
	$self->Clear;
	my $mode = $self->{MODE};
	my $mdi = $self->extGet('CoditMDI');
	if ($$mode eq $srchcur) {
		my $cur = $mdi->docSelected;
		return unless defined $cur;
		$self->FindInDoc($cur);
	} elsif ($$mode eq $srchall) {
		my @list = ($mdi->docList, $mdi->deferredList);
		for (@list) {
			$self->FindInDoc($_);
		}
	} elsif ($$mode eq $srchprj) {
		$self->FindInProject;
	} elsif ($$mode eq $srchres) {
		$self->FindInResults;
	}
}

sub FindInDoc {
	my ($self, $name) = @_;

	my $mdi = $self->mdi;
	my $search = $self->{SEARCH};
	my $case = $self->{CASE};
	my $regex = $self->{REGEX};
	my $results = $self->{RESULTSLIST};
	if (($mdi->docExists($name)) and (not $mdi->deferredExists($name))) {
		my $widg = $mdi->docGet($name)->CWidg;
		my $srch = $$search;
		$srch = quotemeta($srch) if $$regex eq 'exact';
		$widg->FindAll($$regex, $$case, $srch);
		my @ranges = $widg->tagRanges('sel');
		if (@ranges) {
			$results->add($name,
				-text => $self->abbreviate($name, 30),
				-itemtype => 'imagetext',
				-image =>  $self->getArt('text-x-plain')
			); 
			$results->autosetmode;
		}

		while (@ranges) {
			my $begin = shift @ranges;
			my $end = shift @ranges;
			my $line = $widg->get("$begin linestart", "$begin lineend - 1c");
			$line =~ s/^\s+//; #removing leading spaces and tabs
			$results->add($name . '@' . $begin,
				-text => "$begin - $line",
				-data => $begin,
			);
			$results->autosetmode;
		}
		$self->{FRESH}->{$name} = 1;
	} else {
		my @hits = ();
		if (open IFILE, "<", $name) {
			my $linenum = 1;
			my $srch = $$search;
			$srch = quotemeta($srch) if $$regex eq 'exact';
			while (<IFILE>) {
				my $line = $_;
				$line =~ s/\n$//; #remove trailing newline
				my $copy = $line;
				$line =~ s/^\s+//; #remove leading spaces
				my $offset = 0;
				while ($copy =~ /($srch)/g) {
					my $pos = pos($copy);
					$pos = $pos - length($1);
					push @hits, ["$linenum.$pos", $line];
				}
				$linenum ++;
			}
			close IFILE;
		}
		if (@hits) {
			$results->add($name,
				-text => $self->abbreviate($name, 30),
				-itemtype => 'imagetext',
				-image =>  $self->getArt('text-x-plain')
			); 
		}
		while (@hits) {
			my $hit = shift @hits;
			my $begin = $hit->[0];
			my $line = $hit->[1];
			$results->add($name . '@' . $begin,
				-text => "$begin - $line",
				-data => $begin,
			);
			$results->autosetmode;
		}
	}
	$self->update;
}

sub FindInProject {
	my $self = shift;
	my $git = $self->extGet('Plugins')->plugGet('Git');
	unless (defined $git) {
		$self->popMessage('Plugin git must be loaded for this', 'dialog-warning');
		return
	}
	my $project = $git->projectCurrent;
	if ($project eq '') {
		$self->popMessage('No project selected in Git plugin', 'dialog-warning');
		return
	}
	my @list = $git->gitFileList($project);
	for (@list) {
		$self->FindInDoc($_) if -T $_;
	}
}

sub FindInResults {
	my $self = shift;
	my $list = $self->{LASTRESULTS};
	for (@$list) {
		$self->FindInDoc($_);
	}
	
}

sub FinishedCheck {
	my $self = shift;
	my $cur = $self->GetCurrent;
	unless (defined $cur) {
		$self->{RESULTSLIST}->selectionClear;
		my $num = $self->{REPLACES};
		$self->Report(1);
		return 1
	}
	return 0;
}

sub GetCurrent {
	my $self = shift;
	my $list = $self->{RESULTSLIST};
	my @c = $list->infoChildren('');
	my $mdi = $self->extGet('CoditMDI');

	for (@c) {
		my $name = $_;
		my @hits = $list->infoChildren($name);
		my $offset = $self->OffsetGet($name);
		my $cur = $hits[$offset];
		if (defined $cur) {
			$mdi->docSelect($name);
			if(exists $self->{FRESH}->{$name}) {
				$self->DocWidget($name)->unselectAll;
				delete $self->{FRESH}->{$name};
			}
			return $cur
		}
	}
	return undef;
}

sub GetFirst {
	my ($self, $name) = @_;
	my @c = $self->GetList($name);
	if (@c) {
		return $c[0]
	}
}

sub GetLast {
	my ($self, $name) = @_;
	my @c = $self->GetList($name, 1);
	if (@c) {
		my $size = @c;
		return $c[$size - 1]
	}
}

sub GetList {
	my ($self, $name, $flag) = @_;
	$flag = 0 unless defined $flag;
	my $list = $self->{RESULTSLIST};
	unless (defined $name) {
		my @d = $list->infoChildren('');
		if ($flag) {
			my $size = @d;
			return $list->infoChildren($d[$size - 1]);
		} else {
			return $list->infoChildren($d[0]);
		}
	} else {
		return $list->infoChildren($name);
	}
}

sub GoCurrent {
	my $self = shift;
	my $cur = $self->GetCurrent;
	return unless defined $cur;
	$self->Select($cur);
}

sub IsSelected {
	my ($self, $entry) = @_;
	my $list = $self->{RESULTSLIST};
	my ($sel) = $list->infoSelection;
	return 0 unless defined $sel;
	return $sel eq $entry
}

sub OffsetGet {
	my ($self, $name) = @_;
	return $self->{OFFSET}->{$name} if exists $self->{OFFSET}->{$name};
	return 0
}

sub OffsetInc {
	my ($self, $name) = @_;
	my $offset = $self->OffsetGet($name);
	$offset ++;
	$self->OffsetSet($name, $offset);
}

sub OffsetSet {
	my ($self, $name, $offset) = @_;
	$self->{OFFSET}->{$name} = $offset	
}

sub Replace {
	my $self = shift;
	my $cur = $self->GetCurrent;
	unless (defined $cur) {
		$self->logWarning('Nothing to replace');
		return 
	}
	my ($name, $index) = split(/@/, $cur);
	my $widg = $self->DocWidget($name);
	my $list = $self->{RESULTSLIST};
	if ($widg->selectionExists) {
		my $replace = $self->{REPLACE};
		$widg->ReplaceSelectionsWith($$replace);
		$list->deleteEntry($cur);

		$self->repl($self->repl + 1);
		$self->Report;
		my @h = $list->infoChildren($name);
		$list->deleteEntry($name) unless @h;
		$self->GoCurrent unless $self->FinishedCheck;
	} else {
		$self->GoCurrent unless $self->FinishedCheck;
	}
}

sub repl {
	my $self = shift;
	$self->{REPLACED} = shift if @_;
	return $self->{REPLACED}
}

sub Report {
	my ($self, $flag) = @_;
	$flag = 0 unless defined $flag;
	my $rep = $self->repl;
	my $skp = $self->skipped;
	my $text = "Made $rep replaces and skipped $skp";
	$text = "Replacing finished. $text" if $flag;
	$self->log($text)
}

sub Select {
	my ($self, $entry) = @_;
	my ($name, $index) = split(/@/, $entry);
	my $search = $self->{SEARCH};
	my $mdi = $self->extGet('CoditMDI');
	my $list = $self->{RESULTSLIST};
	$list->selectionClear;
	$list->anchorClear;
	$list->selectionSet($entry);
	return if $entry eq $name;
	$self->cmdExecute('doc_open', $name) unless ($mdi->docExists($name));
	$mdi->docSelect($name);
	my $widg = $mdi->docGet($name)->CWidg;
	$widg->unselectAll;
	$widg->goTo($index);
	my $len = length($$search);
	$widg->tagAdd('sel', $index, "$index + $len c");
	$widg->focus;
}

sub skipped {
	my $self = shift;
	$self->{SKIPPED} = shift if @_;
	return $self->{SKIPPED}
}

sub Skip {
	my $self = shift;
	my $cur = $self->GetCurrent;
	unless (defined $cur) {
		$self->logWarning('Nothing to skip');
		return 
	}
	my ($name, $index) = split(/@/, $cur);
	$self->OffsetInc($name);
	$self->skipped($self->skipped + 1);
	$self->Report;
	$self->GoCurrent unless $self->FinishedCheck;
}

sub SelectFirst {
	my $self = shift;
	my $first = $self->GetFirst;
	$self->Select($first) if defined $first
}

sub SelectLast {
	my $self = shift;
	my $last = $self->GetLast;
	$self->Select($last) if defined $last
}

sub Unload {
	my $self = shift;
	$self->ToolRightPageRemove('SearchReplace');
#	$self->extGet('ToolPanel')->deletePage('SearchReplace');
	my $id = $self->{REFRESHID};
	$self->afterCancel($id) if defined $id;
	return $self->SUPER::Unload
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=back

=cut



1;














