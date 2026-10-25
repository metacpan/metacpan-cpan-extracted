package TestSync;

use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA ();
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use App::FileSync::Admin;
use App::FileSync::Client;
use App::FileSync::Config;

sub new_env {
	my ($class, %args) = @_;

	my $base = tempdir(CLEANUP => 1);
	my $self = bless { base => $base }, __PACKAGE__;

	$self->{server} = File::Spec->catdir($base, 'server');
	$self->{client} = File::Spec->catdir($base, 'client');
	$self->{home}   = File::Spec->catdir($base, 'home');
	make_path($self->{server}, $self->{client}, $self->{home});

	open my $marker, '>', File::Spec->catfile($self->{client}, '.filesync-root')
		or die $!;
	print {$marker} "test marker\n";
	close $marker;

	my $admin = App::FileSync::Admin->new(root => $self->{server});
	$admin->repo_create(
		name        => 'docs',
		(defined $args{max_deletes} ? (max_deletes => $args{max_deletes}) : ()),
	);

	my $client_id = $args{client_id} || 'test-1';
	my $role = $args{role} || 'client';
	$admin->client_allow(repo => 'docs', client => $client_id, role => $role);

	my $config = App::FileSync::Config::default_client_config();
	$config->{client_id} = $client_id;
	$config->{repos}{docs} = {
		root             => $self->{client},
		remote_repo      => 'docs',
		role             => $role,
		transport        => 'local',
		server_root      => $self->{server},
		local_trash_days => 30,
	};

	$self->{config_path} = File::Spec->catfile($self->{home}, 'config.json');
	App::FileSync::Config::save_client($config, $self->{config_path});

	# Keep Object::Configure away from the developer's ~/.conf: every test run
	# uses its own empty settings file.  Settings tests pass config_file
	# explicitly instead.
	my $settings = File::Spec->catfile($self->{home}, 'settings.json');
	open my $settings_fh, '>', $settings or die "Cannot write $settings: $!";
	print {$settings_fh} "{}\n";
	close $settings_fh;

	$ENV{FILESYNC_HOME}     = $self->{home};
	$ENV{FILESYNC_CONFIG}   = $self->{config_path};
	$ENV{FILESYNC_SETTINGS} = $settings;

	return $self;
}

sub client {
	my ($self, %opts) = @_;

	my $config = App::FileSync::Config::load_client($self->{config_path});
	return App::FileSync::Client->new(
		config => $config,
		name   => 'docs',
		opts   => \%opts,
	);
}

sub sync {
	my ($self, %opts) = @_;
	return $self->client(%opts)->sync();
}

sub verify {
	my ($self, %opts) = @_;
	return $self->client->verify(%opts);
}

sub log {
	my ($self, %opts) = @_;
	return $self->client->log(%opts);
}

sub restore {
	my ($self, %opts) = @_;
	return $self->client->restore(%opts);
}

sub snapshot_create {
	my ($self, %opts) = @_;
	return $self->client->snapshot_create(%opts);
}

sub snapshot_list {
	my ($self) = @_;
	return $self->client->snapshot_list();
}

sub snapshot_restore {
	my ($self, %opts) = @_;
	return $self->client->snapshot_restore(%opts);
}

sub server_path {
	my ($self, $rel) = @_;
	return File::Spec->catfile($self->{server}, 'master', 'docs', split m{/}, $rel);
}

sub client_path {
	my ($self, $rel) = @_;
	return File::Spec->catfile($self->{client}, split m{/}, $rel);
}

sub write_file {
	my ($self, $side, $rel, $content, $mtime) = @_;

	my $path = $side eq 'server' ? $self->server_path($rel) : $self->client_path($rel);
	my $parent = dirname($path);
	make_path($parent) unless -d $parent;

	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print {$fh} $content;
	close $fh;

	utime($mtime, $mtime, $path) if defined $mtime;

	return $path;
}

sub read_file {
	my ($self, $side, $rel) = @_;

	my $path = $side eq 'server' ? $self->server_path($rel) : $self->client_path($rel);
	open my $fh, '<', $path or die "Cannot read $path: $!";
	binmode $fh;
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

sub exists_in {
	my ($self, $side, $rel) = @_;
	my $path = $side eq 'server' ? $self->server_path($rel) : $self->client_path($rel);
	return (-e $path || -l $path) ? 1 : 0;
}

sub tree {
	my ($self, $dir) = @_;

	my @found;
	my @queue = ($dir);
	while (@queue) {
		my $current = shift @queue;
		my $dh;
		next unless opendir($dh, $current);
		for my $name (sort readdir($dh)) {
			next if $name eq '.' || $name eq '..';
			my $path = File::Spec->catfile($current, $name);
			if (-d $path && !-l $path) {
				push @queue, $path;
			} elsif (-f $path) {
				my $relative = File::Spec->abs2rel($path, $dir);
				$relative =~ s{\\}{/}g;
				push @found, $relative;
			}
		}
		closedir $dh;
	}

	return [ sort @found ];
}

sub snapshot {
	my ($self, $dir) = @_;

	my %snapshot;
	for my $rel (@{ $self->tree($dir) }) {
		my $path = File::Spec->catfile($dir, split m{/}, $rel);
		my $sha = Digest::SHA->new(256);
		$sha->addfile($path, 'b');
		my @stat = stat($path);
		$snapshot{$rel} = $sha->hexdigest() . ':' . $stat[9];
	}

	return \%snapshot;
}

sub meta_path {
	my ($self, @parts) = @_;
	return File::Spec->catfile($self->{server}, '.filesync', 'repos', 'docs', @parts);
}

1;
