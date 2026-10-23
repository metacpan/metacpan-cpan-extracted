use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use Test::Most;

use App::Actions::Cache;
use App::Actions::Docker;
use App::Actions::Error;
use App::Actions::Process;
use App::Actions::Runner;
use App::Actions::Runner::Support qw(local_action_dir write_container_file);

# The defences against other users of the host: secrets kept off the docker
# client's command line, commands that never go through a shell, and files
# that are never written through a link someone planted.

my $UNIX = $^O ne 'MSWin32';

# Runs $code and returns the App::Actions::Error it throws, or undef.
sub error_from {
	my ($code) = @_;

	return eval { $code->(); 1 } ? undef : App::Actions::Error->caught($@);
}

subtest 'job variables are kept off the docker command line' => sub {
	local $Sub::Private::BYPASS = 1;

	my $docker = App::Actions::Docker->new;
	my $variable = sub { App::Actions::Docker::Variable->new(@_) };

	my $token = $variable->('TOKEN', 's3cret');
	is("$token", 'TOKEN=s3cret', 'a variable reads as NAME=VALUE');
	is(App::Actions::Docker::Variable->new('EMPTY')->value, '', 'and an undefined value is empty');

	my ($command, $hidden) = $docker->_hide_variables('run', '-e', $token, '-e', 'PLAIN=1', 'image');
	is_deeply($command, [ 'run', '-e', 'TOKEN', '-e', 'PLAIN=1', 'image' ], 'the value leaves the arguments, a plain string stays');
	is_deeply($hidden, { TOKEN => 's3cret' }, 'and goes to the environment instead');

	($command, $hidden) = $docker->_hide_variables('-e', $variable->('DOCKER_HOST', 'tcp://x'),
		'-e', $variable->('https_proxy', 'p'), '-e', $variable->('PATH', '/x'));
	is_deeply($command, [ '-e', 'DOCKER_HOST=tcp://x', '-e', 'https_proxy=p', '-e', 'PATH=/x' ],
		'a name the client reads for itself stays inline, in either case');
	is_deeply($hidden, {}, 'so the client is not redirected');

	($command, $hidden) = $docker->_hide_variables('-e', $variable->('Key', 'a'), '-e', $variable->('KEY', 'b'));
	is_deeply($command, [ '-e', 'Key=a', '-e', 'KEY=b' ], 'names that differ only in case stay inline');

	($command, $hidden) = $docker->_hide_variables('-e', $variable->('NUL', "a\0b"), '-e', $variable->('1BAD', 'x'));
	is_deeply($command, [ '-e', "NUL=a\0b", '-e', '1BAD=x' ], 'so do a value with a NUL and a name no environment can carry');
	is_deeply($hidden, {}, 'and none of them is hidden');
};

subtest 'a command is never handed to a shell' => sub {
	plan skip_all => 'Windows has no /bin/sh to compare with' unless $UNIX;

	my $directory = File::Temp->newdir;
	my $marker = File::Spec->catfile("$directory", 'ran');

	# A one-element list with a metacharacter is what system() would give a
	# shell; here it must be looked for as a program called that.
	my $status = eval {
		App::Actions::Process::run_quiet([ "true; touch $marker" ]);
	};
	ok(!-e $marker, 'the shell command in it did not run');
	ok(!defined $status || $status != 0, 'and the "program" was not found');

	is(App::Actions::Process::run_quiet([ $^X, '-e', 'exit 3', '; touch x' ]), 3,
		'arguments with metacharacters are passed as they are');
};

subtest 'runner files are opened to other users only when they must be' => sub {
	local $Sub::Private::BYPASS = 1;

	my $shares = \&App::Actions::Runner::_shares_runner_files;
	is($shares->(undef), 0, 'no --user: the job runs as the image says, files stay private');
	is($shares->(''), 0, 'nor does an empty one');
	is($shares->('root'), 0, 'root can read anything');
	is($shares->('0:0'), 0, 'and so can uid 0');
	is($shares->("$<"), 0, 'nor does your own uid');
	is($shares->("$<:1234"), 0, 'whatever the group');
	is($shares->('nobody'), 1, 'another user by name must be given access');
	is($shares->($< + 1), 1, 'and so must another uid');
};

subtest 'a container file is never written through a planted link' => sub {
	plan skip_all => 'symbolic links are not available' unless $UNIX && eval { symlink('', ''); 1 };

	my $directory = File::Temp->newdir;
	my $target = File::Spec->catfile("$directory", 'victim');
	my $path = File::Spec->catfile("$directory", 'step-1.sh');

	write_container_file($path, "first\n", 'a step file');
	write_container_file($path, "second\n", 'a step file');
	open my $in, '<', $path or die "cannot read $path: $!";
	is(do { local $/; <$in> }, "second\n", 'the run replaces a file it wrote');
	close $in;
	is((stat $path)[2] & 07777, 0600, 'and only its owner can read it');

	# unlink() takes the link away, so plant one the run cannot remove: a
	# directory of that name stands for a link in a sticky directory.
	my $blocked = File::Spec->catfile("$directory", 'blocked');
	mkdir $blocked or die "cannot make $blocked: $!";
	my $error = error_from(sub { write_container_file($blocked, 'secret', 'a step file') });
	ok($error && $error->is('runner.write_failed'), 'a name the run cannot claim is an error, not a write through it');
	like($error ? $error->message : '', qr/a step file/, 'which names what was being written');

	open my $out, '>', $target or die "cannot write $target: $!";
	close $out;
	my $link = File::Spec->catfile("$directory", 'step-2.sh');
	symlink $target, $link or die "cannot link $link: $!";
	write_container_file($link, 'secret', 'a step file');
	ok(!-l $link, 'a link the run can remove is replaced by a file');
	is(-s $target, 0, 'and what it pointed to is untouched');
};

subtest 'a local action may not lead out of the project' => sub {
	plan skip_all => 'symbolic links are not available' unless $UNIX && eval { symlink('', ''); 1 };

	my $outside = File::Temp->newdir;
	my $project = File::Temp->newdir;
	my $actions = File::Spec->catdir("$project", '.github', 'actions');
	make_path(File::Spec->catdir($actions, 'build'));

	my $found = local_action_dir("$project", './.github/actions/build');
	is($found->{relative}, '.github/actions/build', 'an action inside the project is found');
	is($found->{dir}, File::Spec->catdir("$project", '.github', 'actions', 'build'), 'in the project directory');

	is(local_action_dir("$project", './.github/actions/missing')->{relative}, '.github/actions/missing',
		'one that does not exist is left for the caller to report');

	symlink "$outside", File::Spec->catdir($actions, 'escape') or die "cannot link: $!";
	my $error = error_from(sub { local_action_dir("$project", './.github/actions/escape') });
	ok($error && $error->is('runner.local_action_escapes'), 'one that is a link to outside is refused');
	like($error ? $error->message : '', qr{\./\.github/actions/escape}, 'naming the step\'s uses');

	symlink 'build', File::Spec->catdir($actions, 'alias') or die "cannot link: $!";
	is(local_action_dir("$project", './.github/actions/alias')->{relative}, '.github/actions/alias',
		'while a link that stays inside is allowed');
};

subtest 'the cache is replaced through a file nobody can predict' => sub {
	plan skip_all => 'symbolic links are not available' unless $UNIX && eval { symlink('', ''); 1 };

	my $directory = File::Temp->newdir;
	my $file = File::Spec->catfile("$directory", 'cache.json');
	my $victim = File::Spec->catfile("$directory", 'victim');

	# The old temporary name was the PID and rand(); plant links at every
	# name of that shape this process could have used.
	open my $out, '>', $victim or die "cannot write $victim: $!";
	close $out;
	symlink $victim, "$file.$$.tmp" or die "cannot link: $!";

	my $cache = App::Actions::Cache->new(file => $file);
	is($cache->remember('alpine:3'), 1, 'an image is remembered');
	is(-s $victim, 0, 'without writing through a planted link');
	ok(App::Actions::Cache->new(file => $file)->entries, 'and the cache reads back');

	opendir my $handle, "$directory" or die "cannot list $directory: $!";
	my @left = grep { /\A\.cache-/ } readdir $handle;
	closedir $handle;
	is_deeply(\@left, [], 'no temporary file is left behind');
	is((stat $file)[2] & 07777, 0600, 'and the cache is private to its owner');
};

done_testing();
