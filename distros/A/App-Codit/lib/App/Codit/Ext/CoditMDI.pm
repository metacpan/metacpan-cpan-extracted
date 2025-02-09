package App::Codit::Ext::CoditMDI;

=head1 NAME

App::Codit::Ext::CoditMDI - Multiple Document Interface for App::Codit

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.17";

use base qw( Tk::AppWindow::Ext::MDI );

#require Tk::AppWindow::PluginsForm;
require App::Codit::CoditTagsEditor;
require App::Codit::Macro;
require Tk::YADialog;

my @navcontextmenu = (
	[ 'menu_normal',    undef,  '~Close',  'doc_close',	 'document-close', '*CTRL+SHIFT+O'],
	[ 'menu_normal',    undef,  '~Delete',  'doc_delete_dialog',	 'edit-delete'],
	[ 'menu_separator', undef,  'c1'],
	[ 'menu_normal',    undef,  '~Collapse all',  'nav_collapse'],
	[ 'menu_normal',    undef,  '~Expand all',  'nav_expand'],
);

=head1 SYNOPSIS

my $app = new App::Codit(@options,
	-extensions => ['CoditMDI'],
);
$app->MainLoop;

=head1 DESCRIPTION

Inherits L<Tk::AppWindow::Ext::MDI>.

This is a specially crafted multiple document interface for l<App::Codit>.

=head1 CONFIG VARIABLES

=over 4

=item B<-doc_autoindent> I<hookable>

Sets and returns the autoindent option of the currently selected document.

=item B<-doc_wrap> I<hookable>

Sets and returns the wrap option of the currently selected document.

=item B<-doc_view_folds> I<hookable>

Sets and returns the showfolds option of the currently selected document.

=item B<-doc_view_numbers> I<hookable>

Sets and returns the shownumbers option of the currently selected document.

=item B<-doc_view_status> I<hookable>

Sets and returns the showstatus option of the currently selected document.

=item B<-doc_wrap>

Sets and returns the wrap option of the currently selected document.

=back

=head1 COMMANDS

=over 4

=item B<bookmark_add>

=item B<bookmark_clear>

=item B<bookmark_fill>

=item B<bookmark_next>

=item B<bookmark_prev>

=item B<bookmark_remove>

=item B<doc_autoindent>

Sets and returns the autoindent option of the currently selected document.

=item B<doc_case_lower>

If there is a selection it turns it to lower case.
Else it only turns the character at the insert position to lower case.

=item B<doc_case_upper>

If there is a selection it turns it to upper case.
Else it only turns the character at the insert position to upper case.

=item B<doc_delete>

Closes the current selected document and deletes the document file from disk.
Use with caution.

=item B<doc_delete_dialog>

Same as I<doc_delete> except it first asks nicely if you really want to do that.

=item B<doc_find>

Pops up the search bar in the currently selected document.

=item B<doc_fix_indent>

Asks for the number of spaces per tab and attempts
to reformat the indentation taking the indentstyle into account.

If a selection exists it will do this for the selection, otherwise it
will scan the whole document.

=item B<doc_get_sel>

Returns the begin and end index of the current selection.

=item B<doc_get_text> I<$begin>, I<$end>

Returns the text in the current selected document from index $begin to index $end.

=item B<doc_remove_trailing>

Removes spaces at the end of each line.

If a selection exists it will do this for the selection, otherwise it
will scan the whole document.

=item B<doc_replace>

Pops up the search and replace bar in the currently selected document.

=item B<doc_wrap>

Sets and returns the wrap option of the currently selected document.

=item B<edit_delete>, I<$begin>, I<$end>

Deletes text in the currently selected document. It takes two indices as parameters.

=item B<edit_insert>, I<$index>, I<$text>

Inserts text in the currently selected document. It takes an index and a string as parameters.

=item B<edit_replace>, I<$begin>, I<$end>, I<$text>

Replaces text in the currently selected document. It takes two indices and a text as parameters.

=item B<key_released>, I<$doc>, I<$key>

Dummy command only meant for hooking on by plugins. Called every time a visible character
key was pressed.

=item B<modified>, I<$doc>, I<$index>

Called every time you make an edit, it gets a document name and an index as parameters.
It checks if there are any macros that should be restarted.
Many plugins hook on to this command.

=back

=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
#	$self->Require('Navigator');
	$self->{MACROS} = {};
	$self->{SHOWSPACES} = 0;
	$self->{FIXINDENTSPACES} = 3;

	my $nav = $self->Subwidget('NAVTREE');

	$self->configInit(
		-doc_autoindent => ['docAutoIndent', $self],
		-doc_show_spaces => ['docShowSpaces', $self],
		-doc_view_folds => ['docViewFolds', $self],
		-doc_view_numbers => ['docViewNumbers', $self],
		-doc_view_status => ['docViewStatus', $self],
		-doc_wrap => ['docWrap', $self],
	);
	$self->cmdConfig(
		bookmark_add => ['bookmarkAdd', $self],
		bookmark_clear => ['bookmarkClear', $self],
		bookmark_fill => ['bookmarkFill', $self],
		bookmark_next => ['bookmarkNext', $self],
		bookmark_prev => ['bookmarkPrev', $self],
		bookmark_remove => ['bookmarkRemove', $self],
		doc_autoindent => ['docAutoIndent', $self],
		doc_case_lower => ['docCaseLower', $self],
		doc_case_upper => ['docCaseUpper', $self],
		doc_delete => ['docDelete', $self],
		doc_delete_dialog => ['docDeleteDialog', $self],
		doc_find => ['docPopFindReplace', $self, 1],
		doc_fix_indent => ['docFixIndent', $self],
		doc_get_sel => ['docGetSel', $self],
		doc_get_text => ['docGetText', $self],
		doc_remove_trailing => ['docRemoveTrailing', $self],
		doc_replace => ['docPopFindReplace', $self, 0],
		doc_wrap => ['docWrap', $self],
		edit_delete => ['editDelete', $self],
		edit_insert => ['editInsert', $self],
		edit_replace => ['editReplace', $self],
		key_released => ['keyReleased', $self],
		modified => ['contentModified', $self],
		nav_collapse => ['navCollapse', $self],
		nav_expand => ['navExpand', $self],
	);
	return $self;
}

sub _mcr { return $_[0]->{MACROS} }

sub bookmarkAdd {
	my $self = shift;
	my $doc = $self->docSelected;
	if (defined $doc) {
		my $w = $self->docGet($doc)->CWidg;
		$w->bookmarkNew
	}
}

sub bookmarkClear {
	my $self = shift;
	my $doc = $self->docSelected;
	if (defined $doc) {
		my $w = $self->docGet($doc)->CWidg;
		$w->bookmarkRemoveAll;
	}
}

sub bookmarkFill {
	my $self = shift;
	my $mnu = $self->extGet('MenuBar');
	my ($menu, $index) = $mnu->FindMenuEntry('Bookmarks');
	my $submenu = $menu->entrycget($index, '-menu');
	my $i = $submenu->index('end');
	if ($i > 7) {
		$submenu->delete(8, 'last');
	}
	my $doc = $self->docSelected;
	if (defined $doc) {
		my $w = $self->docGet($doc)->CWidg;
		my @list = $w->bookmarkList;
		for (@list) {
			$submenu->add('command',
				-label => "$_ - " . $w->bookmarkText($_),
				-command => ['bookmarkGo', $w, $_],
			);
		}
	}
}

sub bookmarkNext {
	my $self = shift;
	my $doc = $self->docSelected;
	if (defined $doc) {
		my $w = $self->docGet($doc)->CWidg;
		$w->bookmarkNext
	}
}

sub bookmarkPrev {
	my $self = shift;
	my $doc = $self->docSelected;
	if (defined $doc) {
		my $w = $self->docGet($doc)->CWidg;
		$w->bookmarkPrev
	}
}

sub bookmarkRemove {
	my $self = shift;
	my $doc = $self->docSelected;
	if (defined $doc) {
		my $w = $self->docGet($doc)->CWidg;
		$w->bookmarkRemove
	}
}

sub CmdDocClose {
	my ($self, $name) =  @_;
	$name = $self->docSelected unless defined $name;
		$self->macroRemoveAll($name);
	my $result = $self->SUPER::CmdDocClose($name);
	if ($result) {
		$self->after(100, sub {
			my @list = $self->docFullList;
			$self->cmdExecute('doc_new') unless @list;
		});
	}
	return $result
}

sub CmdDocNew {
	my $self = shift;
	my $result = $self->SUPER::CmdDocNew(@_);
	$self->disposeUntitled if $result;
	return $result
}

#sub CmdDocOpen {
#	my $self = shift;
#	my $result = $self->SUPER::CmdDocOpen(@_);
#	$self->disposeUntitled if $result;
#	return $result
#}

sub contentModified {
	my $self = shift;
	my ($doc, $index) = @_;
	if ($self->docShowSpaces) {
		my $macro = $self->macroGet($doc, 'space');
		if (defined $macro) {
			my $line = $macro->widg->linenumber($index);
			$macro->line($line);
			$macro->start;
		}
	}
	return @_;
}

sub ContextMenu {
	my $self = shift;
	return $self->extGet('MenuBar')->menuContext($self->GetAppWindow,
		[ 'menu_normal',    undef,  '~Copy',       '<Control-c>',	 'edit-copy',       '*CTRL+C'],
		[ 'menu_normal',    undef,  'C~ut',        '<Control-x>',	 'edit-cut',        '*CTRL+X'],
		[ 'menu_normal',    undef,  '~Paste',      '<Control-v>',	 'edit-paste',      '*CTRL+V'],
		[ 'menu_separator', undef,  'c1'],
		[ 'menu_normal',    undef,  '~Select all', '<Control-a>',  'edit-select-all', '*CTRL+A'],
		[ 'menu_separator', undef,  'c2'],
		[ 'menu_normal',    undef,  'Co~mment',    '<Control-g>',   undef,            '*CTRL+G'],
		[ 'menu_normal',    undef,  '~Uncomment',  '<Control-G>',   undef,            '*CTRL+SHIFT+G'],
		[ 'menu_separator', undef,  'c3' ],
		[ 'menu_normal',    undef,  '~Indent',     '<Control-j>',   'format-indent-more','*CTRL+J'],
		[ 'menu_normal',    undef,  'Unin~dent',   '<Control-J>',   'format-indent-less','*CTRL+SHIFT+J'],
		[ 'menu_separator', undef,  'c4' ],
		[ 'menu_check',     undef,  'A~uto indent', undef, '-doc_autoindent', undef, 0, 1],
		[ 'menu_radio_s',   undef,  '~Wrap',  [qw/char word none/],  'text-wrap', '-doc_wrap'],
	)
}

sub CreateContentHandler {
	my ($self, $name) = @_;
	my $h = $self->SUPER::CreateContentHandler($name);
	$h->Name($name);
	return $h;
}

sub deferredOpen {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $options = $self->deferredOptions($name);
	my $bookmarks = delete $options->{'bookmarks'};
	$self->SUPER::deferredOpen($name);
	$self->after(100, sub {
		if (defined $bookmarks) {
			my $w = $self->docGet($name)->CWidg;
			while ($bookmarks =~ s/^(\d+)\s//) {
				$w->bookmarkNew($1);
			}
		}
	});
}

sub disposeUntitled {
	my $self = shift;
	my @list = $self->docListDisplayed;
	my $untitled = $list[0];
	if ((@list eq 2) and ($untitled =~ /^Untitled/)){
		return if -e $untitled;
		return if $self->docModified($untitled);
		$self->cmdExecute('doc_close', $untitled);
	}
}

sub docAutoIndent {
	my $self = shift;
	return $self->docOption('-contentautoindent', @_);
}

sub docCase {
	my ($self, $upper) = @_;
	$upper = 1 unless defined $upper;
	my $widg = $self->docWidget;
	return unless defined $widg;
	$widg->caseChange($upper);
}

sub docCaseLower { $_[0]->docCase(0) }

sub docCaseUpper { $_[0]->docCase(1) }

sub docDelete {
	my ($self, $name) = @_;
	my $r = 1;
	$name = $self->docSelected unless defined $name;
	if (defined $name) {
		$r = $self->cmdExecute('doc_close', $name) if $self->docExists($name);
		unlink $name if $r;
	}
	return $name if $r;
	return ''
}

sub docDeleteDialog {
	my ($self, $name) = @_;
	$name = $self->docSelected unless defined $name;
	if (defined $name) {
		my $answer = $self->popDialog(
			'Deleting file',
			"Are you sure you want to delete\n$name?",
			'dialog-warning',
			'Yes', 'No',
		);
		return $self->cmdExecute('doc_delete', $name) if $answer eq 'Yes';
	}
	return ''
}

sub docFixIndent {
	my ($self, $name) = @_;
	$name = $self->docSelected unless defined $name;
	my $widg = $self->docGet($name)->CWidg;

	my $val = $widg->cget('-indentstyle');
	$val = $self->{FIXINDENTSPACES} if $val eq 'tab';
	$val = 3 unless defined $val;
	my $spaces_per_tab = $self->popEntry('Spaces', 'Spaces per tab:', $val);
	$self->{FIXINDENTSPACES} = $spaces_per_tab;

	if (defined $spaces_per_tab) {
		my $macro = $self->macroInit($name, 'fix_indent', ['docFixIndentCycle', $self, $spaces_per_tab]);

		#if a selection exists only do selection
		my @sel = $widg->tagRanges('sel');
		if (@sel) {
			$macro->line($widg->linenumber(shift @sel));
			$macro->last($widg->linenumber(shift @sel));
		}

		$macro->start;
	}
}

sub docFixIndentCycle {
	my ($self, $spaces_per_tab, $widg, $line) = @_;
	my $begin = $widg->index("$line.0");
	my $end = $widg->index("$begin lineend");
	my $text = $widg->get($begin, $end);
	if ($text =~ /^([\s|\t]+)/) {
		my $spaces = $1;
		my $s = 0;
		my $pos = 0;
		my $itext = '';
		$itext = "$itext " while length($itext) ne $spaces_per_tab;
		while ($spaces ne '') {
			my $char = substr $spaces, 0, 1, '';
			if ($widg->cget('-indentstyle') eq 'tab') {
				if ($char eq "\t") {
					$s = 0;
				} else {
					$s ++;
					my $lp = $pos;
					my $linepos = $widg->index("$begin + $lp c");
					$widg->delete($linepos, "$linepos + 1 c");
					if ($s eq $spaces_per_tab) {
						$widg->insert($linepos, "\t");
						$s = 0;
						$pos ++;
					}
				}
#				$pos ++;
			} else {
				if ($char eq "\t") {
					my $linepos = $widg->index("$begin + $pos c");
					$widg->delete($linepos, "$linepos + 1 c");
					$widg->insert($linepos, $itext);
					$pos = $pos + $spaces_per_tab - 1;
				}
				$pos ++
			}
		}
	}
}

sub docGetSel {
	my $self = shift;
	my $doc = $self->docSelected;
	return unless defined $doc;
	return $self->docGet($doc)->tagRanges('sel');
}

sub docGetText {
	my $self = shift;
	my $doc = $self->docSelected;
	return unless defined $doc;
	return $self->docGet($doc)->get(@_);
}

sub docOption {
	my $self = shift;
	my $item = shift;
	croak 'Option is not defined' unless defined $item;
	return if $self->configMode;
	my $sel = $self->docSelected;
	return unless defined $sel;
	my $doc = $self->docGet($sel);
	if (@_) {
		$doc->configure($item, shift);
	}
	return $doc->cget($item);
}

sub docPopFindReplace {
	my ($self, $flag) = @_;
	my $sel = $self->docSelected;
	return unless defined $sel;
	my $doc = $self->docGet($sel);
	$doc->CWidg->FindAndOrReplace($flag);
}

sub docRemoveTrailing {
	my ($self, $name) = @_;
	$name = $self->docSelected unless defined $name;

	my $macro = $self->macroInit($name, 'trailing', ['docRemoveTrailingCycle', $self]);
	my $widg = $self->docGet($name)->CWidg;

	#if a selection exists only do selection
	my @sel = $widg->tagRanges('sel');
	if (@sel) {
		$macro->line($widg->linenumber(shift @sel));
		$macro->last($widg->linenumber(shift @sel));
	}

	$macro->start;
}

sub docRemoveTrailingCycle {
	my ($self, $widg, $line) = @_;
	my $begin = $widg->index("$line.0");
	my $end = $widg->index("$line.0 lineend");
	my $text = $widg->get($begin, $end);
	if ($text =~ /(\s+)$/) {
		my $spaces = $1;
		my $l = length($spaces);
		$widg->delete("$end - $l c", $end);
	}
}

sub docSelect {
	my ($self, $name) = @_;
	return if $self->selectDisabled;
	$self->SUPER::docSelect($name);
	if ($self->docShowSpaces) {
		$self->spaceMacroAdd($name);
	} else {
		$self->spaceMacroRemove($name);
	}
}

sub docShowSpaces {
	my ($self, $flag) = @_;
	my $cur = $self->{SHOWSPACES};
	if ((defined $flag) and ($flag ne $cur)) {
		$self->{SHOWSPACES} = $flag;
		my $sel = $self->docSelected;
		if (defined $sel) {
#			my $widg = $self->docGet($sel)->CWidg;
			if ($flag) {
				$self->spaceMacroAdd($sel);
			} else {
				$self->spaceMacroRemove($sel);
			}
		}
	}
	return $self->{SHOWSPACES}
}

sub docSelectFirst {
	my $self = shift;
	my $sel = $self->docSelected;
	unless (defined $sel) {
		my @list = $self->docFullList;
		$self->cmdExecute('doc_select', $list[0]) if @list;
	}
}

sub docViewFolds {
	my $self = shift;
	return $self->docOption('-showfolds', @_);
}

sub docViewNumbers {
	my $self = shift;
	return $self->docOption('-shownumbers', @_);
}

sub docViewStatus {
	my $self = shift;
	return $self->docOption('-showstatus', @_);
}

=item B<docWidget>

Returns a reference to the Tk::CodeText widget
of the current selected document. Returns undef
if no document is selected.

=cut

sub docWidget {
	my $self = shift;
	my $name = $self->docSelected;
	return undef unless defined $name;
	my $doc = $self->docGet($name);
	return undef unless defined $doc;
	return $doc->CWidg;
}

sub docWrap {
	my $self = shift;
	return $self->docOption('-contentwrap', @_);
}

=item B<editDelete>I<($begin, $end)>

Deletes text in the currently selected document. It takes two indices as parameters.

=cut

sub editDelete {
	my $self = shift;
	my $doc = $self->docSelected;
	return unless defined $doc;
	$self->docGet($doc)->delete(@_);
}


=item B<editInsert>I<($index, $text)>

Inserts text in the currently selected document. It takes an index and the text as parameters.

=cut

sub editInsert {
	my $self = shift;
	my $doc = $self->docSelected;
	return unless defined $doc;
	$self->docGet($doc)->insert(@_);
}

=item B<editReplace>I<($begin, $end, $text)>

Inserts text in the currently selected document. It takes indices $begin and $end and the text as parameters.

=cut

sub editReplace {
	my $self = shift;
	my $doc = $self->docSelected;
	return unless defined $doc;
	$self->docGet($doc)->replace(@_);
}

sub keyReleased {
#	my ($self, $name, $key) = @_;
}

=back

Macros are callbacks executed in the background. For each line in the document the macro is linked to,
the callback is executed with a reference to the text widget and the line number as parameter.
the macro ends after the last line has been processed. Codit uses macro callback to do tasks like show
leading and trailing tabs and spaces and reparing indentation.

=over 4

=item B<macroGet>I<($doc, $name)>

Returns a reference to the macro object $name belonging to $doc.

=cut

sub macroGet {
	my ($self, $doc, $name) = @_;
	my $mcr = $self->_mcr;
	return unless exists $mcr->{$doc};
	my $l = $mcr->{$doc};
	for (@$l) {
		my $n = $_->name;
		return $_ if $_->name eq $name
	}
	return undef
}

=item B<macroInit>I<($doc, $name, $call)>

Creates a new macro object $name for $doc with $call as callback.

=cut

sub macroInit {
	my ($self, $doc, $name, $call) = @_;
	unless (defined $self->macroGet($doc, $name)) {
		my $macro = App::Codit::Macro->new($self, $name, $doc, $call);
		my $mcr = $self->_mcr;
		$mcr->{$doc} = [] unless exists $mcr->{$doc};
		my $l = $mcr->{$doc};
		push @$l, $macro;
		return $macro;
	}
	warn "macro $name for $doc already exists";
	return undef
}

=item B<macroList>I<($doc)>

Returns a list with the objects of loaded macros for $doc.

=cut

sub macroList {
	my ($self, $doc) = @_;
	my $mcr = $self->_mcr;
	return unless exists $mcr->{$doc};
	my $l = $mcr->{$doc};
	return @$l;
}

=item B<macroRemove>I<($doc, $name)>

Removes macro $name for $doc from the stack.

=cut

sub macroRemove {
	my ($self, $doc, $name) = @_;
	if (defined $self->macroGet($doc, $name)) {
		my $mcr = $self->_mcr;
		my $l = $mcr->{$doc};
		my @list = @$l;
		my $count = 0;
		for (@list) {
			if ($_->name eq $name) {
				$_->stop;
				last;
			} else {
				$count ++;
			}
		}
		splice @list, $count, 1;
		if (@list) {
			$mcr->{$doc} = \@list;
		} else {
			delete $mcr->{$doc}
		}
		return
	}
	warn "macro $name for $doc does not exist"
}

=item B<macroRemoveAll>I<($doc)>

Removes all macros for $doc from the stack.

=cut

sub macroRemoveAll {
	my ($self, $doc) = @_;
	my @list = $self->macroList($doc);
	for (@list) {
		$self->macroRemove($doc, $_->name);
	}
}

sub MenuItems {
	my $self = shift;

	#creating the context menu for the navigator tree
	$self->after(1000, ['navContextMenu', $self]);

	my @items = $self->SUPER::MenuItems;
	return (@items,
		[ 'menu',           undef,             '~Edit'],
		[ 'menu_normal',    'Edit::',           '~Copy',             '<Control-c>',	      'edit-copy',      '*CTRL+C'],
		[ 'menu_normal',    'Edit::',          'C~ut',					          '<Control-x>',			    'edit-cut',	      '*CTRL+X'],
		[ 'menu_normal',    'Edit::',          '~Paste',             '<Control-v>',	      'edit-paste',     '*CTRL+V'],
		[ 'menu_separator', 'Edit::',          'e1' ],
		[ 'menu_normal',    'Edit::',          'U~ndo',              '<Control-z>',       'edit-undo',      '*CTRL+Z'],
		[ 'menu_normal',    'Edit::',          '"~Redo',             '<Control-Z>',       'edit-redo',      '*CTRL+SHIFT+Z'],
		[ 'menu_separator', 'Edit::',          'e2'],
		[ 'menu_normal',    'Edit::',          'Co~mment',           '<Control-g>',       undef,            '*CTRL+G'],
		[ 'menu_normal',    'Edit::',          '~Uncomment',         '<Control-G>',       undef,            '*CTRL+SHIFT+G'],
		[ 'menu_separator', 'Edit::',          'e3' ],
		[ 'menu_normal',    'Edit::',          '~Indent',            '<Control-j>',       'format-indent-more','*CTRL+J'],
		[ 'menu_normal',    'Edit::',          'Unin~dent',          '<Control-J>',       'format-indent-less','*CTRL+SHIFT+J'],
		[ 'menu_separator', 'Edit::',          'e4' ],
		[ 'menu_normal',    'Edit::',          'U~pper case',        'doc_case_upper',    'format-text-uppercase','*CTRL+U'],
		[ 'menu_normal',    'Edit::',          '~Lower case',        'doc_case_lower',    'format-text-lowercase','*ALT+U'],
		[ 'menu_separator', 'Edit::',          'e5' ],
		[ 'menu_normal',    'Edit::',          '~Select all',        '<Control-a>',       'edit-select-all','*CTRL+A'],

		[ 'menu',           undef,             '~Bookmarks',         'bookmark_fill'],
		[ 'menu_normal',    'Bookmarks::',     '~Add bookmark',      'bookmark_add',      'bookmark_new',      'CTRL+B',],
		[ 'menu_normal',    'Bookmarks::',     '~Remove bookmark',   'bookmark_remove',   'bookmark_remove',   'CTRL+SHIFT+B',],
		[ 'menu_normal',    'Bookmarks::',     '~Clear bookmarks',   'bookmark_clear',    undef],
		[ 'menu_separator', 'Bookmarks::',     'b1' ],
		[ 'menu_normal',    'Bookmarks::',     '~Previous bookmark', 'bookmark_prev',     'bookmark_previous'],
		[ 'menu_normal',    'Bookmarks::',     '~Next bookmark',     'bookmark_next',     'bookmark_next'],
		[ 'menu_separator', 'Bookmarks::',     'b2' ],

		[ 'menu_separator', 'View::',          'v1' ],
		[ 'menu_check',     'View::',          'Show ~folds',          undef,   '-doc_view_folds', undef, 0, 1],
		[ 'menu_check',     'View::',          'Show ~line numbers',   undef,   '-doc_view_numbers', undef, 0, 1],
		[ 'menu_check',     'View::',          'Show ~document status',undef,   '-doc_view_status', undef, 0, 1],
		[ 'menu_separator', 'View::',          'v2' ],
		[ 'menu_check',     'View::',          'Show ~spaces and tabs','show-spaces', '-doc_show_spaces', undef, 0, 1],

		[ 'menu',           undef,             '~Tools'],
		[ 'menu_normal',    'Tools::',         '~Find',              'doc_find',          'edit-find',      '*CTRL+F',],
		[ 'menu_normal',    'Tools::',         '~Replace',	          'doc_replace',       'edit-find-replace','*CTRL+R',],
		[ 'menu_separator', 'Tools::',          't1' ],
		[ 'menu_check',     'Tools::',          'A~uto indent',        undef,   '-doc_autoindent', undef, 0, 1],
		[ 'menu_radio_s',   'Tools::',          '~Wrap',  [qw/char word none/],  undef, '-doc_wrap'],
		[ 'menu_separator', 'Tools::',          't1' ],
		[ 'menu_normal',    'Tools::',          'R~emove trailing spaces',   'doc_remove_trailing',],
		[ 'menu_normal',    'Tools::',          'F~ix indentation',   'doc_fix_indent',],
	);
}

sub navCollapse {
	my $self = shift;
	my $tree = $self->Subwidget('NAVTREE');
	$tree->collapseAll;
}

sub navContextMenu {
	my $self = shift;
	my $nav = $self->Subwidget('NAVTREE');
	my @items = @navcontextmenu;

	#checking if Git is loaded;
	my $git = $self->extGet('Plugins')->plugGet('Git');
	push @items, [ 'menu_normal', 'c1', '~Add to project', 'git_add', 'git-icon',] if defined $git;

	my $stack = $self->extGet('MenuBar')->menuStack(@items);
	$nav->configure('-contextmenu', $stack);
}

sub navExpand {
	my $self = shift;
	my $tree = $self->Subwidget('NAVTREE');
	$tree->expandAll;
}

sub SettingsPage {
	my $self = shift;
	my ($first) = $self->docList;
	my $doc = $self->docGet($first);
	return () unless defined $doc;
	my $themefile = $doc->cget('-highlight_themefile');
	my $historyfile = $self->extGet('ConfigFolder')->ConfigFolder . '/color_history';
	my @opt = (
		-applycall => sub {
			my $themefile = shift;
			my @list = $self->docList;
			for (@list) {
				my $d = $self->docGet($_);
				$d->configure(-highlight_themefile => $themefile);
				$d->configureTags;
			}
		},
		-defaultbackground => $doc->cget('-contentbackground'),
		-defaultforeground => $doc->cget('-contentforeground'),
		-defaultfont => $doc->CWidg->Subwidget('XText')->cget('-font'),
		-historyfile => $historyfile,
		-extension => $self,
		-themefile => $themefile,
	);
	return (
		'Highlighting' => ['CoditTagsEditor', @opt]
	)
}

sub spaceMacroAdd {
	my ($self, $doc) = @_;
	return if defined $self->macroGet($doc, 'space');
	my $macro = $self->macroInit($doc, 'space', ['spaceMacroCycle', $self]);
	$macro->remain(1);
	$macro->start;
#	$self->macroStart($doc, 'space');
}

sub spaceMacroCycle {
	my ($self, $widg, $line) = @_;
	my $begin = $widg->index("$line.0");
	my $end = $widg->index("$begin lineend");
	my $text = $widg->get($begin, $end);
	for ('dspace', 'dtab') {
		$widg->tagRemove($_, $begin, $end)
	}
	if ($text =~ /^([\s|\t]+)/) {
		my $spaces = $1;
		my $count = 0;
		while ($spaces ne '') {
			my $char = substr $spaces, 0, 1, '';
			my $next = $count + 1;
			$widg->tagAdd('dspace', "$begin + $count c", "$begin + $next c") if $char eq ' ';
			$widg->tagAdd('dtab', "$begin + $count c", "$begin + $next c") if $char eq "\t";
			$count ++
		}
	}
	if ($text =~ /(\s+)$/) {
		my $spaces = $1;
		my $l = length($spaces);
		$end = $widg->index("$end - $l c");
		my $count = 0;
		while ($spaces ne '') {
			my $char = substr $spaces, 0, 1, '';
			my $next = $count + 1;
			$widg->tagAdd('dspace', "$end + $count c", "$end + $next c") if $char eq ' ';
			$widg->tagAdd('dtab', "$end + $count c", "$end + $next c") if $char eq "\t";
			$count ++
		}
	}
	$widg->tagRaise('dspace');
	$widg->tagRaise('dtab');
}

sub spaceMacroRemove {
	my ($self, $doc) = @_;
	return unless defined $self->macroGet($doc, 'space');
	$self->macroRemove($doc, 'space');
	my $widg = $self->docGet($doc)->CWidg;
	for ('dspace', 'dtab') {
		$widg->tagRemove($_, '1.0', 'end')
	}
}


sub ToolItems {
	my $self = shift;
	my @items = $self->SUPER::ToolItems;
	return (@items,
	#	type					label			cmd					icon					help
	[	'tool_separator' ],
	[	'tool_button',		'Copy',		'<Control-c>',		'edit-copy',		'Copy selected text to clipboard'],
	[	'tool_button',		'Cut',		'<Control-x>',		'edit-cut',			'Move selected text to clipboard'],
	[	'tool_button',		'Paste',		'<Control-v>',		'edit-paste',		'Paste clipboard content into document'],
	[	'tool_separator' ],
	[	'tool_button',		'Undo',		'<Control-z>',		'edit-undo',		'Undo last action'],
	[	'tool_button',		'Redo',		'<Control-Z>',		'edit-redo',		'Cancel undo'],
	);
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<App::Codit::Macro>

=item L<Tk::AppWindow::Ext::MDI>

=back

=cut

1;
