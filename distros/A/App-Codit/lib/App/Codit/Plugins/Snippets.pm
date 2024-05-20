package App::Codit::Plugins::Snippets;

=head1 NAME

App::Codit::Plugins::Snippets - plugin for App::Codit

=cut

use strict;
use warnings;
use Carp;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::HList;
require Tk::XText;
use File::Path qw(make_path);

=head1 DESCRIPTION

Quick and easy code samples.

=head1 DETAILS

Snippets are shorts pieces of code that you find yourself writing over and over again.
The top side of the panel allows you to manage your collection of snippets.
The bottom side allows you to insert a selected snippet into your document,
copy the snippet to the clipboard or create a new document based on the snippet.
A file dialog is launched and the snippet is saved to the selected file name.
Then it is opened in a new tab.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ToolPanel');
	return undef unless defined $self;
	
	$self->{CURRENT} = undef;
	my $tp = $self->extGet('ToolPanel');
	my $page = $tp->addPage('Snippets', 'insert-text', undef, 'Snippets');

	my @padding = (-padx => 2, -pady => 2);

	my $lf = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(@padding, -fill => 'x');
	
	$lf->Button(
		-text => 'New',
		-command => ['snippetNew', $self],
	)->pack(@padding, -fill => 'x');
	$lf->Button(
		-text => 'Copy to',
		-command => ['snippetCopy', $self],
	)->pack(@padding, -fill=> 'x');
	$lf->Button(
		-text => 'Delete',
		-command => ['snippetDelete', $self],
	)->pack(@padding, -fill => 'x');
	my $hlist = $lf->Scrolled('HList',
		-browsecmd => ['listSelect', $self],
		-height => 4,
		-scrollbars => 'osoe',
	)->pack(@padding, -expand => 1, -fill => 'both');
	$self->{LIST} = $hlist;

	$page->Adjuster(
		-side => 'top',
		-widget => $lf,
	)->pack(-fill => 'x');
	
	my $sf = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(@padding, -expand => 1, -fill => 'both');
	$sf->Button(
		-text => 'Insert',
		-command => ['snippetInsert', $self],
	)->pack(@padding, -fill => 'x');
	$sf->Button(
		-text => 'Clipboard',
		-command => ['snippetClipboard', $self],
	)->pack(@padding, -fill => 'x');
	$sf->Button(
		-text => 'Create',
		-command => ['snippetCreate', $self],
	)->pack(@padding, -fill => 'x');
	my $text = $sf->Scrolled('XText',
		-font => $self->configGet('-contentfont'),
		-scrollbars => 'osoe',
		-tabs => '8m',
		-wrap => 'none',
		-width => 20,
	)->pack(@padding, -expand => 1, -fill => 'both');
	$self->{TEXT} = $text;

	$self->listRefresh;
	return $self;
}

sub _current {
	my $self = shift;
	$self->{CURRENT} = shift if @_;
	return $self->{CURRENT}
}

sub _list {
	return $_[0]->{LIST}
}

sub _text {
	return $_[0]->{TEXT}
}

sub listSelect {
	my ($self, $item) = @_;
	croak "Item not defined" unless defined $item;
	my $cur = $self->_current;
	$self->snippetSave if defined $cur;
	$self->_current($item);
	$self->snippetLoad;
}

sub listRefresh {
	my $self = shift;
	my $folder = $self->snippetsFolder;
	my $dh;
	unless (opendir($dh, $folder)) {
		croak "cannot open folder $folder";
		return
	}
	my $l = $self->_list;
	$l->deleteAll;
	$self->snippetSave;
	$self->_current(undef);
	$self->_text->clear;
	while (my $i = readdir($dh)) {
		next if $i eq '.';
		next if $i eq '..';
		$self->snippetAdd($i);
	}
	closedir($dh)
}

sub snippetAdd {
	my ($self, $item) = @_;
	croak "Item not defined" unless defined $item;
	my $l = $self->_list;
	my @op = ();
	my @peers = $l->infoChildren('');
	for (@peers) {
		if ($item lt $_) {
			@op = (-before, $_);
			last;
		}
	}
	$l->add($item, -text => $item, @op);
}

sub snippetClipboard {
	my $self = shift;
	my $cur = $self->_current;
	return unless defined $cur;
	my $text = $self->snippetGet;
	$self->clipboardClear;
	$self->clipboardAppend($text);
}

sub snippetCopy {
	my $self = shift;
	my $sel = $self->_current;
	return unless defined $sel;
	my $text = $self->snippetGet;
	my $new = $self->snippetDialog;
	if (defined $new) {
		$self->snippetAdd($new);
		$self->listSelect($new);
		$self->_text->insert('end', $text);                                                                                                                                                                                                                                                                                                                                                                                                                                                    
	}
}

sub snippetCreate {
	my $self = shift;
	my $list = $self->_list;
	my ($sel) = $list->infoSelection;
	return unless defined $sel;
	my $file = $self->getSaveFile;
	if (defined $file) {
		my $dh;
		unless (open($dh, ">", $file)) {
			croak "cannot open $file";
			return
		}
		print $dh $self->snippetGet;
		close $dh;
		$self->cmdExecute('doc_open', $file);
	}
}

sub snippetDelete {
	my $self = shift;
	my $list = $self->_list;
	my ($sel) = $list->infoSelection;
	return unless defined $sel;
	my $file = $self->snippetsFolder . "/$sel";
	my $button = $self->popDialog(
		'Deleting snippet', 
		"Deleting snippet '$sel'\nAre you sure?",
		'dialog-warning',
		'Ok', 'Cancel'
	);
	if ($button eq 'Ok') {
		$self->_current(undef);
		unlink $file;
		$self->listRefresh;
	}
}

sub snippetDialog {
	my ($self, $value) = @_;
	$value = '' unless defined $value;
	return $self->popEntry('New snippet', 'Please enter a snippet name', $value, 'dialog-information')
}

sub snippetGet {
	my $self = shift;
	my $text = $self->_text;
	return $text->get('1.0', 'end -1c')
}

sub snippetInsert {
	my $self = shift;
	my $cur = $self->_current;
	return unless defined $cur;
	$self->cmdExecute('edit_insert', 'insert', $self->snippetGet);
}

sub snippetLoad {
	my ($self, $item) = @_;
	$item = $self->_current unless defined $item;
	return unless defined $item;
	my $txt = $self->_text;
	$txt->clear;
	my $file = $self->snippetsFolder . "/$item";
	$txt->load($file) if -e $file;
}

sub snippetNew {
	my $self = shift;
	my $item = $self->snippetDialog;
	return if $self->_list->infoExists($item);
	$self->snippetAdd($item) if defined $item;
}

sub snippetSave {
	my ($self, $item) = @_;
	$item = $self->_current unless defined $item;
	return unless defined $item;
	my $txt = $self->_text;
	$txt->save($self->snippetsFolder . "/$item")
}

sub snippetsFolder {
	my $self = shift;
	my $config = $self->extGet('ConfigFolder')->ConfigFolder . '/Snippets';
	make_path($config) unless -e $config;
	return $config
}

sub Unload {
	my $self = shift;
	$self->snippetSave;
	$self->extGet('ToolPanel')->deletePage('Snippets');
	return 1
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






