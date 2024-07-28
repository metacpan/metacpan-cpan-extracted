package App::Codit::Plugins::Git;

=head1 NAME

App::Codit::Plugins::FileBrowser - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.09;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::Adjuster;
require Tk::DocumentTree;
require Tk::Menu;
use File::Basename;

use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';

my @contextmenu = (
	[ 'menu_normal',    undef,  '~Open all files',  'git_open_all',	 'document-open'],
	[ 'menu_normal',    undef,  '~Remove from project',  'git_remove_dialog',	 'edit-delete'],
	[ 'menu_separator', undef,  'c1'],
	[ 'menu_normal',    undef,  '~Collapse all',  'git_collapse'],
	[ 'menu_normal',    undef,  '~Expand all',  'git_expand'],
);

=head1 DESCRIPTION

Integrate Git into Codit.

=head1 DETAILS

This plugin will only load if the git executable is installed.

It adds a document list to the navigation panel with the git icon. 

When a file is opened it will check if it belongs to a git repository. If it does
it will add the repository to the top menu list. If you select a repository
from that list all documents in that repository are loaded in the file list.
Selecting a document in the list will open it if it is not yet opened and select it.

When a file is closed it will check if there are any remaining documents in it's repository
are opened. If none are open it will unselect the repository and remove it from the
top menu list.

It has a context menu that pops with the right mouse button. You can quickly open all files in
the repository, or remove the current selected file from the repository. And you can collapse
and expand the list.

=head1 COMMANDS

Thi Git plugin adds the following commands to Codit.

=over 4

=item B<git_collapse>

Collapses the git document tree and only opens the current selected document, if it is in
the current selected repository.

=item B<git_command> I<$project>, I<$commandstring>

Executes the git command in $commandstring for repository $project.

=item B<git_expand>

Epxands the git document tree.

=item B<git_open_all>

Opens all files in the current selected repository.

=item B<git_remove> I<?$name?>

If $name is not specified, $name is the selected document.

Closes $name, Removes it from the current selected repository
and deletes the file from disk. Use with care.

=item B<git_remove_dialog>

Same as git_remove but first asks nicely if you really want to do this.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'Navigator');
	return undef unless defined $self;

	#load only if git command line is installed
	my $git = `git -v`;
	return undef unless $git =~/^git\sversion/;

	$self->cmdHookAfter('doc_open', 'openDocAfter', $self);
	$self->cmdHookAfter('doc_close', 'closeDocAfter', $self);
	$self->cmdHookBefore('doc_select', 'selectDocBefore', $self);
	$self->cmdConfig(
		git_add => ['gitAdd', $self],
		git_collapse => ['gitCollapse', $self],
		git_command => ['gitCommand', $self],
		git_expand => ['gitExpand', $self],
		git_open_all => ['gitOpenAll', $self],
		git_remove => ['gitRemove', $self],
		git_remove_dialog => ['gitRemoveDialog', $self],
	);

	$self->{PROJECTS} = {};

	my $tp = $self->extGet('NavigatorPanel');
	my $page = $tp->addPage('Git', 'git-icon', undef, 'Manage your projects');
	
	my $pframe = $page->Frame->pack(-fill => 'x');
	$pframe->Label(-text => 'Project:')->pack(-side => 'left');

	my $current = '';
	$self->{CURRENT} = \$current;
	my $mb = $pframe->Menubutton(
		-anchor => 'w',
		-textvariable => \$current,
	)->pack(-side => 'left', -expand => 1, -fill => 'x');

	my $menu = $mb->Menu(-tearoff => 0);
	$mb->configure(-menu => $menu);
	$self->{PMENU} = $menu;

	my $nav = $self->extGet('Navigator');
	my $gtree = $page->DocumentTree(
		-entryselect => ['selectInternal', $self],
		-diriconcall => ['GetDirIcon', $nav],
		-fileiconcall => ['GetFileIcon', $nav],
		-saveiconcall => ['GetSaveIcon', $nav],
	)->pack(-expand => 1, -fill => 'both');
	my $stack =$self->extGet('MenuBar')->menuStack(@contextmenu);
	$gtree->configure('-contextmenu', $stack);
	$self->{TREE} = $gtree;
	
	$self->after(10, ['doPostConfig', $self]);
	return $self;
}

sub closeDocAfter {
	my $self = shift;
	my ($file) = @_;
	if ($file ne 0) {
		#does the file belong to a project?
		my $project = $self->fileInAnyProject($file);
		if (defined $project) {
			#is any other file of this project open?
			$self->projectRemove($project) unless $self->filesOpenInProject($project);
		}
	}
	return @_
}

sub doPostConfig {
	my $self = shift;
	my $mdi = $self->mdi;
	my @list = $mdi->docFullList;
	for (@list) {
		my $doc = $_;
		my $folder = $self->projectFind($doc);
		if (defined $folder) {
			my $name = $self->projectName($folder);
			$self->projectAdd($name, $folder);
		}
	}
	$self->after(1000, ['navContextMenu', $mdi]);
}

sub fileInAnyProject {
	my ($self, $file) = @_;
	my @list = $self->projectList;
	for (@list) {
		my $project = $_;
		return $project if $self->fileInProject($project, $file)
	}
	return undef
}

sub fileInProject {
	my ($self, $project, $file) = @_;
	my @files = $self->gitFileList($project);
	my $term = quotemeta($file);
	my @containing = grep { /^$term$/ } @files;
	return 1 if @containing;
	return ''
}

sub fileRoot {
	my ($self, $file) = @_;
	return '/' unless $mswin;
	if ($file =~ /^([a-zA-Z]\:\\)/) {
		return $1
	}
}

sub filesOpenInProject {
	my ($self, $project) = @_;
	my $mdi = $self->mdi;
	my @g = $self->gitFileList($project);
	my @open = ();
	for (@g) {
		push @open, $_ if $mdi->docExists($_);
	}
	return @open	
}

sub fileStrip {
	my ($self, $project, $file) = @_;
	my $offset = length($self->projectFolder($project)) + 1;
	$file = substr($file, $offset);
	return $file;
}

sub gitAdd {
	my $self = shift;
	my $project = $self->projectCurrent;
	return if $project eq '';

	my $doc = $self->mdi->docSelected;
	return unless defined $doc;
	return unless -e $doc;
	return if $self->fileInProject($project, $doc);

	$doc = $self->fileStrip($project, $doc);
	$self->gitCommand($project, "add $doc");
	$self->projectRefresh;
}

sub gitCollapse {	$_[0]->{TREE}->collapseAll }

sub gitCommand {
	my ($self, $project, $command) = @_;
	my $folder = $self->projectFolder($project);
	return unless defined $folder;
	return `cd $folder; git $command`
}

sub gitExpand {	$_[0]->{TREE}->expandAll }

sub gitFileList {
	my ($self, $project) = @_;
	my $list = $self->gitCommand($project, 'ls-files');
	my $folder = $self->projectFolder($project);
	my $sep = $self->{TREE}->cget('-separator');
	my @items = ();
	while ($list =~ s/([^\n]*)\n//) {
		my $file = "$folder$sep$1";
		push @items, $file
	}
	return @items
}

sub gitOpenAll {
	my $self = shift;
	my $project = $self->projectCurrent;
	return if $project eq '';
	my @list = $self->gitFileList($project);
	my $mdi = $self->mdi;
	$mdi->silentMode(1);
	for (@list) {
		next unless -T $_;
		$self->cmdExecute('doc_open', $_) unless $mdi->docExists($_)
	}
	$mdi->silentMode(0);
}

sub gitRemove {
	my ($self, $project, $name) = @_;
	if ($self->fileInProject($project, $name)) {
		$self->cmdExecute('doc_close', $name) if $self->mdi->docExists($name);

		#remove project path from $name
		$name = $self->fileStrip($project, $name);

		$self->gitCommand($project, "rm -f $name");
		$self->projectRefresh;
	}
}

sub gitRemoveDialog {
	my ($self, $project, $name) = @_;
	$project = $self->projectCurrent unless defined $project;
	return if $project eq '';
	unless (defined $name) {
		my $tree = $self->{TREE};
		my $folder = $self->projectFolder($project);
		my $sep = $tree->cget('-separator');
		($name) = $tree->infoSelection;
		$name = "$folder$sep$name" if defined $name;
	}
	if (defined $name) {
		my $answer = $self->popDialog(
			'Removing from repository',
			"Are you sure you want to remove\n$name?",
			'dialog-warning',
			'Yes', 'No',
		);
		$self->cmdExecute('git_remove', $project, $name) if $answer eq 'Yes';
	}
}

sub openDocAfter {
	my $self = shift;
	my ($file) = @_;
	if ($file ne '') {
		my $folder = $self->projectFind($file);
		if (defined $folder) {
			my $name = $self->projectName($folder);
			$self->projectAdd($name, $folder);
		}
	}
	return @_
}

sub prj { return $_[0]->{PROJECTS} }

sub projectAdd {
	my ($self, $project, $folder) = @_;
	return if $project eq '';
	return if $self->projectExists($project);
	$self->prj->{$project} = $folder;
	$self->{PMENU}->add('command',
		-label => $project,
		-command => ['projectSelect', $self, $project],
	);
}

sub projectCurrent {
	my $self = shift;
	my $cur = $self->{CURRENT};
	$$cur = shift if @_;
	return $$cur
}

sub projectExists {
	my ($self, $project) = @_;
	return exists $self->prj->{$project};
}

sub projectFind {
	my ($self, $file) = @_;
	return undef unless -e $file;
	my $root = $self->fileRoot($file);
	while ($file ne $root) {
		$file = dirname($file);
		my $git = "$file/.git";
		return $file if (-e $git) and (-d $git)
	}
	return undef
}

sub projectFolder {
	my ($self, $project) = @_;
	return $self->prj->{$project};
}

sub projectList {
	my $self = shift;
	my $prj = $self->prj;
	return sort keys %$prj;
}

sub projectName {
	my ($self, $folder) = @_;
	my $url = `cd $folder; git config --local remote.origin.url`;
	if ($url =~ /\/([^\/]+)\.git$/) {
		return $1
	}
}

sub projectRefresh {
	my $self = shift;

	my $tree = $self->{TREE};
	$tree->deleteAll;
	
	my $cur = $self->projectCurrent;
	return if $cur eq '';

	my @list  = $self->gitFileList($cur);
	for (@list) {
		$tree->entryAdd($_)
	}
}

sub projectRemove {
	my ($self, $project) = @_;
	return unless $self->projectExists($project);
	my $prj = $self->prj;

	#remove from the menu
	my @p = $self->projectList;
	my $size = @p;
	my $menu = $self->{PMENU};

	for (0 .. $size - 1) {
		if ($menu->entrycget($_, '-label') eq $project) {
			$menu->delete($_);
			last;
		}
	}

	#unselect if this project is currently selected
	$self->projectSelect('') if $self->projectCurrent eq $project;

	#remove
	delete $prj->{$project};
}

sub projectSelect {
	my ($self, $project) = @_;
	$self->projectCurrent($project);
	$self->projectRefresh;
}

sub selectDocBefore {
	my $self = shift;
	my ($file) = @_;
	$self->selectExternal($file);
	return @_
}

sub selectExternal {
	my ($self, $name) = @_;
	my $cur = $self->projectCurrent;
	return if $cur eq '';
	$self->{TREE}->entrySelect($name) if $self->fileInProject($cur, $name);
}

sub selectInternal {
	my ($self, $name) = @_;
	my $mdi = $self->mdi;
	unless ($mdi->docExists($name)) {
		$self->cmdExecute('doc_open', $name) if -T $name;
	}
	$self->cmdExecute('doc_select', $name) if $mdi->docExists($name);
}

sub Unload {
	my $self = shift;
	$self->extGet('NavigatorPanel')->deletePage('Git');
	for (
		'git_add', 
		'git_collapse', 
		'git_command',
		'git_expand',	
		'git_open_all', 
		'git_remove',
		'git_remove_dialog',
	) {
		$self->cmdRemove($_);
	}
	$self->cmdUnhookAfter('doc_close', 'closeDocAfter', $self);
	$self->cmdUnhookAfter('doc_open', 'openDocAfter', $self);
	$self->cmdUnhookBefore('doc_select', 'selectDocBefore', $self);
	my $flag = $self->SUPER::Unload;
	my $mdi = $self->mdi;
	$self->after(100, ['navContextMenu', $mdi]);
	return $flag;
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=cut




1;
