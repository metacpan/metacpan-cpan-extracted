package App::Codit::Plugins::SplitView;

=head1 NAME

App::Codit::Plugins::SplitView - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = '0.19';

use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::Adjuster;
require Tk::YANoteBook;
require App::Codit::CodeTextManager;

=head1 DESCRIPTION

Create a secondary document interface for simultaneous reviewing.

=head1 DETAILS

This plugin creates a secondary document interface that holds all the
documents in the primary one in a readonly state. You can create
a horizontal or a vertical split through the View menu. Whenever
a document is opened or closed in the primary interface it is also
opened or closed in the secondary interface.

=head1 COMMANDS

=over 4

=item B<split_cancel>

Removes an existing split from view.

=item B<split_horizontal>

Creates a horizontal split.

=item B<split_vertical>

Creates a vertical split.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	$self->{ADJUSTER} = undef;
	$self->{DOCS} = {};
	$self->{SPLIT} = undef;
	$self->{STATE} = 'none';
	my $w = $self->WorkSpace;
	
	$self->cmdHookAfter('doc_close', 'splitClose', $self);
	$self->cmdHookAfter('doc_open', 'splitOpen', $self);

	$self->cmdConfig(
		split_cancel => ['splitCancel', $self],
		split_horizontal => ['splitHorizontal', $self],
		split_vertical => ['splitVertical', $self],
	);
	return $self;
}

sub MenuItems {
	my $self = shift;
	my $path = 'View::Show navigator panel';
	return (
#This table is best viewed with tabsize 3.
#			 type					 menupath			label	              cmd                icon
		[	'menu_normal', 	 $path,     'Split ~horizontal',		'split_horizontal',   'view-split-left-right'],
		[	'menu_normal', 	 $path,     'Split ~vertical',		  'split_vertical',     'view-split-top-bottom'],
		[	'menu_normal', 	 $path,     'Split ~cancel',		    'split_cancel', ],
		[	'menu_separator',$path,     's1'],
	)
}

sub split { return $_[0]->{SPLIT} }

sub splitCancel {
	my $self = shift;
	my $state = $self->{STATE};
	return if $self->{STATE} eq 'none';
	$self->splitRemove;
	$self->{STATE} = 'none';
}

sub splitClose {
	my ($self, $name) = @_;
	my $split = $self->{SPLIT};
	return unless defined $split;
	return if $name eq '';
	my $plit = $self->split;
	$split->deletePage($name);
}

sub splitGet {
	my $self = shift;
	my $split = $self->{SPLIT};
	unless (defined $split) {
		$split = 	$self->{INTERFACE} = $self->WorkSpace->YANoteBook(
			-image => $self->getArt('document-multiple', 16),
			-selecttabcall => ['splitSelect', $self ],
		);
		my $mdi = $self->mdi;
		my $interface = $self->mdi->Interface;
		my $disp = $interface->{DISPLAYED};
		my $undisp = $interface->{UNDISPLAYED};
		for (@$disp, @$undisp) {
			my ($t) = $mdi->docTitle($_);
			$split->addPage($_,
				-title => $t,
			);
		}
		$self->{SPLIT} = $split;
		my $sel = $mdi->docSelected;
		$split->selectPage($sel);
	}
	return $split
}

sub splitHorizontal {
	my $self = shift;
	$self->splitRemove;
	my $w = $self->WorkSpace;
	$w->gridColumnconfigure(2, -weight => 1);
	my $i = $self->mdi->Interface;
	
	my $a = $w->Adjuster(
		-widget => $i,
		-side => 'left'
	)->grid(-row => 0, -column => 1, -sticky => 'ns');
	$self->{ADJUSTER} = $a;

	my $s = $self->splitGet;
	$s->grid(-row => 0, -column => 2, -sticky => 'nsew');
	my $width = $w->width;
	$i->GeometryRequest(int(($width)/2), $w->height);

	$self->{STATE} = 'horizontal';
}

sub splitOpen {
	my ($self, $name) = @_;
	my $split = $self->{SPLIT};
	return unless defined $split;
	return if $name eq '';
	my $plit = $self->split;
	my ($t) = $self->mdi->docTitle($name);
	$split->addPage($name,
		-title => $t,
	);
}

sub splitRemove {
	my $self = shift;
	my $s = $self->{STATE};
	return if $self->{STATE} eq 'none';
	my $m = $self->{SPLIT};
	$m->gridForget;
	my $a = $self->{ADJUSTER};
	$a->gridForget;
	$a->destroy;
	my $w = $self->WorkSpace;
	$w->gridColumnconfigure(2, -weight => 0);
	$w->gridRowconfigure(2, -weight => 0);
	my $i = $self->mdi->Interface;
	$w->gridColumnconfigure(0, -weight => 1);
	$w->gridRowconfigure(0, -weight => 1);
	$i->grid(-column => 0, -row => 0, -sticky => 'nsew');
}

sub splitSelect {
	my ($self, $name) = @_;
	my $split = $self->split;
	my $mdi = $self->mdi;
	my $w;
	unless (exists $self->{DOCS}->{$name}) {
		my $page = $split->getPage($name);
		my $man = $page->CodeTextManager(
			-extension => $mdi,
		)->pack(-expand => 1, -fill => 'both');
		$w = $man->CWidg;
		$w->configure('-readonly', 1);
		$self->{DOCS}->{$name} = $w;
	} else {
		$w = $self->{DOCS}->{$name}
	}
	if ($mdi->deferredExists($name)) {
		$w->load($name);
	} else {
		my $d = $mdi->docGet($name);
		my $content = $d->get('1.0', 'end - 1c');
		$w->delete('1.0', 'end');
		$w->insert('end', $content);
		$w->ResetRedo;
		$w->ResetUndo;
		$w->editModified(0);
		$w->configure('-syntax', $d->CWidg->cget('-syntax'));
	}
}

sub splitVertical {
	my $self = shift;
	$self->splitRemove;
	my $w = $self->WorkSpace;
	$w->gridRowconfigure(2, -weight => 1);
	my $i = $self->mdi->Interface;
	
	my $a = $w->Adjuster(
		-widget => $i,
		-side => 'top'
	)->grid(-row => 1, -column => 0, -sticky => 'ew');
	$self->{ADJUSTER} = $a;

	my $s = $self->splitGet;
	$s->grid(-row => 2, -column => 0, -sticky => 'nsew');
	my $height = $w->height;
	$i->GeometryRequest($w->width, int(($height)/2));

	$self->{STATE} = 'vertical';
}


sub Unload {
	my $self = shift;
	
	#destroy the split window
	my $split = $self->split;
	$split->destroy if defined $split;

	#unhook commands
	$self->cmdUnhookAfter('doc_close', 'splitClose', $self);
	$self->cmdUnhookAfter('doc_open', 'splitOpen', $self);

	#unload commands
	for (qw/
		split_horizontal
		split_vertical
		split_cancel
	/) {
		$self->cmdRemove($_);
	}
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













