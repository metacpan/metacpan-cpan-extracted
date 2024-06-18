package App::Codit::SessionManager;

=head1 NAME

App::Codit::SessionManager - Session manager used by the Sessions plugin

=cut

use strict;
use warnings;
use Carp;
require Tk::YAMessage;
use File::Copy;
use vars qw($VERSION);
$VERSION="0.06";

use base qw(Tk::Derived Tk::YADialog);
Construct Tk::Widget 'SessionManager';


sub Populate {
	my ($self,$args) = @_;
	
	my $plug = delete $args->{'-plugin'};
	carp 'You must specify the -plugin option' unless defined $plug;

	$self->SUPER::Populate($args);

	my @padding = (-padx => 4, -pady => 4);

	my $art = $plug->extGet('Art');
	
	my @sessions = ();
	$self->{SESSIONS} = \@sessions;
	$self->{PLUGIN} = $plug;
	my $lb = $self->Scrolled('Listbox',
		-scrollbars => 'osoe',
		-listvariable => \@sessions,
		-selectmode => 'single',
	)->pack(-side => 'left', @padding, -fill => 'y',);
	$self->Advertise('Listbox', $lb);

	my $bf = $self->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(-side => 'left', -fill => 'y', @padding);

	$bf->Button(
		-image => $art->createCompound(
			-text => 'Open',
			-image => $art->getIcon('document-open', 22),
		),
		-anchor => 'w',
		-command => ['Open', $self],
	)->pack(@padding, -fill => 'x');
	$bf->Button(
		-image => $art->createCompound(
			-text => 'New session',
			-image => $art->getIcon('document-new', 22),
		),
		-anchor => 'w',
		-command => ['NewSession', $self],
	)->pack(@padding, -fill => 'x');
	$bf->Label(-text => ' ')->pack(@padding);
	$bf->Button(
		-image => $art->createCompound(
			-text => 'Duplicate',
			-image => $art->createEmptyImage(22),
		),
		-anchor => 'w',
		-command => ['Duplicate', $self],
	)->pack(@padding, -fill => 'x');
	$bf->Button(
		-image => $art->createCompound(
			-text => 'Rename',
			-image => $art->createEmptyImage(22),
		),
		-anchor => 'w',
		-command => ['Rename', $self],
	)->pack(@padding, -fill => 'x');
	$bf->Label(-text => ' ')->pack(@padding);
	$bf->Button(
		-image => $art->createCompound(
			-text => 'Delete',
			-image => $art->getIcon('edit-delete', 22),
		),
		-anchor => 'w',
		-command => ['Delete', $self],
	)->pack(@padding, -fill => 'x');

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => [$self],
	);
	$self->Refresh;
}

sub Delete {
	my $self = shift;
	my $sel = $self->GetSelected;
	return unless defined $sel;
	my $plug = $self->{PLUGIN};
	return if $sel eq $plug->sessionCurrent;

	my $q = $self->YAMessage(
		-title => 'Deleting session',
		-image => $plug->getArt('dialog-warning', 32),
		-buttons => [qw(Yes No)],
		-text => "Deleting $sel.\nAre you sure?",
		-defaultbutton => 'No',
	);

	my $answer = $q->Show(-popover => $self);
	if ($answer eq 'Yes') {
		$plug->sessionDelete($sel);
		$self->Refresh;
	}
}

sub Duplicate {
	my $self = shift;
	my ($sel) = $self->GetSelected;
	return unless defined $sel;
	my $name = $self->NameDialog("Enter duplicate name:");
	my $plug = $self->{PLUGIN};
	return unless defined $name;
	return if $plug->sessionExists($name);
	my $f = $plug->sessionFolder;
	copy("$f/$sel", "$f/$name");
	$self->Refresh;
}

sub GetSelected {
	my $self = shift;
	my ($sel) = $self->Subwidget('Listbox')->curselection;
	return unless defined $sel;
	return $self->{SESSIONS}->[$sel]
}

sub NameDialog {
	my ($self, $text) = @_;
	return $self->{PLUGIN}->popEntry('Session name', $text);
}

sub NewSession {
	my $self = shift;
	$self->{PLUGIN}->sessionNew;
	$self->Pressed('Close');
}

sub Open {
	my $self = shift;
	my $sel = $self->GetSelected;
	my $plug = $self->{PLUGIN};
	return unless defined $sel;
	return if $sel eq $plug->sessionCurrent;
	$plug->sessionOpen($sel);
	$self->Pressed('Close');
}

sub Refresh {
	my $self = shift;
	my $sessions = $self->{SESSIONS};
	while (@$sessions) { pop @$sessions }
	my @list = $self->{PLUGIN}->sessionList;
	for (@list) { push @$sessions, $_ }
}

sub Rename {
	my $self = shift;
	my ($sel) = $self->GetSelected;
	return unless defined $sel;
	my $name = $self->NameDialog("Rename session to:");
	return unless defined $name;
	my $plug = $self->{PLUGIN};
	return if $plug->sessionExists($name);
	my $f = $plug->sessionFolder;
	move("$f/$sel", "$f/$name");
	$self->Refresh;
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
