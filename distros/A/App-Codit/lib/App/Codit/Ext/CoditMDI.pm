package App::Codit::Ext::CoditMDI;

=head1 NAME

App::Codit::Ext::CoditMDI - Multiple Document Interface for App::Codit

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.05";

use base qw( Tk::AppWindow::Ext::MDI );

require Tk::AppWindow::PluginsForm;
require App::Codit::CoditTagsEditor;
require Tk::YADialog;


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

=item B<-doc_autoindent>

Sets and returns the autoindent option of the currently selected document.

=item B<-doc_wrap>

Sets and returns the autoindent option of the currently selected document.

=item B<-doc_view_folds>

Sets and returns the showfolds option of the currently selected document.

=item B<-doc_view_numbers>

Sets and returns the shownumbers option of the currently selected document.

=item B<-doc_view_status>

Sets and returns the showstatus option of the currently selected document.

=back

=head1 COMMANDS

=over 4

=item B<-doc_autoindent>

Sets and returns the autoindent option of the currently selected document.

=item B<-doc_find>

Pops up the search bar in the currently selected document.

=item B<-doc_replace>

Pops up the search and replace bar in the currently selected document.

=item B<-doc_wrap>

Sets and returns the wrap option of the currently selected document.

=item B<-edit_delete>, I<$begin>, I<$end>

Deletes text in the currently selected document. It takes two indices as parameters.

=item B<-edit_insert>, I<$index>, I<$text>

Inserts text in the currently selected document. It takes an index and the text parameters.

=item B<-modified>

Dummy command. It is called after every edit. It gets the document name and
location of the edit as parameters. It is only there so plugins can hook on to it.

=back

=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->configInit(
		-doc_autoindent => ['docAutoIndent', $self],
		-doc_wrap => ['docWrap', $self],
		-doc_view_folds => ['docViewFolds', $self],
		-doc_view_numbers => ['docViewNumbers', $self],
		-doc_view_status => ['docViewStatus', $self],
	);
	$self->cmdConfig(
		doc_autoindent => ['docAutoIndent', $self],
		doc_find => ['docPopFindReplace', $self, 1],
		doc_get_sel => ['docGetSel', $self],
		doc_get_text => ['docGetText', $self],
		doc_replace => ['docPopFindReplace', $self, 0],
		doc_wrap => ['docWrap', $self],
		edit_delete => ['editDelete', $self],
		edit_insert => ['editInsert', $self],
		modified => ['contentModified', $self],
	);
	return $self;
}

sub CmdDocClose {
	my $self = shift;
	my $result = $self->SUPER::CmdDocClose(@_);
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

sub CmdDocOpen {
	my $self = shift;
	my $result = $self->SUPER::CmdDocOpen(@_);
	$self->disposeUntitled if $result;
	return $result
}

sub contentModified {
	my $self = shift;
	return @_;
}

sub ContextMenu {
	my $self = shift;
	return $self->extGet('MenuBar')->menuContext($self->GetAppWindow,
     [ 'menu_normal',    undef,  '~Copy',  '     <Control-c>',	 'edit-copy',       '*CTRL+C'], 
     [ 'menu_normal',    undef,  'C~ut',        '<Control-x>',	 'edit-cut',        '*CTRL+X'], 
     [ 'menu_normal',    undef,  '~Paste',      '<Control-v>',	 'edit-paste',      '*CTRL+V'], 
     [ 'menu_separator', undef,  'c1'], 
     [ 'menu_normal',    undef,  '~Select all', '<Control-a>',  'edit-select-all', '*CTRL+A'], 
     [ 'menu_separator', undef,  'c2'], 
     [ 'menu_normal',    undef,  'Co~mment',    '<Control-g>',   undef,            '*CTRL+G'], 
     [ 'menu_normal',    undef,  '~Uncomment',  '<Control-G>',   undef,            '*CTRL+SHIFT+G'], 
     [ 'menu_separator', undef,  'c3' ], 
     [ 'menu_normal',    undef,  '~Indent',     '<Control-j>',   undef,            '*CTRL+J'], 
     [ 'menu_normal',    undef,  'Unin~dent',   '<Control-J>',   undef,            '*CTRL+SHIFT+J'], 
     [ 'menu_separator', undef,  'c4' ], 
     [ 'menu_check',     undef,  'A~uto indent', undef, '-doc_autoindent', undef, 0, 1], 
     [ 'menu_radio_s',   undef,  '~Wrap',  [qw/char word none/],  undef, '-doc_wrap'], 
 	)
}

sub CreateContentHandler {
	my ($self, $name) = @_;
	my $h = $self->SUPER::CreateContentHandler($name);
	$h->Name($name);
	return $h;
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
		print "configuring $sel\n";
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

sub docViewFolds {
	my $self = shift;
	return $self->docOption('-showfolds', @_);
}

sub docSelectFirst {
	my $self = shift;
	my $sel = $self->docSelected;
	unless (defined $sel) {
		my @list = $self->docFullList;
		$self->cmdExecute('doc_select', $list[0]) if @list;
	}
}

sub docViewNumbers {
	my $self = shift;
	return $self->docOption('-shownumbers', @_);
}

sub docViewStatus {
	my $self = shift;
	return $self->docOption('-showstatus', @_);
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

Inserts text in the currently selected document. It takes an index and the text parameters.

=cut

sub editInsert {
	my $self = shift;
	my $doc = $self->docSelected;
	return unless defined $doc;
	$self->docGet($doc)->insert(@_);
}

#sub HighlightConfigure {
#	my $self = shift;
#	my $dialog = $self->{DIALOG};
#	unless (defined $dialog) {
#		my ($first) = $self->docList;
#		my $doc = $self->docGet($first);
#		return () unless defined $doc;
#		my $themefile = $doc->cget('-highlight_themefile');
#		my $historyfile = $self->extGet('ConfigFolder')->ConfigFolder . '/color_history';
#		my @opt = (
#			-applycall => sub {
#				my $themefile = shift;
#				my @list = $self->docList;
#				for (@list) {
#					my $d = $self->docGet($_);
#					$d->configure(-highlight_themefile => $themefile);
#				}
#			},
#			-defaultbackground => $doc->cget('-contentbackground'),
#			-defaultforeground => $doc->cget('-contentforeground'),
#			-defaultfont => $doc->cget('-contentfont'),
#			-historyfile => $historyfile,
#			-themefile => $themefile,
#			-height => 20,
#			-width => 60,
#		);
#		$dialog = $self->YADialog(
#			-title => 'Configure highlighting',
#			-buttons => ['Close'],
#		);
#		$self->{DIALOG} = $dialog;
#		my $editor = $dialog->CoditTagsEditor(@opt)->pack(-expand => 1, -fill => 'both');
#		my $button = $dialog->Subwidget('buttonframe')->Button(
#			-text => 'Apply',
#			-command => ['Apply' => $editor],
#		);
#		$dialog->ButtonPack($button);
#	}
#
#	$dialog->Show(-popover => $self->GetAppWindow);
##	$dialog->destroy;
#}

sub MenuItems {
	my $self = shift;
	my @items = $self->SUPER::MenuItems;
	return (@items,
#      [	'menu_normal',		 'appname::h2',		    '~Highlighting',	     'highlighting',	         'configure',		    'SHIFT+F9',	], 
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
      [ 'menu_normal',    'Edit::',          '~Indent',            '<Control-j>',       undef,            '*CTRL+J'], 
      [ 'menu_normal',    'Edit::',          'Unin~dent',          '<Control-J>',       undef,            '*CTRL+SHIFT+J'], 
      [ 'menu_separator', 'Edit::',          'e4' ], 
      [ 'menu_normal',    'Edit::',          '~Select all',        '<Control-a>',       'edit-select-all','*CTRL+A'], 
      [ 'menu_separator', 'View::',          'v1' ],
      [ 'menu_check',     'View::',          'Show ~folds',          undef,   '-doc_view_folds', undef, 0, 1], 
      [ 'menu_check',     'View::',          'Show ~line numbers',   undef,   '-doc_view_numbers', undef, 0, 1], 
      [ 'menu_check',     'View::',          'Show ~document status',undef,   '-doc_view_status', undef, 0, 1], 
      [ 'menu',           undef,             '~Tools'],
      [ 'menu_normal',    'Tools::',         '~Find',              'doc_find',          'edit-find',      'CTRL+F',],
      [ 'menu_normal',    'Tools::',         '~Replace',	          'doc_replace',       'edit-find-replace','CTRL+R',],
      [ 'menu_separator', 'Tools::',          't1' ],
      [ 'menu_check',     'Tools::',          'A~uto indent',        undef,   '-doc_autoindent', undef, 0, 1], 
#       [ 'menu',           'Tools::',          '~Wrap'],
      [ 'menu_radio_s',   'Tools::',          '~Wrap',  [qw/char word none/],  undef, '-doc_wrap'], 
	);
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
			}
		},
		-defaultbackground => $doc->cget('-contentbackground'),
		-defaultforeground => $doc->cget('-contentforeground'),
		-defaultfont => $doc->cget('-contentfont'),
		-historyfile => $historyfile,
		-themefile => $themefile,
	);
	return (
		'Highlighting' => ['CoditTagsEditor', @opt]
	)
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

=item L<Tk::AppWindow::Ext::MDI>

=back

=cut

1;
