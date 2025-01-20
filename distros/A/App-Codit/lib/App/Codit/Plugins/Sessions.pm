package App::Codit::Plugins::Sessions;

=head1 NAME

App::Codit::Plugins::Sessions - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.16;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

use File::Path qw(make_path);
require App::Codit::SessionManager;

my @saveoptions = (
	'-contentindent',
	'-contentposition',
	'-contentsyntax',
	'-contenttabs',
	'-contentwrap',
	'-showfolds',
	'-shownumbers',
	'-showstatus',
);

=head1 DESCRIPTION

Manage your sessions. Saves your named session on exit and reloads it on start.

=head1 DETAILS

The sessions plugin allows you to save a collection of documents as a session.
When re-opening the session the documents are loaded in the exact order as they
were when the session was closed. Also the syntax option, tab size, indent style,
bookmarks and insert cursor position are saved. The only thing that is lost is your
undo stack.

The sessions plugin also saves the following from plugins if they are loaded:

=over 4

=item The working folder from the Console plugin

=item The working folder from the FileBrowser plugin

=item The project name of the currently loaded project in the Git plugin

=back

The session manager allows you to keep your sessions orderly.

=head1 COMMANDS

=over 4

=item B<session_dialog>

Pops the dialog for managing sessions.

=item B<session_fill_menu>

Called when the Session menu in the menu bar is opened.

=item B<session_new>

Closes current session and creates a new, unnamed, one.

=item B<session_open>

Takes a session name as parameter. Closes current session and opens the new one.

=item B<session_save>

Save current session. If the session was not saved before, a dialog will pop to enter a name.

=item B<session_save_as>

Save current session under a new name.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ConfigFolder', 'MenuBar');
	return undef unless defined $self;

	$self->sessionFolder;

	$self->{CURRENT} = '';
	$self->{DATA} = {};

	$self->cmdConfig(
		session_dialog => ['sessionDialog', $self],
		session_fill_menu => ['sessionFillMenu', $self],
		session_new => ['sessionNew', $self],
		session_open => ['sessionOpen', $self],
		session_save => ['sessionSave', $self],
		session_save_as => ['sessionSaveAs', $self],
	);
	$self->cmdHookAfter('set_title', 'AdjustTitle', $self);
	return $self;
}

sub AdjustTitle {
	my $self = shift;
	my $mdi = $self->mdi;
	my $doc = $mdi->docSelected;
	my $name = $self->configGet('-appname');
	if (defined $doc) {
		my $label = $mdi->docTitle($doc);
		$name = "$label - $name";
	}
	my $current = $self->sessionCurrent;
	if ($current ne '') {
		$name =  "$current: $name" ;
	}
	$self->configPut(-title => $name);
}

sub bookmarksInitialize {
	my $self = shift;
	my $bookmarks = $self->extGet('Plugins')->plugGet('Bookmarks');
	$self->after(200, ['Initialize', $bookmarks]) if defined $bookmarks;
}

sub browserDir {
	my ($self, $dir) = @_;
	my $b = $self->extGet('Plugins')->plugGet('FileBrowser');
	return unless defined $b;
	my $browser = $b->browser;
	$browser->load($dir) if defined $dir;
	return $browser->folder;
}

sub CanQuit {
	my $self = shift;
	$self->sessionSave unless $self->sessionCurrent eq '';
	$self->mdi->docForceClose(1);
	return 1
}

sub consoleDir {
	my ($self, $dir) = @_;
	my $console = $self->extGet('Plugins')->plugGet('Console');
	return unless defined $console;
	$console->dirSet($dir) if defined $dir;
	return $console->dirGet;
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
		[	'menu', 				undef,			"~Session"],
		[	'menu', 				'Session::',	"~Open session",		'session_fill_menu'],
		[	'menu_normal',		'Session::',	"~New session",		'session_new',			'document-new'],
		[	'menu_separator',	'Session::',	'se1'],
		[	'menu_normal',		'Session::',	"~Save session",		'session_save',		'document-save'],
		[	'menu_normal',		'Session::',	"~Save session as",	'session_save_as',	'document-save'],
		[	'menu_separator',	'Session::',	'se1'],
		[	'menu_normal',		'Session::',	"~Manage sessions",	'session_dialog',		'configure'],
	)
}

sub projectName {
	my ($self, $proj) = @_;
	my $git = $self->extGet('Plugins')->plugGet('Git');
	return '' unless defined $git;
	$git->projectSelect($proj) if defined $proj;
	return $git->projectCurrent;
}

sub sessionClose {
	my $self = shift;
	my $session = $self->sessionCurrent;
	my $mdi = $self->mdi;
	if ($mdi->docConfirmSaveAll) {
		$self->sessionSave unless $session eq '';
		$self->sessionCurrent('');
		my @list = $self->sessionDocList;

		my $fc = $mdi->docForceClose;
		$mdi->docForceClose(1);
		$mdi->silentMode(1);

		my $size = @list;
		my $count = 0;
		$self->progressAdd('multi_close', 'Close session', $size, \$count);
		for (@list) {
			$self->cmdExecute('doc_close', $_);
			$count ++;
#			$self->update;
			$self->pause(20);
		}
		$self->progressRemove('multi_close');
		$mdi->silentMode(0);
		$mdi->docForceClose($fc);
		$self->AdjustTitle;
		return 1;
	}
	return 0
}

sub sessionCurrent {
	my $self = shift;
	$self->{CURRENT} = shift if @_;
	return $self->{CURRENT}
}

sub sessionDelete {
	my ($self, $name) = @_;
	return if $name eq $self->sessionCurrent;
	my $file = $self->sessionFolder . "/$name";
	unlink $file if -e $file;
}

sub sessionDialog {
	my $self = shift;
	my $d = $self->SessionManager(
		-plugin => $self,
		-popover => $self->toplevel,
	);
	$d->Show;
	$d->destroy;
}

sub sessionExists {
	my ($self, $name) = @_;
	return 1 if -e $self->sessionFolder . "/$name";
	return 0
}

sub sessionDocList {
	my $self = shift;
	my $interface = $self->mdi->Interface;
	my $disp = $interface->{DISPLAYED};
	my $undisp = $interface->{UNDISPLAYED};
	return @$disp, @$undisp;
}

sub sessionFillMenu {
	my $self = shift;
	my $mnu = $self->extGet('MenuBar');
	my @list = $self->sessionList;
	my $var = $self->sessionCurrent;
# 	print "current $var\n";
	my ($menu, $index) = $mnu->FindMenuEntry('Session::Open session');
	if (defined($menu)) {
		my $submenu = $menu->entrycget($index, '-menu');
		$submenu->delete(1, 'last');
		for (@list) {
			my $f = $_;
			$submenu->add('radiobutton',
				-variable => \$var,
				-value => $f,
				-label => $f,
				-command => sub { $self->sessionOpen($f) }
			);
		}
	}
}

sub sessionFolder {
	my $self = shift;
	my $config = $self->extGet('ConfigFolder')->ConfigFolder . '/Sessions';
	make_path($config) unless -e $config;
	return $config
}

sub sessionList {
	my $self = shift;
	my $dir = $self->sessionFolder;
	if (opendir(my $dh, $dir)) {
		my @list = ();
		while (my $thing = readdir $dh) {
			push @list, $thing unless $thing =~ /^\.+$/;
		}
		return sort @list
	}
}

sub sessionNew {
	my $self = shift;
	$self->sessionClose;
	$self->mdi->docSelectFirst;
}

sub sessionOpen {
	my ($self, $name) = @_;

	my $file = "Sessions/$name";
	my $cff = $self->extGet('ConfigFolder');

	return if $name eq $self->sessionCurrent;
	return unless $cff->confExists($file);
	return unless $self->sessionClose;

	my @list = $cff->loadSectionedList($file, 'cdt session');

	my $mdi = $self->mdi;
	$mdi->silentMode(1);

	my $count = 0;
	my $size = @list;
	$self->progressAdd('multi_open', 'Open session', $size, \$count);
	my $select;
	my $workdir; #plugin Console
	my $project; #plugin Git
	my $browserdir; #plugin FileBrowser
	for (@list) {
		my ($file, $options) = @$_;
		if ($file eq 'general') {
			$select = $options->{'selected'};
			$workdir = $options->{'workdir'};
			$project = $options->{'project'};
			$browserdir = $options->{'browserdir'};
			$count ++
		} else {
			if ($self->cmdExecute('doc_open', $file)) {
				$mdi->deferredOptions($file, $options);
			}
			$count ++;
#			$self->update;
			$self->pause(20);
		}
	}
	$self->progressRemove('multi_open');
	$self->sessionCurrent($name);
	$self->AdjustTitle;

	$mdi->silentMode(0);

	$mdi->interfaceCollapse;
	if ((defined $select) and ($mdi->docExists($select))) {
		$self->cmdExecute('doc_select',$select)
	} else {
		$mdi->docSelectFirst
	}
	$self->consoleDir($workdir) if defined $workdir;
	$self->projectName($project) if defined $project;
	$self->browserDir($browserdir) if defined $browserdir;
	$self->bookmarksInitialize;
	$self->update;
	$self->StatusMessage("Session '$name' loaded");
}

sub sessionSave {
	my $self = shift;
# 	print "sessionSave\n";

	my $name = $self->sessionCurrent;
	return $self->sessionSaveAs if $name eq '';

	my $file = "Sessions/$name";
	my $cff = $self->extGet('ConfigFolder');
	my $mdi = $self->mdi;

	#configuring general options
	my @genopt = (	'selected', $mdi->docSelected	);
	#workdir of plugin Console
	my $workdir = $self->consoleDir;
	push @genopt, 'workdir', $workdir if defined $workdir;
	#workdir of plugin FileBrowser
	my $browserdir = $self->browserDir;
	push @genopt, 'browserdir', $browserdir if defined $browserdir;
	#project name of plugin Git
	my $project = $self->projectName;
	push @genopt, 'project', $project if $project ne '';

	my @list = (['general', { @genopt }]);

	#getting all document names ordered as they are on the tab bar.
	my @items = $self->sessionDocList;
	for (@items) {
		my $item = $_;
		if ($mdi->deferredExists($item)) {
			my $options = $mdi->deferredOptions($item);
			my %h = %$options;
			push @list, [$item, \%h]
		} else {
			next if $item =~/^Untitled/;
			my $doc = $mdi->docGet($item);
			my %h = ();
			for (@saveoptions) { $h{$_} = $doc->cget($_) }

			#saving bookmarks
			my $w = $doc->CWidg;
			my (@l) = $w->bookmarkList;
			if (@l) {
				my $bm = '';
				for (@l) {
					$bm = "$bm$_ ";
				}
				$h{'bookmarks'} = $bm;
			}			

			push @list, [$item, \%h]
		}
	}
	$cff->saveSectionedList($file, 'cdt session', @list)
}

sub sessionSaveAs {
	my $self = shift;
	my $dialog = $self->YADialog(
		-buttons => ['Ok', 'Cancel'],
	);
	$dialog->Label(
		-text => 'Please enter a session name',
		-justify => 'left',
	)->pack(-fill => 'x', -padx => 3, -pady => 3);
	my $text = '';
	my $e = $dialog->Entry(
		-textvariable => \$text,
	)->pack(-fill => 'x', -padx => 3, -pady => 3);
	$e->focus;
	my $but = $dialog->show(-popover => $self->toplevel);
	if (($but eq 'Ok') and ($text ne '')) {
		$self->sessionCurrent($text);
		$self->sessionSave;
		$self->AdjustTitle;
	}

}

sub sessionValidateName {
	my ($self, $name) = @_;
	return 0 if $name eq '';
	return 0 if $name +~ /\//;
	return 0 if $name +~ /\\/;
	return 1
}

sub Unload {
	my $self = shift;
	for (qw/
		session_dialog
		session_fill_menu
		session_new
		session_open
		session_save
		session_save_as
	/) {
		$self->cmdRemove($_);
	}
	$self->sessionCurrent('');
	$self->cmdUnhookAfter('set_title', 'AdjustTitle', $self);
	$self->AdjustTitle;
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













