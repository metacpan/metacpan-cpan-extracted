#! /bin/false

# This next lines is here to make Dist::Zilla happy.
# ABSTRACT: Watch file system for changes

package AnyEvent::Filesys::Watcher;

use strict;

our $VERSION = 'v0.1.1'; # VERSION

use Locale::TextDomain ('AnyEvent-Filesys-Watcher');
use Scalar::Util qw(reftype);
use Path::Iterator::Rule;
use File::Spec;
use Cwd;
use Scalar::Util qw(reftype);

use AnyEvent::Filesys::Watcher::Event;

# This constructor is kind of doing reversed inheritance.  It first sets up
# the module, then selects a backend which is then instantiated.  The
# backend is expected to invoke the protected constructor _new() below.
#
# Using the factory pattern would be the cleaner approach but we want to
# retain a certain compatibility with the original AnyEvent::Filesys::Notify,
# because the module is easier to use that way.
sub new {
	my ($class, %args) = @_;

	my $backend_class = $args{backend};

	if (exists $args{cb} && !exists $args{callback}) {
		$args{callback} = delete $args{cb};
	}

	if (exists $args{dirs} && !exists $args{directories}) {
		$args{directories} = delete $args{dirs};
	}

	if ($backend_class) {
		# Use the AEFW:: prefix unless the backend starts with a plus.
		unless ($backend_class =~ s/^\+//) {
			$backend_class = "AnyEvent::Filesys::Watcher::"
				. $backend_class;
		}
	} elsif ($^O eq 'linux') {
		$backend_class = 'AnyEvent::Filesys::Watcher::Inotify2';
	} elsif ($^O eq 'darwin') {
		$backend_class = "AnyEvent::Filesys::Watcher::FSEvents";
	} elsif ($^O eq 'MSWin32') {
		$backend_class = "AnyEvent::Filesys::Watcher::ReadDirectoryChanges";
	} elsif ($^O =~ /bsd/) {
		$backend_class = "AnyEvent::Filesys::Watcher::KQueue";
	} else {
		$backend_class = "AnyEvent::Filesys::Watcher::Fallback";
	}

	my $backend_module = $backend_class . '.pm';
	$backend_module =~ s{::}{/}g;

	my $self;
	eval {
		require $backend_module;
		$self = $backend_class->new(%args);
	};
	if ($@) {
		if ($@ =~ /^Can't locate $backend_module in \@INC/) {
			warn __x(<<"EOF", class => $backend_class);
Missing backend module '{class}'!
You either have to install it or specify 'Fallback' as the backend but that is
not very efficient.

Original error message:
EOF
		}

		die $@;
	}

	return $self;
}

sub _new {
	my ($class, %args) = @_;

	my $self = bless {}, $class;

	# Resolve aliases once more.  This is necessary so that the backend classes
	# can be instantiated directly.
	if (exists $args{dirs} && !exists $args{directories}) {
		$args{directories} = delete $args{dirs};
	}

	if (exists $args{cb} && !exists $args{callback}) {
		$args{callback} = delete $args{cb};
	}

	if (!exists $args{callback}) {
		require Carp;
		Carp::croak(__"The option 'callback' is mandatory");
	}

	if (reftype $args{callback} ne 'CODE') {
		require Carp;
		Carp::croak(__"The argument to 'callback' must be a code reference");
	}

	if (exists $args{raw_events} && reftype $args{raw_events} ne 'CODE') {
		require Carp;
		Carp::croak(__"The argument to 'raw_events' must be a code reference");
	}

	if (!exists $args{base_dir}) {
		$args{base_dir} = Cwd::cwd();
	}

	if (!exists $args{directories}) {
		$args{directories} = $args{base_dir};
	}

	$args{interval} = 1 if !exists $args{interval};
	$args{directories} = [$args{directories}]
		if !ref $args{directories};
	if (exists $args{filter}
	    && defined $args{filter}
	    && length $args{filter}) {
		$args{filter} = $self->__compileFilter($args{filter});
	} else {
		$args{filter} = sub { 1 };
	}

	foreach my $arg (keys %args) {
		$self->{'__' . $arg} = $args{$arg};
	}

	$self->_oldFilesystem($self->_scanFilesystem($self->directories));

	return $self;
}

sub directories {
	my ($self) = @_;

	return [@{$self->{__directories}}];
}

sub interval {
	shift->{__interval};
}

sub callback {
	my ($self, $cb) = @_;

	if (@_ > 1) {
		$self->{__callback} = $cb;
	}

	return $self->{__callback};
}

sub filter {
	my ($self, $filter) = @_;

	if (@_ > 1) {
		$self->{__filter} = $self->__compileFilter($filter);
	}

	return $self->{__filter};
}

# Taken from AnyEvent::Filesys::Notify.
sub _scanFilesystem {
	my ($self, @args) = @_;

	# Accept either an array of directories or an array reference of
	# directories.
	my @paths = ref $args[0] eq 'ARRAY' ? @{ $args[0] } : @args;

	my $fs_stats = {};

	my $rule = Path::Iterator::Rule->new;
	my $next = $rule->iter(@paths);
	while (my $file = $next->()) {
		my $path = $self->_makeAbsolute($file);
		my %stat = $self->_stat($path)
			or next; # Skip files that we cannot stat.
		$fs_stats->{$path} = \%stat;
	}

	return $fs_stats;
}

sub _makeAbsolute {
	my ($self, $path) = @_;

	$path = File::Spec->rel2abs($path, $self->{__base_dir});
	if ('MSWin32' eq $^O || 'cygwin' eq $^O || 'os2' eq $^O || 'dos' eq $^O) {
		# This is what Cwd does.
		$path =~ s{\\}{/}g;
	}

	return $path;
}

# Taken from AnyEvent::Filesys::Notify.
sub _diffFilesystem {
	my ($self, $old_fs, $new_fs) = @_;
	my @events = ();

	for my $path (keys %$old_fs) {
		if (not exists $new_fs->{$path}) {
			push @events,
				AnyEvent::Filesys::Watcher::Event->new(
					path => $path,
					type => 'deleted',
					is_directory => $old_fs->{$path}->{is_directory},
				);
		} elsif ($self->__isPathModified($old_fs->{$path}, $new_fs->{$path})) {
			push @events,
				AnyEvent::Filesys::Watcher::Event->new(
					path => $path,
					type => 'modified',
					is_directory => $old_fs->{$path}->{is_directory},
			);
		}
	}

	for my $path (keys %$new_fs) {
		if (not exists $old_fs->{$path}) {
			push @events,
				AnyEvent::Filesys::Watcher::Event->new(
					path => $path,
					type => 'created',
					is_directory => $new_fs->{$path}->{is_directory},
				);
		}
	}

	return @events;
}

sub _filesystemMonitor {
	my ($self, $value) = @_;

	if (@_ > 1) {
		$self->{__filesystem_monitor} = $value;
	}

	return $self->{__filesystem_monitor};
}

sub _watcher {
	my ($self, $watcher) = @_;

	if (@_ > 1) {
		$self->{__watcher} = $watcher;
	}

	return $self->{__watcher};
}

sub _processEvents {
	my ($self, @raw_events) = @_;

	if ($self->{__raw_events}) {
		@raw_events = $self->{__raw_events}->(@raw_events);
	}

	my @events = $self->_parseEvents(
		sub { $self->_applyFilter(@_) },
		@raw_events
	);

	if (@events) {
		$self->_postProcessEvents(@events);
		$self->callback->(@events) if @events;
	}

	return \@events;
}

sub _parseEvents {
	shift->_rescan;
}

sub _rescan {
	my ($self) = @_;

	my $new_fs = $self->_scanFilesystem($self->directories);

	my @events = $self->_applyFilter(
		$self->_diffFilesystem($self->_oldFilesystem, $new_fs));
	$self->_oldFilesystem($new_fs);

	return @events;
}

# Some backends need to add files (KQueue) or directories (Inotify2) to the
# watch list after they are
sub _postProcessEvents {}

sub _applyFilter {
	my ($self, @events) = @_;

	my $callback = $self->filter;
	return grep { $callback->($_) } @events;
}

sub _oldFilesystem {
	my ($self, $fs) = @_;

	if (@_ > 1) {
		$self->{__old_filesystem} = $fs;
	}

	return $self->{__old_filesystem};
}

sub _directoryWrites {
	shift->{__directory_writes};
}

sub __compileFilter {
	my ($self, $filter) = @_;

	if (!ref $filter) {
		$filter = qr/$filter/;
	}

	my $reftype = reftype $filter;
	if ('REGEXP' eq $reftype) {
		my $regexp = $filter;
		$filter = sub {
			my $event = shift;
			my $path = $event->path;
			my $result = $path =~ $regexp;
			return $result;
		};
	} elsif ($reftype ne 'CODE') {
		require Carp;
		Carp::confess(__("The filter must either be a regular expression or"
						. " code reference"));
	}

	return $filter;
}

# Originally taken from Filesys::Notify::Simple --Thanks Miyagawa
sub _stat {
	my ($self, $path) = @_;

	my @stat = stat $path;

	# Return undefined if no stats can be retrieved, as it happens with broken
	# symlinks (at least under ext4).
	return unless @stat;

	return (
		path => $path,
		mtime => $stat[9],
		size => $stat[7],
		mode => $stat[2],
		is_directory => -d _,
	);
}

# Taken from AnyEvent::Filesys::Notify.
sub __isPathModified {
	my ($self, $old_path, $new_path) = @_;

	return 1 if $new_path->{mode} != $old_path->{mode};
	return if $new_path->{is_directory};
	return 1 if $new_path->{mtime} != $old_path->{mtime};
	return 1 if $new_path->{size} != $old_path->{size};
	return;
}

1;
