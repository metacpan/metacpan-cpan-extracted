package App::Codit::CodeTextManager;

=head1 NAME

App::Codit::CodeTextManaer - Content manager for App::Codit

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require Tk::CodeText;

use base qw(Tk::Derived Tk::AppWindow::BaseClasses::ContentManager);
Construct Tk::Widget 'CodeTextManager';

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);
	my $text = $self->CodeText(
		-saveimage => $self->Extension->getArt('document-save', 16),
		-modifiedcall => ['Modified', $self],
		-scrollbars => 'osoe',
	)->pack(-expand => 1, -fill => 'both');
	$self->CWidg($text);
	my $xt = $text->Subwidget('XText');
	$self->{NAME} = '';

	$self->ConfigSpecs(
		-contentautoindent => [{-autoindent => $xt}],
		-contentbackground => [{-background => $xt}],
		-contentforeground => [{-foreground => $xt}],
		-contentfont => [{-font => $xt}],
		-contentindent => [{-indentstyle => $xt}],
		-contentposition => [{-position => $text}],
		-contentsyntax => [{-syntax => $text}],
		-contenttabs => [{-tabs => $xt}],
		-contentwrap => [{-wrap => $xt}],
#		-contentxml => [{-xmlfolder => $text}],
		-showfolds => [$text],
		-shownumbers => [$text],
		-showstatus => [$text],
		-highlight_themefile => [{ -themefile => $text}],
		DEFAULT => [$text],
	);
	$self->Delegates(
		DEFAULT => $text,
	);
}

# sub ConfigureCM {
# 	my $self = shift;
# 	my $ext = $self->Extension;
# 	my $cmopt = $ext->configGet('-contentmanageroptions');
# 	
# 	my @o = @$cmopt; #Hack preventing from the original being modified. No idea why this is needed.
# 	for (@o) {
# 		my $key = $_;
# # 		print "option $key\n";
# 		my $val = $ext->configGet($key);
# 		if ((defined $val) and ($val ne '')) {
# # 			print "configuring $key with value $val\n";
# 			$self->configure($key, $val) ;
# 		}
# 	}
# }


sub Close {
	my $self = shift;
	$self->doClear;
	return 1;
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






