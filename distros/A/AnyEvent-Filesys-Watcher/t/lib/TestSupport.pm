package TestSupport;

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Filesys::Watcher;
use File::Temp qw(tempdir);
use File::Path;
use File::Basename;
use File::Copy qw(move);
use File::Spec;
use Cwd;
use Test::More;
use autodie;

use constant EXISTS => 1;
use constant DELETED => 0;

use Exporter qw(import);
our @EXPORT = qw(EXISTS DELETED);
our @EXPORT_OK = qw(create_test_files delete_test_files move_test_files
	modify_attrs_on_test_files test EXISTS DELETED);

sub create_test_files;
sub delete_test_files;
sub move_test_files;
sub modify_attrs_on_test_files;
sub test;
sub compare_ok;
sub test_done;

# On the Mac, TMPDIR is a symbolic link.  We have to resolve that with
# Cwd::realpath in order to be able to compare paths.
our $dir = Cwd::realpath(tempdir CLEANUP => 1);
my $size = 1;

sub create_test_files {
	my (@files) = @_;

	for my $file (@files) {
		my $full_file = File::Spec->catfile($dir, $file);
		my $full_dir = dirname($full_file);

		mkpath $full_dir unless -d $full_dir;

		my $exists = -e $full_file;

		open my $fd, ">", $full_file;
		print $fd "Test\n" x $size++ if $exists;
		close $fd;
	}
}

sub delete_test_files {
	my (@files) = @_;

	for my $file (@files) {
		my $full_file = File::Spec->catfile($dir, $file);
		if   (-d $full_file) { rmdir $full_file; }
		else				   { unlink $full_file; }
	}
}

sub move_test_files {
	my (%files) = @_;

	while (my ($src, $dst) = each %files) {
		my $full_src = File::Spec->catfile($dir, $src);
		my $full_dst = File::Spec->catfile($dir, $dst);
		move $full_src, $full_dst;
	}
}

sub modify_attrs_on_test_files {
	my (@files) = @_;

	for my $file (@files) {
		my $full_file = File::Spec->catfile($dir, $file);
		chmod 0750, $full_file or die "Error chmod on $full_file: $!";
	}
}

sub test {
	my (%args) = @_;

	$args{setup} ||= {};
	$args{filter} ||= sub { 1 };
	$args{expected} ||= {};
	$args{ignore} ||= [];

	my @received;
	my $watcher = AnyEvent::Filesys::Watcher->new(
		directories => $dir,
		callback => sub {
			push @received, @_;
		},
		filter => $args{filter},
		backend => $args{backend},
		parse_events => 1,
		skip_subdirectories => $args{skip_subdirectories},
	);

	$args{setup}->();

	my $done = AnyEvent->condvar;

	my $count = 0;
	my $timer = AnyEvent->timer(
		interval => 0.1,
		cb => sub {
			$done->send if test_done \@received, $args{expected};
			if (++$count > 30) {
				ok 0, "$args{description}: lame test\n";
				$done->send;
			}
		},
	);

	$done->recv;

	compare_ok $args{description}, \@received, $args{expected}, $args{ignore};
}

sub test_done {
	my ($received, $expected) = @_;

	my %expected = %$expected;

	foreach my $event (@$received) {
		my $path = File::Spec->abs2rel($event->path, $dir);
		# This is not portable but good enough for our test cases.  Otherwise
		# we would have to drag in Path::Class as a dependency.
		$path =~ s{\\}{/}g;
		delete $expected{$path};
	}

	return if keys %expected;

	return 1;
}

sub compare_ok {
	my ($description, $received, $expected, $ignore) = @_;

	$description .= ':';

	my %got;
	my %received_events;
	# First translate the events to either EXISTS or DELETED.
	foreach my $event (@{$received}) {
		my $path = File::Spec->abs2rel($event->path, $dir);
		# This is not portable but good enough for our test cases.  Otherwise
		# we would have to drag in Path::Class as a dependency.
		$path =~ s{\\}{/}g;
		my $type = $event->type;
		$received_events{$path} ||= [];
		push @{$received_events{$path}}, $type;

		if ('deleted' eq $type) {
			$got{$path} = DELETED;
		} else {
			$got{$path} = EXISTS;
		}
	}

	$ignore = [$ignore] if !ref $ignore;
	my %ignore = map { $_ => 1 } @$ignore;

	# Now match got versus expected.
	foreach my $path (keys %got) {
		next if $ignore{$path};

		# FIXME! That doesn't work if multiple events are fired.
		my $expected_type = delete $expected->{$path};
		if (!defined $expected_type) {
			my $types = join ', ', @{$received_events{$path}};
			ok 0, "$description $path: unexpected event of type(s) $types";
			next;
		}
		if (!!$expected_type != !!$got{$path}) {
			if ($expected_type) {
				ok 0, "$description $path: expected to be deleted but seems to exists";
			} else {
				ok 0, "$description $path: expected to exist but seems to be deleted";
			}
		} elsif ($expected_type) {
			ok 1, "$description $path: seems to exist";
		} else {
			ok 1, "$description $path: seems to be deleted";
		}
	}

	foreach my $path (keys %$expected) {
		ok 0, "$description $path: no event received";
	}
}

1;
