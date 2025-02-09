package App::Codit::Plugins::Backups;

=head1 NAME

App::Codit::Plugins::Backups - plugin for App::Codit

=cut

use strict;
use warnings;
use Carp;
use vars qw( $VERSION );
$VERSION = 0.17;

use File::Basename;
use File::Path qw(make_path);

use base qw( Tk::AppWindow::BaseClasses::PluginJobs );

=head1 DESCRIPTION

Protect yourself against crashes. This plugin keeps backups of your unsaved files.

=head1 DETAILS

The Backups plugin protects you against crashes of all kinds.
It silently does it's job in the background and only reports when it
finds an existing backup of a file you open.

It keeps backups of all open and unsaved files. Whenever a file is saved or closed
the backup is removed.

It keeps the backups in the configuration folder, it does not pollute your working folders.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	$self->interval(1000);
	$self->{MODIFIED} = {};
	$self->{ACTIVE} = {};
	
	$self->cmdHookBefore('deferred_open', 'openDocBefore', $self);
	$self->cmdHookAfter('doc_close', 'closeDocAfter', $self);
	$self->cmdHookBefore('doc_rename', 'docRenameBefore', $self);
	$self->cmdHookAfter('doc_save', 'saveDocAfter', $self);

	$self->backupFolder;
	return $self;
}

sub backupCheck {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $mdi = $self->extGet('CoditMDI');

	unless ($mdi->docExists($name)) {
		$self->jobEnd($name);
		return
	}

	my $mod = $self->{MODIFIED};

	if ($mdi->docModified($name)) {
		my $widg = $mdi->docGet($name)->CWidg;
		my $em = $widg->editModified;
		my $modified = $mod->{$name};

		if (defined $modified) {
			$self->backupSave($name) if $em ne $modified
		} else {
			$self->backupSave($name);
		}

		$mod->{$name} = $em;
	} else {
		$self->backupRemove($name);
	}
}

sub backupExists {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my @list = $self->backupList;
	for (@list) {
		return 1 if $_ eq $name
	}
	return 0;
}

sub backupFile {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	$name =~ s/^\///;
	$name =~ s/\//_-_/g;
	return $self->backupFolder . "/$name";
}

sub backupFolder {
	my $self = shift;
	my $config = $self->extGet('ConfigFolder')->ConfigFolder . '/Backups';
	make_path($config) unless -e $config;
	return $config
}

sub backupList {
	my $self = shift;
	my $folder = $self->backupFolder;
	my @names = ();
	if (opendir my $dh, $folder) {
		while (my $file = readdir $dh) {
			push @names, $self->backupName($file);
		}
		closedir $dh
	}
	return @names
}

sub backupName {
	my ($self, $file) = @_;
	croak 'Name not defined' unless defined $file;
	$file =~ s/_-_/\//g;
	$file = "/$file";
	return $file
}

sub backupRemove {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $file = $self->backupFile($name);
	unlink $file if -e $file;
}

sub backupRestore {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $file = $self->backupFile($name);
	my $mdi = $self->extGet('CoditMDI');
	my $widg = $mdi->docGet($name)->CWidg;
	if ($widg->load($file)) {
		$widg->editModified(1);
		return 1
	}
	return 0
}

sub backupSave {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $file = $self->backupFile($name);
	my $mdi = $self->extGet('CoditMDI');
	my $widg = $mdi->docGet($name)->CWidg;
	$widg->saveExport($file);
	return 0;
}

sub closeDocAfter {
	my ($self, $name) = @_;
	if ((defined $name) and $name) {
		$self->jobEnd($name) if $self->jobExists($name);
		$self->backupRemove($name);
	}
}

sub docRenameBefore {
	my ($self, $name, $new) = @_;
	croak 'Name not defined' unless defined $name;
	croak 'New name not defined' unless defined $new;
	$self->jobEnd($name);
	$self->jobStart($new, 'backupCheck', $self, $new);
}

sub openDocBefore {
	my ($self, $name) = @_;
	if ((defined $name) and $name) {
		if ($self->backupExists($name)) {
			my $title = 'Backup exists';
			my $text = 'A backup for ' . basename($name) . " exists.\nDo you want to recover?";
			my $icon = 'dialog-question';
			my $response = $self->popDialog($title, $text, $icon, qw/Yes No/);
			$self->after(300, ['backupRestore', $self, $name]) if $response eq 'Yes';
		}
		$self->jobStart($name, 'backupCheck', $self, $name)
	}
}

sub saveDocAfter {
	my ($self, $name) = @_;
	if ((defined $name) and $name) {
		$self->backupRemove($name);
		delete $self->{MODIFIED}->{$name};
	}
}

sub Quit {
	my $self = shift;
	for ($self->jobList) { $self->jobEnd($_) }
}

sub Unload {
	my $self = shift;
	$self->cmdUnhookBefore('deferred_open', 'openDocBefore', $self);
	$self->cmdUnhookAfter('doc_close', 'closeDocAfter', $self);
	$self->cmdUnhookBefore('doc_rename', 'docRenameBefore', $self);
	$self->cmdUnhookAfter('doc_save', 'saveDocAfter', $self);
	return $self->SUPER::Unload;
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
















