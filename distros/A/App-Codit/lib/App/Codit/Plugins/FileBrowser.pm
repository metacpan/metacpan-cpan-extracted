package App::Codit::Plugins::FileBrowser;

=head1 NAME

App::Codit::Plugins::FileBrowser - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.13;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::FileManager;

=head1 DESCRIPTION

Browse your file system.

=head1 DETAILS

The FileBrowser plugin lets you browse your harddrive and open multiple
documents at once through its context menu (left-click).

All columns are sortable and sizable. If you left-click the header
it will give you options to display hidden files (that start with a '.'), Sort case dependant or not and directories first.

Pressing CTRL+F when the file browser has the focus invokes a filter entry at the bottom.

=cut

my @contextmenu = (
	[ 'menu_normal', undef, 'Open', 'fb_open',	'document-open', 'CTRL+SHIFT+I'], 
	[ 'menu_separator', undef, 'f1'],
	[ 'menu_normal', undef, 'Copy', 'fb_copy',	'edit-copy', '*CTRL+C'], 
	[ 'menu_normal', undef, 'Cut', 'fb_cut',	'edit-cut', '*CTRL+X'], 
	[ 'menu_normal', undef, 'Paste', 'fb_paste',	'edit-paste', '*CTRL+V'], 
	[ 'menu_separator', undef, 'f2'],
	[ 'menu_normal', undef, 'Delete', 'fb_delete',	'edit-delete', '*SHIFT+DELETE'], 
);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;


	my $page = $self->ToolNavigPageAdd('FileBrowser', 'folder', undef, 'Browse your file system', 400);
	my @images = (
		['-msgimage', 'dialog-information', 32],
		['-newfolderimage', 'folder-new', 16],
		['-reloadimage', 'appointment-recurring', 16],
		['-warnimage', 'dialog-warning', 32],
	);
	my @op = ();
	for (@images) {
		my ($opt, $icon, $size) = @$_;
		my $img = $self->getArt($icon, $size);
		push @op, $opt, $img if defined $img;
	}

	my $b = $page->FileManager(@op,
		-invokefile => ['fbInvoke', $self],
		-listmenu => $self->extGet('MenuBar')->menuStack(@contextmenu),
		-diriconcall => ['getDirIcon', $self],
		-fileiconcall => ['getFileIcon', $self],
		-linkiconcall => ['getLinkIcon', $self],
		-selectmode => 'extended',
	)->pack(-expand => 1, -fill => 'both');
	$self->cmdConfig(
		'fb_copy' => ['clipboardCopy', $b],
		'fb_cut' => ['clipboardCut', $b],
		'fb_delete' => ['delete', $b],
		'fb_open' => ['fbOpen', $self],
		'fb_paste' => ['clipboardPaste', $b],
	);
	$self->after(1000, ['load', $b]);
	$self->{BROWSER} = $b;
	
	return $self;
}

sub browser { return $_[0]->{BROWSER} }

sub fbInvoke {
	my ($self, $file) = @_;
	if (-T $file) {
		$self->cmdExecute('doc_open', $file);
	} else {
		$self->openURL($file)
	}
}

sub fbOpen {
	my $self = shift;
	my $b = $self->browser;
	my $mdi = $self->extGet('CoditMDI');
	$mdi->silentMode(1);
	my @sel = $b->infoSelection;
	for (@sel) {
		my $d = $b->infoData($_);
		$b->Invoke($_) unless $d->isDir;
	}
	$mdi->silentMode(0);
	$mdi->docSelectFirst;
}

sub Unload {
	my $self = shift;
	$self->cmdRemove('fb_copy');
	$self->cmdRemove('fb_cut');
	$self->cmdRemove('fb_delete');
	$self->cmdRemove('fb_open');
	$self->cmdRemove('fb_paste');
	$self->ToolNavigPageRemove('FileBrowser');
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











