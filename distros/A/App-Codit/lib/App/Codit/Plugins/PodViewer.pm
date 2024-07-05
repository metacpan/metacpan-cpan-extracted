package App::Codit::Plugins::PodViewer;

=head1 NAME

App::Codit::Plugins::PodViewer - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.07;

use base qw( App::Codit::BaseClasses::TextModPlugin );

require Tk::Pod::Text;
use Tk;

=head1 DESCRIPTION

Add a Perl pod viewer to your open files.

=head1 DETAILS

PodViewer adds a I<Pod> button to the toolbar. 
When you click it the frame of the current selected document 
will split and the bottom half will show the pod documentation
in your document.

The viewer is refreshed after you make an edit.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ToolBar');
	return undef unless defined $self;

	$self->{ACTIVEDELAY} = 300;
	$self->{ADJUSTER} = undef;
	$self->{DOCS} = {};
	$self->{MODIFIEDSAVE} = {};
	$self->{VIEWER} = undef;
	$self->{VISIBLE} = 0;
	$self->cmdConfig(
		flip_pod => ['FlipPod', $self],
	);
#	$self->cmdHookBefore('deferred_open', 'selectBlock', $self);
	$self->PodAdd;
	return $self;
}


sub _visible {
	my $self = shift;
	$self->{VISIBLE} = shift if @_;
	return $self->{VISIBLE}
}

sub docBefore {
	my $self = shift;
	my ($name ) = @_;
	if (defined $name) {
		$self->{DOCNAME} = $name;
	}
	return @_;
}

#sub docSelect {
#	my $self = shift;
#	if (exists $self->{'select_block'}) {
#		$self->after(100, sub { delete $self->{'select_block'} });
#		return;
#	}
#	$self->SUPER::docSelect;
#}

sub FlipPod {
	my $self = shift;
	my $view = $self->{VIEWER};
	my $adj = $self->{ADJUSTER};
	if ($self->_visible) {
		$self->_visible(0);
		$view->packForget;
		$adj->packForget;
	} else {
		$self->_visible(1);
		$self->Refresh;
		$view->pack(-side => 'bottom', -fill => 'both');
		$adj->pack(-before => $view, -fill => 'x');
	}
}

sub PodAdd {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	my $page = $self->Subwidget('WORK');
	my $art = $self->extGet('Art');

	my $podframe = $page->Frame;
	my $pod;

	my $bframe = $podframe->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(-fill => 'x');

	for (
		['Previous', 'go-previous', 'Previous document', sub { $pod->history_move(-1) }],
		['Next', 'go-next', 'Next document', sub { $pod->history_move }],
		['Zoom in', 'zoom-in', 'Zoom in', sub { $pod->zoom_in }],
		['Zoom out', 'zoom-out', 'Zoom out', sub { $pod->zoom_out }],
		['Reset zoom', 'zoom-original', 'Reset zoom', sub { $pod->zoom_normal }],
	) {
		my ($lab, $icon, $status, $sub) = @$_;
		my @opt = ();
		my $img = $self->getArt($icon, 22);
		if (defined $img) {
			push @opt, -image => $art->createCompound(
				-image => $img,
				-text => $lab,
			)
		} else {
			push @opt, -text => $lab
		}
		my $b = $bframe->Button(@opt,
			-relief => 'flat',
			-command => $sub,
		)->pack(-side => 'left', -padx => 2, -pady => 2);
		$self->StatusAttach($b, -statusmsg => $status);
	}

	$pod = $podframe->PodText(
		-file => $self->PodFile,
		-width => 20,
		-height => 10,
		-scrollbars => 'oe',
	)->pack(-expand => 1, -fill => 'both');

	my $adj = $page->Adjuster(
		-side => 'bottom',
		-widget => $podframe,
	);
	$self->{ADJUSTER} = $adj;
	$self->{PODWIDGET} = $pod;
	$self->{VIEWER} = $podframe;
}

sub PodFile {
	my $self = shift;
	my $podfile = $self->extGet('ConfigFolder')->configGet('-configfolder') . '/temppod.pod';
	unless (-e $podfile) {
		if (open FH, ">", $podfile) {
			print FH "\n";
			close FH;
		}
	}
	return $podfile
}

sub PodRemove {
	my $self = shift;
	my $adj = $self->{ADJUSTER};
	$adj->destroy if (defined $adj) and Exists($adj);
	my $podframe = $self->{VIEWER};
	$podframe->destroy if (defined $podframe) and Exists($podframe);
}

sub Refresh {
	my $self = shift;
	$self->SUPER::Refresh;

	return unless $self->_visible;

	my $widg = $self->docWidget;
	return unless defined $widg;

	my $file = $self->PodFile;
	$widg->saveExport($file);

	my $title = $self->configGet('-title');
	my $pod = $self->{PODWIDGET};
	$pod->reload;
	$self->configPut(-title => $title);
}

sub selectBlock {
	my $self = shift;
	$self->{'select_block'} = 1;
	return @_;
}

sub ToolItems {
	return (
		[	'tool_separator',],
		[	'tool_button',	'Pod',	'flip_pod',	'documentation',	'Add or remove pod viewer'],
	)
}

sub Quit {
	my $self = shift;
	unlink $self->PodFile;
}

sub Unload {
	my $self = shift;
#	$self->cmdUnhookBefore('deferred_open', 'selectBlock', $self);
	$self->PodRemove;
	$self->cmdRemove('flip_pod');
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









