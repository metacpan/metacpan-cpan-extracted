package App::Codit::Plugins::Console;

=head1 NAME

App::Codit::Plugins::Console - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = '0.19';

use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';


use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::HList;
require Tk::Menu;
require Tk::LabFrame;
require Tk::NoteBook;
require Tk::Terminal;

=head1 DESCRIPTION

Test your code and run system commands.

Will not load on Windows.

=head1 DETAILS

The Console plugin allows you to run system commands and tests inside Codit.
It works a bit as a standard command console. If a command produces errors, 
the output is scanned for document names and line numbers. Clickable links 
are created that bring you directly to the place where the error occured.

The command console has three keybindings:

=over 4

=item B<CTRL+U>

Toggle buffering on or off.

=item B<CTRL-W>

Clear the screen

=item B<CTRL+Z>

Kill the currently running process.

=back

This plugin does not work and cannot load on Windows.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	return undef if $mswin; #will not load on windows.

	my $page = $self->ToolBottomPageAdd('Console', 'utilities-terminal', undef, 'Execute system commands', 250);
	
	my @pad = (-padx => 2, -pady => 2);
	
	my $workdir = '';
	$self->{WORKDIR} = \$workdir;
	$self->{UPDATEBLOCK} = 0;
	
	my $folder = $self->configGet('-configfolder');
	my $hist = "$folder/console_history";
	my $text = $page->Scrolled('Terminal',
		-width => 8,
		-height => 8,
		-historyfile => $hist,
		-scrollbars => 'oe',
		-linkcall => ['linkSelect', $self],
		-linkreg => qr/[^\s]+\sline\s\d+/,
	)->pack(@pad, -expand => 1, -fill => 'both');
	$text->bind('<Button-3>', [$self, 'popMenu']);
	$self->{TXT} = $text;
	$workdir = $text->cget('-workdir');
	my $sb = $self->sidebars;
	$sb->pageSelectCall('Console', sub { $text->focus });
	$sb->pageUnselectCall('Console', sub { 
		my $w = $self->mdi->docWidget;
		$w->focus if defined $w;
	});
	

	return $self;
}

sub _txt { return $_[0]->{TXT} }

sub dirGet {
	return $_[0]->_txt->workdir
}

sub dirSet { # TODO
	my ($self, $dir) = @_;
	if ((defined $dir) and (-d $dir)) {
		$self->_txt->launch("cd $dir");
	}
}

sub docWidget {
	my $self = shift;
	my $mdi = $self->mdi;
	my $name = $mdi->docSelected;
	return undef unless defined $name;
	my $doc = $mdi->docGet($name);
	return undef unless defined $doc;
	return $doc->CWidg;
}

sub linkSelect {
	my ($self, $text) = @_;
	if ($text =~ /^([^\s]+)\s+line\s+(\d+)/) {
		my $file = $1;
		my $line = $2;
		$file =~ s/blib\///;
		my $folder = $self->{TXT}->cget('-workdir');
		my $test = "$folder/$file";
		$file = $test if -e $test;
		if (-e $file) {
			my $mdi = $self->extGet('CoditMDI');
			$self->cmdExecute('doc_open', $file) unless $mdi->docExists($file);
			$self->cmdExecute('doc_select', $file);
			my $widg = $mdi->docGet($file)->CWidg;
			$widg->focus;
			$widg->goTo("$line.0");
			$widg->see("$line.0");
		}
	}
}

sub popMenu {
	my $self = shift;

	#refreshing commands
	my $txt = $self->_txt;
	my $dir = $txt->cget('-workdir');
	my $maketype = '';
	my @menuitems = ();
#	my $iconsize = $self->configGet('-menuiconsize');
	my $iconsize = 16;
	if (-e "$dir/Makefile.PL") {
		$maketype = 'make';
		for (
			'perl Makefile.PL',
			'make',
			'make clean',
			'make dist',
			'make disttest',
			'make manifest',
			'make realclean',
			'make test',
		) {
			my $cmd = $_;
			push @menuitems, ['command', $cmd,
				-command => ['launch', $txt, $cmd],
#				-image => $self->getArt('application-x-executable', $iconsize),
				-label => $cmd,
			];
		}
	}
	if (-e "$dir/Build.PL") {
		$maketype = './Build';
		for (
			'perl Build.PL',
			'./Build',
			'./Build clean',
			'./Build dist',
			'./Build disttest',
			'./Build manifest',
			'./Build realclean',
			'./Build test',
		) {
			my $cmd = $_;
			push @menuitems, ['command', $cmd,
				-command => ['launch', $txt, $cmd],
#				-image => $self->getArt('application-x-executable', $iconsize),
				-label => $cmd,
			];
		}
	}
	
	#refreshing tests
	my $tdir = "$dir/t";
	my @tests = ();
	if ((-e $tdir) and (-d $tdir)) {
		if (opendir my $dh, $tdir) {
			while (my $entry = readdir $dh) {
				next unless $entry =~ /\.t$/;
				push @tests, $entry
			}
			closedir $dh;
		}
	}
	push @menuitems, ['separator', '-'] if @tests and @menuitems;
	for (sort @tests) {
		my $cmd = $_;
		push @menuitems, ['command', $cmd,
			-command => ['launch', $txt, "$maketype; perl -Mblib t/$cmd"],
#			-image => $self->getArt('application-x-executable-script', $iconsize),
			-label => $cmd,
		];
	}
	my ($x, $y) = $self->pointerxy;
	if (@menuitems) {
		my $menu = $self->Menu(
			-menuitems => \@menuitems,
			-tearoff => 0,
		);
		$menu->bind('<Leave>', sub {
			$menu->unpost;
			$menu->destroy;
		});
		$menu->post($x - 2, $y - 2);
	}
}

sub Unload {
	my $self = shift;
	$self->ToolBottomPageRemove('Console');
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


