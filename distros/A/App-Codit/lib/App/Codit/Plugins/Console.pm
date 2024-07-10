package App::Codit::Plugins::Console;

=head1 NAME

App::Codit::Plugins::Console - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.08;

use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';


use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::HList;
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
	my $self = $class->SUPER::new(@_, 'ToolPanel');
	return undef unless defined $self;
	return undef if $mswin; #will not load on windows.


	my $tp = $self->extGet('ToolPanel');
	my $page = $tp->addPage('Console', 'utilities-terminal', undef, 'System commands');
	
	my @pad = (-padx => 2, -pady => 2);
	my $text;
	
	my $workdir = '';
	$self->{WORKDIR} = \$workdir;
	$self->{UPDATEBLOCK} = 0;

	my $wff = $page->LabFrame(
		-label => 'Working directory',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $e = $wff->Entry(
		-textvariable => \$workdir,
	)->pack(@pad, -side => 'left', -expand => 1, -fill => 'both');
	$e->bind('<Return>', sub {
		$self->{UPDATEBLOCK} = 1;
		$self->dirSet($workdir);
		$self->{UPDATEBLOCK} = 0;
	});
	my $b = $wff->Button(
		-image => $self->getArt('folder', 22),
		-text => 'Select',
		-relief => 'flat',
		-command => sub {
			my $folder = $self->chooseDirectory;
			$self->dirSet($folder) if defined $folder;
		},
	)->pack(@pad, -side => 'left');
	
	my $nb = $page->NoteBook->pack(@pad, -expand => 1, -fill => 'both');

	my $cmdpage = $nb->add('cmd', -label => 'Commands');
	my $clist = $cmdpage->Scrolled('HList',
		-command => ['commandRun', $self],
		-width => 8,
		-height => 4,
		-scrollbars => 'osoe',
		-selectmode => 'single',
	)->pack(@pad,-expand => 1, -fill => 'both');
	$self->{CLIST} = $clist;

	my $testpage = $nb->add('test', -label => 'Tests');
	my $tlist = $testpage->Scrolled('HList',
		-command => ['testRun', $self],
		-width => 8,
		-height => 4,
		-scrollbars => 'osoe',
		-selectmode => 'single',
	)->pack(@pad, -expand => 1, -fill => 'both');
	$self->{TLIST} = $tlist;

	my $of = $page->Frame->pack(-fill => 'x');
	my $options = '';
	my $oe;
	my $state = '';
	$self->{OPTSTATE} = \$state;
	$of->Checkbutton(
		-command => sub {
			if ($state) {
				$oe->configure(-state => 'normal');
			} else {
				$oe->configure(-state => 'disabled');
			}
		},
		-text => 'Options',
		-variable => \$state,
	)->pack(@pad, -side => 'left');
	$oe = $of->Entry(
		-state => 'disabled',
		-textvariable => \$options
	)->pack(@pad, -expand => 1, -fill => 'x', -side => 'left');
	$self->{OPTIONS} = \$options;
	$of->Button(
		-command => ['refresh', $self],
		-text => 'Refresh'
	)->pack(@pad, -side => 'left');
	
	my $folder = $self->configGet('-configfolder');
	my $hist = "$folder/console_history";
	$text = $page->Scrolled('Terminal',
		-width => 8,
		-height => 8,
		-historyfile => $hist,
		-scrollbars => 'oe',
		-dircall => ['changeDir', $self],
		-linkcall => ['linkSelect', $self],
		-linkreg => qr/[^\s]+\sline\s\d+/,
	)->pack(@pad, -expand => 1, -fill => 'both');
	$self->{TXT} = $text;
	$workdir = $text->cget('-workdir');
	
	$page->Adjuster(
		-side => 'bottom',
		-widget => $text,
	)->pack(@pad, -before => $text, -fill => 'x');
	
	$self->refresh;
	
	return $self;
}

sub _cl { return $_[0]->{CLIST} }

sub _ln {
	my ($self, $name) = @_;
	$name =~ s/\./_/;
	return $name
}

sub _tl { return $_[0]->{TLIST} }

sub _txt { return $_[0]->{TXT} }

sub changeDir {
	my ($self, $dir) = @_;
	if ((defined $dir) and (-d $dir)) {
		unless ($self->{UPDATEBLOCK}) {
			my $workdir = $self->{WORKDIR};
			$$workdir = $dir;
		}
		$self->refresh;
	}
}

sub commandRun {
	my ($self, $cmd) = @_;
	my $list = $self->_cl;
	my $command = $list->entrycget($cmd, '-text');
	my $options = $self->options;
	$command = "$command $options" if $options ne '';
	$self->run($command);
}

=item B<dirGet>

=cut

sub dirGet {
	my ($self, $dir) = @_;
	my $workdir = $self->{WORKDIR};
	return $$workdir
}

=item B<dirSet>I<($dir)>

=cut

sub dirSet { # TODO
	my ($self, $dir) = @_;
	if ((defined $dir) and (-d $dir)) {
		$self->_txt->launch("cd $dir");
	}
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

sub options {
	my $self = shift;
	my $fl = $self->{OPTSTATE};
	return '' unless $$fl;
	my $op = $self->{OPTIONS};
	return $$op
}

sub refresh {
	my $self = shift;

	#refreshing commands
	my $clist = $self->_cl;
	$clist->deleteAll;
	my $d = $self->{WORKDIR};
	my $dir = $$d;
	if (-e "$dir/Makefile.PL") {
		for (
			'perl Makefile.PL',
			'make',
			'make clean',
			'make dist',
			'make manifest',
			'make realclean',
			'make test',
		) {
			my $cmd = $_;
			my $name = $self->_ln($cmd);
			$clist->add($name, -text => $cmd);
		}
	}
	if (-e "$dir/Build.PL") {
		for (
			'perl Build.PL',
			'./Build',
			'./Build clean',
			'./Build dist',
			'./Build manifest',
			'./Build realclean',
			'./Build test',
		) {
			my $cmd = $_;
			my $name = $self->_ln($cmd);
			$clist->add($name, -text => $cmd);
		}
	}
	
	#refreshing tests
	my $tdir = $self->testDir;
	my $tlist = $self->_tl;
	$tlist->deleteAll;
	my @tests = ();
	if (opendir my $dh, $tdir) {
		while (my $entry = readdir $dh) {
			next unless $entry =~ /\.t$/;
			push @tests, $entry
		}
		closedir $dh;
	}
	for (sort @tests) {
		$tlist->add($self->_ln($_), -text => $_);
	}
}

sub run {
	my ($self, $command) = @_;
	$self->_txt->launch($command);
}

sub testDir {
	my $self = shift;
	my $dir = $self->dirGet;
	$dir = "$dir/t";
	return $dir;
}

sub testRun {
	my ($self, $test) = @_;
	my $list = $self->_tl;
	my $command = "make; perl -Mblib t/" . $list->entrycget($test, '-text');
	my $options = $self->options;
	$command = "$command $options" if $options ne '';
	$self->run($command);
}

sub Unload {
	my $self = shift;
	$self->extGet('ToolPanel')->deletePage('Console');
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


