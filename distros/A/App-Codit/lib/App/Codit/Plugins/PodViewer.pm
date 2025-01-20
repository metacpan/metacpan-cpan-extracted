package App::Codit::Plugins::PodViewer;

=head1 NAME

App::Codit::Plugins::PodViewer - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.16;

use base qw( App::Codit::BaseClasses::TextModPlugin );

require Tk::PodViewer::Full;
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
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;

	$self->{ADJUSTER} = undef;
	$self->{DOCS} = {};
	$self->{MODIFIEDSAVE} = {};
	$self->{VIEWER} = undef;
	$self->{VISIBLE} = 0;

	my $page = $self->ToolBottomPageAdd('Pod', 'documentation', undef, 'Show the documentation in your file');
	$self->sidebars->pageSelectCall('Pod', sub {
		$self->after(10, sub { $self->Refresh })
	});
	my $art = $self->extGet('Art');

	#Getting the correct font
	my $l = $page->Label;
	my $lfont = $l->cget('-font');
	my $family = $l->fontActual($lfont, '-family');
	my $size = $l->fontActual($lfont, '-size');
	my $font = $l->Font(-family => $family, -size => $size);
	$l->destroy;

	#creating the viewer widget
	my @vopt = ();
	for (
		['-nextimage', 'go-next', 'Next'],
		['-previmage', 'go-previous', 'Previous'],
		['-zoominimage', 'zoom-in', 'Zoom in'],
		['-zoomoutimage', 'zoom-out', 'Zoom out'],
		['-zoomresetimage', 'zoom-original', 'Zoom reset'],
	) {
		my ($opt, $icon, $text) = @$_;
		my $img = $art->getIcon($icon, 22);
		push @vopt, $opt, $art->createCompound(
			-image => $img,
			-text => $text,
		) if defined $img;
	}
	my $pod = $page->PodViewerFull(@vopt,
		-font => $font,
		-linkcolor => $self->configGet('-linkcolor'),
	)->pack(-expand => 1, -fill => 'both');
	my $sb = $self->sidebars;
	$sb->pageSelectCall('Pod', sub { $self->after(100, ['Refresh', $self]) });
	$self->{PODWIDGET} = $pod;

	return $self;
}


sub _visible {
	my $self = shift;
	return $self->{PODWIDGET}->ismapped;
}

sub docBefore {
	my $self = shift;
	my ($name ) = @_;
	if (defined $name) {
		$self->{DOCNAME} = $name;
	}
	return @_;
}

sub ReConfigure {
	my $self = shift;
	my $pod = $self->{PODWIDGET};
	$pod->configure(-linkcolor => $self->configGet('-linkcolor'));
	$pod->configureTags;
	return 1
}

sub Refresh {
	my $self = shift;
	$self->SUPER::Refresh;

	return unless $self->_visible;

	my $widg = $self->mdi->docWidget;
	return unless defined $widg;

	my $text = $widg->get('1.0', 'end -1c');
	my $pod = $self->{PODWIDGET};
	my $podtxt = $pod->Subwidget('txt');
	my ($v) = $podtxt->yview;
	$pod->load(\$text);
	$podtxt->yviewMoveto($v);
}

sub Unload {
	my $self = shift;
	$self->ToolBottomPageRemove('Pod');
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









