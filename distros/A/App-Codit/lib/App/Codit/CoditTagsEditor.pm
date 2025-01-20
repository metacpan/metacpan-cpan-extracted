package App::Codit::CoditTagsEditor;

=head1 NAME

App::Codit::CoditTagsEditor - Tags editor for the syntax highlight tags of Tk::CodeText

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.14";
use Tk;
use Tie::Watch;
require Tk::CodeText::TagsEditor;

use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'CoditTagsEditor';

sub Populate {
	my ($self,$args) = @_;
	
	my $dbackground = delete $args->{'-defaultbackground'};
	die 'You must specify the -defaultbackground option' unless defined $dbackground;
	my $dforeground = delete $args->{'-defaultforeground'};
	die 'You must specify the -defaultforeground option' unless defined $dforeground;
	my $dfont = delete $args->{'-defaultfont'};
	die 'You must specify the -defaultfont option' unless defined $dfont;
	my $ext = delete	$args->{'-extension'};
	die 'You must specify the -extension option' unless defined $ext;
	my $hist = delete	$args->{'-historyfile'};
	die 'You must specify the -historyfile option' unless defined $hist;
	my $themefile = delete $args->{'-themefile'};
	die 'You must specify the -themefile option' unless defined $themefile;
	
	$self->SUPER::Populate($args);
	my $te = $self->TagsEditor(
		-defaultbackground => $dbackground,
		-defaultforeground => $dforeground,
		-defaultfont => $dfont,
		-historyfile => $hist,
	)->pack(-expand => 1, -fill => 'both');
	$self->Advertise(TE => $te);

	my $toolframe =  $self->Frame(
	)->pack(-fill => 'x');
	$toolframe->Button(
		-command => sub {
			my ($file) = $ext->pickFileSave(
				-loadfilter => '.ctt',
			);
			$te->save($file) if defined $file;
		},
		-text => 'Save',
	)->pack(-side => 'left', -padx => 5, -pady => 5);
	$toolframe->Button(
		-text => 'Load',
		-command => sub {
			my ($file) = $ext->pickFileOpen(
				-loadfilter => '.ctt',
			);
			if (defined $file) {
				my $obj = Tk::CodeText::Theme->new;
				$obj->load($file);
				$te->put($obj->get);
				$te->updateAll
			}
		},
	)->pack(-side => 'left', -padx => 5, -pady => 5);

	$self->{THEMEFILE} = $themefile;

	$self->ConfigSpecs(
		-applycall => ['CALLBACK', undef, undef, sub {}],
		DEFAULT => [$te],
	);

	$self->after(50, sub {
		my $theme = Tk::CodeText::Theme->new;
		$theme->load($themefile);
		$te->put($theme->get)
	});
}

sub Apply {
	my $self = shift;
	my $te = $self->Subwidget('TE');
	my $themefile = $self->{THEMEFILE};
	$te->save($themefile);
	$self->Callback('-applycall', $themefile);
}

1;





