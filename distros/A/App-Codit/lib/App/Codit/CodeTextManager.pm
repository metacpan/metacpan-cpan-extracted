package App::Codit::CodeTextManager;

=head1 NAME

App::Codit::CodeTextManaer - Content manager for App::Codit

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION='0.17';
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
		-keyreleasecall => ['KeyReleased', $self],
		-logcall => ['log', $self],
		-modifiedcall => ['Modified', $self],
		-saveimage => $ext->getArt('document-save', 16),
		-scrollbars => 'osoe',
		-width => 8,
	)->pack(-expand => 1, -fill => 'both');
	$self->CWidg($text);
	my $xt = $text->Subwidget('XText');
	$xt->bind('<Control-f>', sub { $ext->cmdExecute('doc_find') });
	$xt->bind('<Control-r>', sub { $ext->cmdExecute('doc_replace') });
	$self->{NAME} = '';

	$self->ConfigSpecs(
		-contentacpopsize => [{-acpopsize => $xt}],
		-contentacscansize => [{-acscansize => $xt}],
		-contentactivedelay => [{-activedelay => $xt}],
		-contentautocomplete => [{-autocomplete => $xt}],
		-contentautoindent => [{-autoindent => $xt}],
		-contentbackground => [{-background => $xt}],
		-contentbgdspace => [{-spacebackground => $text}],
		-contentbgdtab => [{-tabbackground => $text}],
		-contentbookmarkcolor => [{-bookmarkcolor => $text}],
		-contentfindbg => ['PASSIVE'],
		-contentfindfg => ['PASSIVE'],
		-contentmatchbg => ['PASSIVE'],
		-contentmatchfg => ['PASSIVE'],
		-contentforeground => [{-foreground => $xt}],
#		-contentfont => [{-font => $xt}],
		-contentfontfamily => ['PASSIVE'],
		-contentfontsize => ['PASSIVE'],
		-contentindent => [{-indentstyle => $xt}],
		-contentposition => [{-position => $text}],
		-contentshowspaces => [{-showspaces => $text}],
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

	#configuring the find options
	my @findoptions = ();
	my $fbg = $self->cget('-contentfindbg');
	push @findoptions, '-background', $fbg if (defined $fbg) and ($fbg ne '');
	my $ffg = $self->cget('-contentfindfg');
	push @findoptions, '-foreground', $ffg if (defined $ffg) and ($ffg ne '');
	$widg->configure('-findoptions', \@findoptions) if @findoptions;
	
	#configuring the match options
	my @matchoptions = ();
	my $mbg = $self->cget('-contentmatchbg');
	push @matchoptions, '-background', $mbg if  (defined $mbg) and ($mbg ne '');
	my $mfg = $self->cget('-contentmatchfg');
	push @matchoptions, '-foreground', $mfg if  (defined $mfg) and ($mfg ne '');;
	$widg->configure('-matchoptions', \@matchoptions) if @matchoptions;
	
	#configuring insert background
	$widg->configure('-insertbackground', $widg->cget('-foreground'));
	
	#configuring font
	my $xt = $widg->Subwidget('XText');
	my $fam = $self->cget('-contentfontfamily');
	$fam = 'Courier' unless defined $fam;
	my $siz = $self->cget('-contentfontsize');
	$siz = 10 unless defined $siz;
	$widg->configure(-font => "{$fam} $siz");
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

sub KeyReleased {
	my ($self, $key) = @_;
	$self->Extension->cmdExecute('key_released', $self->Name, $key);
	$self->CWidg->Subwidget('XText')->matchCheck;
}

sub log {
	my ($self, $message, $type) = @_;
	$type = 'message' unless defined $type;
	my $ext = $self->Extension;
	if ($type eq 'message') {
		$ext->log($message)
	} elsif ($type eq 'error') {
		$ext->logError($message)
	} elsif ($type eq 'warning') {
		$ext->logWarning($message)
	}
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






