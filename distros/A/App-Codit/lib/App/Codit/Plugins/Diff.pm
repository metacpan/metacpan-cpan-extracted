package App::Codit::Plugins::Diff;

=head1 NAME

App::Codit::Plugins::Diff - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = '0.21';

use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::CodeText;
use Text::Diff;
use Tk;

=head1 DESCRIPTION

Generate a diff between your document and a file.

=head1 DETAILS

This plugin shows you the differences between your document and a file in diff format.
You can select a diff from your document to the file or form the file to your document.
You can also select several display styles.
The diff can be exported to a diff file.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;

	my $page = $self->ToolRightPageAdd('Diff', 'diff', undef, 'Perform a difff on your document against a file');


	my @padding = (-padx => 2, -pady => 2);

	my $sm = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(-padx => 2, -fill => 'x');

	my $ff = $sm->Frame->pack(@padding, -fill => 'x');
	my $fe = $ff->Entry->pack(-side => 'left', -expand => 1, -fill => 'x');
	$self->{FILEENTRY} = $fe;
	$ff->Button(
		-relief => 'flat',
		-command => sub {
			my ($file) = $self->pickFileOpen;
			if (defined $file) {
				$fe->delete(0, 'end');
				$fe->insert(0, $file);
			}
		},
		-image => $self->getArt('document-open', 16),
	)->pack(-side => 'right');


	#mode selection
	my $mf = $sm->Frame->pack(-fill =>'x');
	$mf->Label(
		-anchor =>'e',
		-width => 7,
		-text => 'Mode:',
	)->pack(-side => 'left');
	my $mode = 'File to document';
	$self->{MODE} = \$mode;
	my $mb = $mf->Menubutton(
		-anchor => 'w',
		-textvariable => \$mode,
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');
	my @menu = ();
	for ('File to document', 'Document to file') {
		my $operation = $_;
		push @menu, [command => $operation,
			-command => sub { $mode = $operation },
		];
	}
	$mb->configure(-menu => $mb->Menu(
		-menuitems => \@menu,
	));

	#style selection
	my $sf = $sm->Frame->pack(-fill =>'x');
	$sf->Label(
		-anchor =>'e',
		-width => 7,
		-text => 'Style:',
	)->pack(-side => 'left');
	my $style = 'Unified';
	$self->{STYLE} = \$style;
	my $sb = $sf->Menubutton(
		-anchor => 'w',
		-textvariable => \$style,
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');
	my @smenu = ();
	for ('Unified', 'Context', 'OldStyle') {
		my $operation = $_;
		push @smenu, [command => $operation,
			-command => sub { $style = $operation },
		];
	}
	$sb->configure(-menu => $sb->Menu(
		-menuitems => \@smenu,
	));



	my $sa = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(@padding, -expand => 1, -fill => 'both');
	$sa->Button(
		-text => 'Diff',
		-command => ['Diff', $self],
	)->pack(@padding, -fill => 'x');
	$sa->Button(
		-text => 'Clear',
		-command => ['Clear', $self],
	)->pack(@padding, -fill => 'x');
	$sa->Button(
		-text => 'Export',
		-command => ['Export', $self],
	)->pack(@padding, -fill => 'x');

	my $fam = $self->configGet('-contentfontfamily');
	$fam = 'Courier' unless defined $fam;
	my $siz = $self->configGet('-contentfontsize');
	$siz = 10 unless defined $siz;
	my $txt = $sa->CodeText(
		-font => "{$fam} $siz",
		-readonly => 1,
		-showfolds => 0,
		-shownumbers => 0,
		-showstatus => 0,
		-syntax => 'Diff',
		-width => 40,
		-wrap => 'none',
	)->pack(@padding, -fill => 'both', -expand => 1);
	$self->{TXT} = $txt;

	return $self;
}

sub Clear {
	my $self = shift;
	my $txt = $self->{TXT};
	$txt->delete('0.0', 'end');
}

sub Diff {
	my $self = shift;
	my $txt = $self->{TXT};
	$txt->delete('0.0', 'end');
	my $widg = $self->mdi->docWidget;
	my $source = $widg->get('0.0', 'end - 1 char');
	my $file = $self->GetFile;
	my $mode = $self->GetMode;
	my $style = $self->GetStyle;
	my $diff = '';
	if ($mode eq 'File to document') {
		$diff = diff($file, \$source, { STYLE => $style });
	} else {
		$diff = diff(\$source, $file, { STYLE => $style });
	}
	$txt->insert('end', $diff);
}

sub Export {
	my $self = shift;
	my ($file) = $self->pickFileSave;
	my $txt = $self->{TXT};
	$txt->saveExport($file) if defined $file;
}

sub GetFile {
	my $self = shift;
	my $m = $self->{FILEENTRY};
	return $m->get;
}

sub GetMode {
	my $self = shift;
	my $m = $self->{MODE};
	return $$m;
}

sub GetStyle {
	my $self = shift;
	my $m = $self->{STYLE};
	return $$m;
}

sub Unload {
	my $self = shift;
	$self->ToolRightPageRemove('Diff');
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

=item L<Text::Diff>

=back

=cut


1;









