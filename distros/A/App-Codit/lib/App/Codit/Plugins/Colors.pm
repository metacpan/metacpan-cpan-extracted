package App::Codit::Plugins::Colors;

=head1 NAME

App::Codit::Plugins::Colors - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = '0.19';

require Tk::ColorPicker;
use Tie::Watch;

use base qw( Tk::AppWindow::BaseClasses::PluginJobs );

=head1 DESCRIPTION

Easily select and insert colors.

=head1 DETAILS

The Colors plugin lets you choose a color and insert it's hex value into your document.

You can select a color in RGB, CMY and HSV space. Whenever you select a color it is added to the Recent tab.

It allows you to specify color depths 4, 8, 12 and 16 bits per color.

You can pick a color from any place on the screen with the pick button. This does not work on Windows.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	my $page = $self->ToolRightPageAdd('Colors', 'fill-color', undef, 'Select and insert colors', 350);
	
	my @padding = (-padx => 3, -pady => 3);

	my $eframe = $page->Frame->pack(-fill => 'x');

	my $fframe = $eframe->Frame->pack(-side => 'left');

	my $picker;
	my $color = '';
	my $entry = $fframe->Entry(
		-textvariable => \$color,
	)->pack(@padding, -fill => 'x');
	$entry->bind('<Key>', [$self, 'updateEntry']);
	$self->{ENTRY} = $entry;

	my $bframe = $fframe->Frame->pack(-fill => 'x');

	$bframe->Button(
		-text => 'Insert',
		-command => sub {
			if ($picker->validate($color)) {
				$self->cmdExecute('edit_insert', 'insert', $color);
				$picker->historyAdd($picker->getHEX);
				$picker->historyUpdate;
			}
		},
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');

	$bframe->Button(
		-text => 'Copy',
		-command => sub {
			if ($picker->validate($color)) {
				$self->clipboardClear;
				$self->clipboardAppend($color);
				$picker->historyAdd($picker->getHEX);
				$picker->historyUpdate;
			}
		},
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');

	my $indicator = $eframe->Label(
		-width => 4,
		-relief => 'sunken',
		-borderwidth => 2,
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'both');
	$self->{INDICATOR} = $indicator;

	$picker = $page->ColorPicker(
		-depthselect => 1,
		-notationselect => 1,
		-historyfile => $self->extGet('ConfigFolder')->ConfigFolder . '/color_history',
		-updatecall => ['updatePicker', $self],
	)->pack(-padx => 2, -pady => 2, -expand => 1, -fill => 'both');
	$self->{PICKER} = $picker;
	$self->jobStart('selection_check', 'SelectionCheck', $self);
	return $self;
}

sub _ent {
	my ($self, $value) = @_;
	my $entry = $self->{ENTRY};
	if (defined $value) {
		$entry->delete('0', 'end');
		$entry->insert('end', $value);
	}
	return $entry
}

sub _ind {
	my ($self, $value) = @_;
	$self->{INDICATOR}->configure(-background => $self->_pick->convert($value)) if defined $value;
	return $self->{INDICATOR}
}

sub _pick {
	my ($self, $value) = @_;
	$self->{PICKER}->put($value) if defined $value;
	return $self->{PICKER}
}

sub SelectionCheck {
	my $self = shift;
	my @sel = $self->cmdExecute('doc_get_sel');
	my $pick = $self->_pick;
	if (@sel) {
		my $text = $self->cmdExecute('doc_get_text', @sel);
		chomp($text);
		if ($self->_pick->validate($text)) {
			$pick->put($text);
			$self->_ent($pick->notationCurrent);
			$self->updateEntry;
		}
	}
}

sub Unload {
	my $self = shift;
#	$self->extGet('ToolPanel')->deletePage('Colors');
	$self->ToolRightPageRemove('Colors');
	return $self->SUPER::Unload
}

sub updateEntry {
	my ($self, $value) = @_;
	$value = $self->_ent->get unless defined $value;
	my $pick = $self->_pick;
	if ($self->_pick->validate($value)) {
		$self->_ind($pick->getHEX);
		$self->_ent->configure(-foreground => $self->configGet('-foreground'));
		$self->_pick($value);
	} else {
		$self->_ind($self->configGet('-background'));
		$self->_ent->configure(-foreground => $self->configGet('-errorcolor'));
	}
}

sub updatePicker {
	my ($self, $value) = @_;
	$self->_ent($value);
	$self->_ind($self->_pick->getHEX);
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




