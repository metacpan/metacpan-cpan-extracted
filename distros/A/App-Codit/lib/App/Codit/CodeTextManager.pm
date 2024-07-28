package App::Codit::CodeTextManager;

=head1 NAME

App::Codit::CodeTextManaer - Content manager for App::Codit

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.09";
use Tk;
require Tk::CodeText;

use base qw(Tk::Derived Tk::AppWindow::BaseClasses::ContentManager);
Construct Tk::Widget 'CodeTextManager';

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);
	my $ext = $self->Extension;
	
	my $text = $self->CodeText(
		-contextmenu => $ext->ContextMenu,
		-height => 8,
		-logcall => ['log', $ext],
		-modifiedcall => ['Modified', $self],
		-saveimage => $ext->getArt('document-save', 16),
		-scrollbars => 'osoe',
		-width => 8,
	)->pack(-expand => 1, -fill => 'both');
	$self->CWidg($text);
	my $xt = $text->Subwidget('XText');
	$self->{NAME} = '';

	$self->ConfigSpecs(
		-contentautoindent => [{-autoindent => $xt}],
		-contentbackground => [{-background => $xt}],
		-contentbgdspace => ['PASSIVE', undef, undef, '#E600A8'],
		-contentbgdtab => ['PASSIVE', undef, undef, '#B5C200'],
		-contentinsertbg => ['PASSIVE', undef, undef, '#000000'],
		-contentmatchbg => ['PASSIVE', undef, undef, '#0000FF'],
		-contentmatchfg => ['PASSIVE', undef, undef, '#FFFF00'],
		-contentforeground => [{-foreground => $xt}],
		-contentfont => [{-font => $xt}],
		-contentindent => [{-indentstyle => $xt}],
		-contentposition => [{-position => $text}],
		-contentsyntax => [{-syntax => $text}],
		-contenttabs => [{-tabs => $xt}],
		-contentwrap => [{-wrap => $xt}],
		-showfolds => [$text],
		-shownumbers => [$text],
		-showstatus => [$text],
		-highlight_themefile => [{ -themefile => $text}],
		DEFAULT => [$text],
	);
	$self->Delegates(
		DEFAULT => $text,
	);
	$self->after(10, ['configureTags', $self]);
}

#sub ConfigureCM {
#	my $self = shift;
#	my $ext = $self->Extension;
#	my $cmopt = $ext->configGet('-contentmanageroptions');
#	
#	my @matchoptions = ();
#	my @o = @$cmopt; #Hack preventing from the original being modified. No idea why this is needed.
#	for (@o) {
#		my $key = $_;
#		my $val = $ext->configGet($key);
#		if ((defined $val) and ($val ne '')) {
#			if ($key =~ /^\-contentmatch/) {
#				push @matchoptions, $key, $val
#			} else {
#				$self->configure($key, $val);
#			}
#		}
#	}
#	$self->CWidg->configure('-matchoptions', \@matchoptions) if @matchoptions;
#}

sub Close {
	my $self = shift;
	$self->doClear;
	return 1;
}

sub configureTags {
	my $self = shift;
	my $widg = $self->CWidg;

	#configuring space and tabs indicators
	for ('dtab', 'dspace') {
		my $bgopt = $self->cget("-contentbg$_");
		$widg->tagConfigure($_,
			-background => $bgopt,
		);
	}

	#configuring the match options
	my @matchoptions = ();
	my $bg = $self->cget('-contentmatchbg');
	push @matchoptions, '-background', $bg if defined $bg;
	my $fg = $self->cget('-contentmatchfg');
	push @matchoptions, '-foreground', $fg if defined $fg;
	$widg->configure('-matchoptions', \@matchoptions) if @matchoptions;
	
	#configuring insert background
	my $ib = $self->cget('-contentinsertbg');
	$widg->configure('-insertbackground', $ib) if defined $ib;
}

sub doClear {
	$_[0]->CWidg->clear
}

sub doExport {
	my ($self, $file) = @_;
	return $self->CWidg->exportSave($file);
}

sub doLoad {
	my ($self, $file) = @_;
	$self->Name($file);
	return $self->CWidg->load($file);
}

sub doSave {
	my ($self, $file) = @_;
	$self->Name($file);
	return $self->CWidg->save($file);
}

sub doSelect {
	$_[0]->CWidg->focus
}

sub Modified {
	my ($self, $index) = @_;
	$self->Extension->cmdExecute('modified', $self->Name, $index);
}

sub Name {
	my $self = shift;
	$self->{NAME} = shift if @_;
	return $self->{NAME}
}

sub IsModified {
	return $_[0]->CWidg->Subwidget('XText')->editModified;	
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






