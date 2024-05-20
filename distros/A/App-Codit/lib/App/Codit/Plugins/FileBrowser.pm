package App::Codit::Plugins::FileBrowser;

=head1 NAME

App::Codit::Plugins::FileBrowser - plugin for App::Codit

=cut

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::FileBrowser;

=head1 DESCRIPTION

Browse your file system.

=head1 DETAILS

The FileBrowser plugin lets you browse your harddrive and open multiple
documents at once through its context menu (left-click).

All columns are sortable and sizable. If you left-click the header
it will give you options to display hidden files (that start with a ‘.’), Sort case dependant or not and directories first.

Pressing CTRL+F when the file browser has the focus invokes a filter entry at the bottom.

=cut

my @contextmenu = (
	[ 'menu_normal', undef, 'Open', 'fb_open',	'document-open', 'CTRL+SHIFT+I'], 
);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'NavigatorPanel');
	return undef unless defined $self;

	$self->cmdConfig('fb_open', ['OpenSelection', $self]);
	my $tp = $self->extGet('NavigatorPanel');
	my $page = $tp->addPage('FileBrowser', 'folder', undef, 'Browse your file system');
	my $b = $page->FileBrowser(
		-invokefile => ['cmdExecute', $self, 'doc_open'],
		-listmenu => $self->extGet('MenuBar')->MenuStack(@contextmenu),
		-diriconcall => ['GetDirIcon', $self],
		-fileiconcall => ['GetFileIcon', $self],
		-reloadimage => $self->getArt('appointment-recurring'),
		-selectmode => 'extended',
	)->pack(-expand => 1, -fill => 'both');
	$b->load;
	$self->{BROWSER} = $b;
	
	return $self;
}

sub GetDirIcon {
	my ($self, $name) = @_;
	my $icon = $self->getArt('folder');
	return $icon if defined $icon;
	return $self->{BROWSER}->DefaultDirIcon;
}

sub GetFileIcon {
	my ($self, $name) = @_;
	my $icon = $self->getArt('text-x-plain');
	return $icon if defined $icon;
	return $self->{BROWSER}->DefaultFileIcon;
}

sub OpenSelection {
	my $self = shift;
	my $b = $self->{BROWSER};
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
	$self->cmdRemove('fb_open');
	$self->extGet('NavigatorPanel')->deletePage('FileBrowser');
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











