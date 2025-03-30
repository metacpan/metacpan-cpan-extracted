package App::Codit::Plugins::Icons;

=head1 NAME

App::Codit::Plugins::Icons - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = '0.19';

require Tk::ListBrowser;
use base qw( Tk::AppWindow::BaseClasses::PluginJobs );

=head1 DESCRIPTION

Easily select and insert icons.

=head1 DETAILS

The Icons plugin lets you choose an icon from the iconlibrary and insert it's name
into your document.

If a selection exists and it's content matches the name of an icon, the icon will
be selected.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	my $page = $self->ToolRightPageAdd('Icons', 'preferences-desktop-icons', undef, 'Select and insert icons', 350);
	
	my @padding = (-padx => 3, -pady => 3);

	my $list;
	#setting up the buttons
	my $eframe = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	$eframe->Button(
		-text => 'Insert',
		-command => sub {
			my ($sel) = $list->selectionGet;
			$self->cmdExecute('edit_insert', 'insert', $sel) if defined $sel;
		},
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');
	$eframe->Button(
		-text => 'Copy',
		-command => sub {
			my ($sel) = $list->selectionGet;
			if (defined $sel) {
				$self->clipboardClear;
				$self->clipboardAppend($sel);
			}
		},
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');

	my $current = '';
	my $l = $page->Label(
		-textvariable => \$current,
	)->pack(-fill => 'x', -pady => 2);
	$self->{INDICATOR} = \$current,

	$list = $page->ListBrowser(
		-arrange => 'row',
		-itemtype => 'imagetext',
		-wraplength => 70,
		-textside => 'bottom',
	)->pack(-expand => 1, -fill => 'both');
	my $art = $self->extGet('Art');
	my @icons = $art->AvailableIcons($self->cget('-icontheme'));
	for (@icons) {
		my $img = $art->getIcon($_, 48);
		next if $img->height > 48;
		my $text = $self->abbreviate($_, 30);
		$list->add($_,
			-image => $img,
			-text => $text,
		)
	}
	$list->refresh;
	$self->{LIST} = $list;
	$self->jobStart('selection_check', 'SelectionCheck', $self);
	$self->jobStart('list_check', 'ListCheck', $self);
	return $self;
}

sub ListCheck {
	my $self = shift;
	my $l = $self->{LIST};
	my $i = $self->{INDICATOR};
	my ($sel) = $l->selectionGet;
	if (defined $sel) {
		$$i = $sel
	} else {
		$$i = ''
	}
}

sub SelectionCheck {
	my $self = shift;
	my @sel = $self->cmdExecute('doc_get_sel');
	if (@sel) {
		my $text = $self->cmdExecute('doc_get_text', @sel);
		chomp($text);
		my $l = $self->{LIST};
		if ($l->infoExists($text)) {
			$l->selectionSet($text);
			$l->anchorSet($text);
			$l->see($text);
		}
	}
}

sub Unload {
	my $self = shift;
	$self->ToolRightPageRemove('Icons');
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

If you find any bugs, please report them here L<https://github.com/haje61/App-Codit/issues>.

=head1 SEE ALSO

=over 4

=back

=cut


1;




