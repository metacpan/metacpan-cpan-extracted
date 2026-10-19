# ABSTRACT: Small everyday helpers: directory listing, shell commands, JSON files, number formatting, and data-structure shapes
use strict;
use feature 'say';
use warnings FATAL => 'all';
# Devel::Confess is loaded for its side effect, which is process-wide: it
# installs $SIG{__DIE__} and $SIG{__WARN__} so that every die and warn in the
# program carries a stack trace.  `use Cn::Util` has always given the caller
# this, so it stays at the top, where loading the module is enough.
use Devel::Confess;

package Cn::Util;
require 5.010001;
our $VERSION = 0.022;
require Exporter;
our @ISA = ('Exporter');
our @EXPORT = qw(dir execute file2string format_commas json_file_to_ref random_key random_value ref_to_json_file st structure);

# Startup cost.  Everything other than the pragmas, Exporter and
# Devel::Confess is loaded on first use, not at `use Cn::Util`.  Loading DDP,
# autodie, Capture::Tiny and JSON::MaybeXS eagerly cost ~40 ms of interpreter
# startup on every script that touched this module, even ones that only called
# format_commas().
#
# The rules that decide what can be deferred:
#   - PRAGMAS (warnings, feature, autodie) act on the *compiler* for the
#     enclosing lexical scope, so they can never be deferred.  autodie was the
#     single most expensive line here (~15 ms); this file does not use it, and
#     the bare open()s it was covering carry explicit `or die`.
#   - Exporter must exist at compile time (it supplies import()), but it is
#     free -- it is already in memory as part of the core.
#   - Everything else is a plain module, so `require` inside the sub that
#     needs it works.  `require` is idempotent and a repeat call is one %INC
#     hash lookup, so putting it in the hot sub costs nothing measurable.
#   - A runtime `require` does NOT run import(), so the imported short names
#     (find, capture, decode_json, colored, blessed) are not available.  Each
#     call site below is therefore fully qualified.  Calling a not-yet-loaded
#     sub with a block prototype is also unparseable at compile time, which is
#     why Capture::Tiny::capture is handed an explicit sub{} instead of a bare
#     {}.

# ---------------------------------------------------------------------------
# `use Cn::Util` hands the calling package three things besides @EXPORT:
# autodie, and DDP's p() and np().
#
# autodie is LEXICAL, and that is the hard case.  It is Fatal underneath, and
# Fatal::import does a bare `caller()` with no $Level support: calling
# autodie->import() directly from in here makes Fatal believe the importing
# file is Cn/Util.pm.  Its runtime leak-guard then sees calls arriving from a
# different file and correctly declines to apply -- open() in the caller just
# returns undef again, silently.  Verified: the naive version does nothing at
# all.
#
# So the import has to be performed in a context where caller() reports the
# caller's package and file.  A string eval carrying a #line directive does
# exactly that, and is the same trick Import::Into uses (not depended on here
# because it is not a core module).  $line/$file come from our own caller, so
# autodie's scope starts at the `use Cn::Util` line, which is where a
# hand-written `use autodie` would have started it too.
#
# The eval only compiles a closure, and the import runs when that closure is
# called after the eval has returned, which is also what Import::Into does.
# Perls up to at least 5.12 keep a string eval's own %^H in force while the
# eval runs, and autodie 2.06 (core in 5.10.1 and 5.12.5) keeps the guard that
# un-installs it at the end of the scope in %^H: imported inside the eval,
# autodie was un-installed again as the eval returned, and a missing file
# opened in the caller returned false.  t/00-load.t checks this.
#
# p() and np() are installed by _install_ddp_stubs(), below.
#
# NB: `use Cn::Util ();` skips import() entirely, per normal Perl semantics,
# so that is the escape hatch for a caller that wants none of this.
# ---------------------------------------------------------------------------
sub import {
	my $class = shift;
	$class->export_to_level(1, $class, @_);   # the @EXPORT subs, one level up

	my ($pkg, $file, $line) = caller;
	_install_ddp_stubs($pkg);
	require autodie;
	my $autodie = eval qq{package $pkg;\n#line $line "$file"\nsub { autodie->import(':default') }}
		or die "Cn::Util: could not propagate autodie to $file: $@";
	$autodie->();
	return;
}

# Scripts rely on `use Cn::Util` giving them DDP's p() and np() without a
# `use DDP` of their own.  These stubs keep that convenience without paying
# DDP's ~16 ms unless something actually prints.  They are installed at the
# caller's `use` line, which is compile time for the rest of the caller, and
# with DDP's own prototype, because that is what makes `p @files` pass \@files
# rather than a flat list.  On first call, DDP->import() is run as if from the
# caller's package, so it overwrites the stub there with the real thing.
#
# A p() or np() the caller already has -- its own, or DDP's from an earlier
# `use DDP` -- is left alone.  Util.pm, which this module was before it was
# Cn::Util, compiled the stubs into main:: whenever it loaded, which redefined
# DDP's p() under its FATAL warnings when a script said `use DDP` first.
my %DDP_LOADED;   # package => true once DDP's real p() and np() are installed there
my %DDP_STUB;     # package => { name => the stub installed for it }, p and np

sub _install_ddp_stubs {
	my ($pkg) = @_;
	no strict 'refs';
	for my $name ('p', 'np') {
		my $glob = "${pkg}::$name";
		next if defined &{$glob};
		*{$glob} = $DDP_STUB{$pkg}{$name} = sub (\[@$%&];%) {
			_load_ddp($pkg);
			# A `p` that DDP did not replace -- an `alias` in ~/.dataprinter
			# exports it under another name -- would otherwise be this stub
			# again, and the goto would call it forever.
			die "Cn::Util: DDP did not install ${pkg}::$name\n"
				if \&{$glob} == $DDP_STUB{$pkg}{$name};
			goto &{$glob};
		};
	}
	return;
}

sub _load_ddp {
	my ($pkg) = @_;
	# Marked loaded only once the import has succeeded.  Marking it first made
	# a second call after a failed load return here at once, and the stub's
	# goto then called the stub itself, forever.
	return if $DDP_LOADED{$pkg};
	require DDP;
	no strict 'refs';
	# DDP->import() exports both p() and np(), but a stub was installed only
	# for a name the caller had no sub under, so the other -- or one the caller
	# defined over a stub after its `use` line -- is the caller's own.  Its
	# glob is localised for the import, so DDP writes into a temporary that is
	# discarded, and the caller's sub comes back untouched.
	my %own = map {
		my $glob = "${pkg}::$_";
		$_ => (defined &{$glob} && \&{$glob} != ($DDP_STUB{$pkg}{$_} // 0));
	} 'p', 'np';
	local *{"${pkg}::p"}  if $own{p};
	local *{"${pkg}::np"} if $own{np};
	local $SIG{__WARN__} = sub {
		warn @_ unless $_[0] =~ m{\ASubroutine \Q$pkg\E::n?p redefined};
	};
	my $ok = eval qq{package $pkg;\nDDP->import({output => 'STDOUT', array_max => 10, show_memsize => 1, show_dualvar => 'off'}); 1};
	die "Cn::Util: could not load DDP into $pkg: $@" unless $ok;
	$DDP_LOADED{$pkg} = 1;
	return;
}

sub dir {
	my %args = (
	  tests     => 'f',
	  dir       => '.',
	  regex     => '.',
	  recursive => 0,
	  on_match  => undef,   # optional callback: streams results, keeps RAM flat
	  cpu       => 1,       # worker processes for a recursive walk; 1 = no forking
	  @_,
	);

	my %allowed = map { $_ => 1 } qw(tests dir regex recursive on_match cpu);
	if (my @bad = grep { !$allowed{$_} } keys %args) {
	  die "Unrecognized arguments: @bad\nAccepted args: "
		 . join(', ', sort keys %allowed);
	}
	# Added 's' (non-zero size), removed 't' (tty test - meaningless on a path)
	die "Unrecognized characters in tests: $args{tests}"
	  if $args{tests} =~ /[^rwxoRWXOezsfdlpSbcugkTB]/;
	die "cpu must be a positive integer, got '$args{cpu}'"
	  unless $args{cpu} =~ /\A[1-9][0-9]*\z/;
	my $re = eval { qr/$args{regex}/ }
	  or die "Invalid regex '$args{regex}': $@";
# Compile the tests once. The first test stats the path; every later test
# reuses the stat buffer via the special '_' filehandle, so N tests cost
# one stat(2) syscall instead of N (~2.4x faster for 4 tests).
# -l needs lstat, so it is hoisted to the front, and the test after it
# must re-stat the real path (otherwise '_' holds lstat data, or -l _
# would be a fatal error).
	my @t = split //, $args{tests};
	@t = ((grep { $_ eq 'l' } @t), (grep { $_ ne 'l' } @t));
	my @parts;
	my $fresh = 1;   # 1 = the next test must stat the path itself rather than reuse '_'
	for my $t (@t) {
	  if    ($t eq 'l') { push @parts, '-l $_[0]';   $fresh = 1 }
	  elsif ($fresh)    { push @parts, "-$t \$_[0]"; $fresh = 0 }
	  else              { push @parts, "-$t _" }
	}
	my $tester = @parts
	  ? (eval 'sub { ' . join(' && ', @parts) . ' }'
		   or die "Failed to compile tests: $@")
	  : sub { 1 };   # empty tests string now means "no filtering", not "nothing matches"

	my $target_dir = $args{dir};
	# On Windows, File::Find turns every "\" in its starting path into "/"
	# (the "canonicalize directory separators" step of _find_opt in 1.44, the
	# version on the Strawberry Perl 5.42 smoker that failed t/dir.t; 1.14, in
	# perl 5.10.1, does not), so a recursive listing of "C:\x" reported paths under
	# "C:/x", while the non-recursive listing and the parallel walk's top
	# levels joined onto "C:\x"; and since "C:/x" ne "C:\x", the walk's check
	# that leaves the root itself out never matched.  Doing the same here first
	# gives every mode the same paths.  Only on MSWin32, as in File::Find:
	# elsewhere "\" is an ordinary character in a file name.
	my $is_win32 = $^O eq 'MSWin32';
	$target_dir =~ tr{\\}{/} if $is_win32;
	# Strip trailing slashes, but keep a root intact: "/", and on Windows "C:/",
	# because "C:" alone is the current directory on drive C, not its root.
	# Collapsing first is what turns "///" into "/"; it used to be left as it
	# was, to be joined as "////etc".
	$target_dir =~ s{/+\z}{/}s;
	$target_dir =~ s{/\z}{}s
		unless $target_dir =~ ($is_win32 ? qr{\A(?:[A-Za-z]:)?/\z}s : qr{\A/\z}s);
	# "." is left off the front of results; a root, the only $d that still
	# ends in "/", must not become "//etc" or "C://etc".
	my $join = sub {
		my ($d, $item) = @_;
		$d eq '.' ? $item : $d =~ m{/\z} ? "$d$item" : "$d/$item"
	};

	my $cb = $args{on_match};
	my @items;
	my $emit = $cb // sub { push @items, $_[0] };

	if ($args{recursive}) {
		require File::Find; # ~1.6 ms, and only the recursive branch needs it
		# Walk everything strictly below $start, handing each match to $sink.
		my $find = sub {
			my ($start, $sink) = @_;
			my $strip = $start eq '.';
			# File::Find lstat()s its starting path, so a $start that is a
			# symlink to a directory was taken for a file and nothing was
			# found under it -- although opendir, which the non-recursive
			# listing and the parallel walk's top levels use, follows it.  A
			# trailing slash makes lstat resolve the link; File::Find strips
			# the slash again only after the lstat (1.14 in perl 5.10.1 and
			# 1.44 in 5.44 alike), so the paths it reports are unchanged.
			File::Find::find({
				no_chdir => 1,
				wanted   => sub {
					 return if $_ eq $start;             # $start itself is not "below" it
					 my ($file) = m{([^/]+)\z}s;         # basename, much cheaper than File::Spec
					 if ($file =~ $re && $tester->($_)) {
					     my $path = $_;
					     $path =~ s{^\./}{} if $strip;
					     $sink->($path);
					 }
				},
			}, -l $start ? "$start/" : $start);
		};
		if ($args{cpu} == 1) {
			$find->($target_dir, $emit);
		} else {
			_dir_parallel($target_dir, $args{cpu}, $re, $tester, $join, $find, $emit);
		}
	} else {
		# cpu is ignored here on purpose: one readdir plus one stat per entry
		# is ~6 us warm, far below the cost of forking and shipping results back.
		opendir my $dh, $target_dir
			or die "Cannot open directory $target_dir: $!";
		while (defined(my $item = readdir $dh)) {   # defined(): a file named "0" is falsy
			next if $item =~ /\A\.\.?\z/;           # \A..\z: "$" would match before a trailing \n
			next if $item !~ $re;
			my $path = $join->($target_dir, $item);
			$emit->($path) if $tester->($path);
		}
		closedir $dh;
	}
	return $cb ? () : @items;
}

# Jobs handed out per worker.  Parallel::ForkManager starts a new job whenever
# a worker finishes, so more jobs than workers is what evens out a tree whose
# subdirectories differ wildly in size; each job costs one fork plus one
# Storable round-trip through a temp file, so too many jobs loses again.
# Measured 2026-09-23, 20-core NVMe box, warm cache, best of 3, seconds:
#
#   tree (files)                 serial   k=1    k=2    k=4    k=8    k=16
#   ~/perl5 (150k), cpu=8         1.23    0.95   0.25   0.29   0.36   0.47
#   ~/perl5 (150k), cpu=4         1.23    1.03   0.82   0.39   0.45   0.61
#   perlbrew/build (120k), cpu=8  0.75    0.19   0.24   0.25   0.33   0.44
#
# k=1 and k=2 collapse on the skewed tree; 4 is the smallest value that does
# not.  Re-run: edit the value below, then time
#   perl -Ilib -MCn::Util -e 'dir(dir => $ARGV[0], recursive => 1, cpu => 8)' TREE
my $DIR_JOBS_PER_CPU = 4;

# Recursive dir() across $cpu worker processes.  Results come back to this
# process and go through $emit here, so an on_match closure still sees and
# mutates the caller's variables -- it just runs after a whole job's batch
# arrives rather than per file, and match order differs from the serial walk.
sub _dir_parallel {
	my ($root, $cpu, $re, $tester, $join, $find, $emit) = @_;
	require Parallel::ForkManager; # not core, and only cpu > 1 needs it

	# One subtree per job would starve the pool whenever a single directory
	# holds most of the tree (~/perl5: one of 3 top-level dirs has 99% of the
	# files, and a top-level split gave no speedup at any cpu).  So walk
	# breadth-first here until a level is wide enough to share out, testing
	# the entries of every level walked; the final level's directories are
	# already tested and become the jobs.
	my $want  = $cpu * $DIR_JOBS_PER_CPU;
	my @level = ($root);
	while (@level && @level < $want) {
		my @next;
		for my $d (@level) {
			opendir my $dh, $d or die "Cannot open directory $d: $!";
			while (defined(my $item = readdir $dh)) {
				next if $item =~ /\A\.\.?\z/;
				my $path = $join->($d, $item);
				$emit->($path) if $item =~ $re && $tester->($path);
				push @next, $path if !-l $path && -d _; # lstat: File::Find does not follow symlinks either
			}
			closedir $dh;
		}
		@level = @next;
	}
	return unless @level;

	my @jobs;
	push @{ $jobs[$_ % $want] }, $level[$_] for 0 .. $#level;

	my @errors;
	my $pm = Parallel::ForkManager->new($cpu);
	# The default 1 s poll in wait_all_children added a flat 1.01 s to every
	# call, measured; 0 makes it block in waitpid instead.
	$pm->set_waitpid_blocking_sleep(0);
	$pm->run_on_finish(sub {
		my ($pid, $exit, $id, $signal, $core, $data) = @_;
		if ($signal || $exit || !$data) {
			push @errors, "dir: worker $pid died (exit $exit, signal $signal)";
			return;
		}
		push @errors, $data->{error} if defined $data->{error};
		$emit->($_) for @{ $data->{paths} };
	});
	for my $job (@jobs) {
		$pm->start and next;
		my @found;
		my $ok = eval { $find->($_, sub { push @found, $_[0] }) for @$job; 1 };
		$pm->finish(0, { paths => \@found, error => $ok ? undef : "$@" });
	}
	$pm->wait_all_children;
	die join "\n", @errors if @errors;
	return;
}

sub execute {
	my ($cmd, $return, $die) = @_;
	$return = 'exit' unless defined $return;
	$die    = 1      unless defined $die;
	if ($return !~ m/^(exit|stdout|stderr|all)$/) {
		die "you gave \$return = \"$return\", while this subroutine only accepts ^(exit|stdout|stderr|all)\$";
	}
	require Capture::Tiny; # ~7.5 ms
	# Capture::Tiny redirects fd 1 and fd 2 and nothing else, so the child still
	# inherits the parent's fd 0.  A child that prompts -- rm on a
	# write-protected file, cp -i, apt -- prompts only when fd 0 is a tty, then
	# writes its question into the captured stderr where nobody can see it and
	# blocks on the terminal for an answer the user does not know is wanted.
	# (Observed 2026-09-13: `rm -r` on read-only cl.tex hung jobsearch/tex/tar.pl
	# indefinitely.)  Pointing fd 0 at /dev/null turns the prompt into an instant
	# EOF, so such a child declines and exits instead of hanging.
	# Reopening STDIN is the point, not `local *STDIN`: the child inherits the
	# descriptor, and only reopening the handle perl holds on fd 0 -- which frees
	# fd 0 and so reclaims it as the lowest available -- puts /dev/null there.
	require File::Spec;
	my $saved_stdin;
	open $saved_stdin, '<&', \*STDIN or die "cannot save STDIN: $!"
		if defined fileno STDIN;   # a caller may legitimately have closed it
	open STDIN, '<', File::Spec->devnull or die "cannot reopen STDIN on devnull: $!";
	# An explicit sub{} rather than capture { ... }: the prototype that makes
	# the block form legal is not visible at compile time under a runtime
	# require, so perl would try to parse the block as an anonymous hash.
	my ($stdout, $stderr, $exit) = Capture::Tiny::capture(sub {
		system( $cmd )
	});
	if (defined $saved_stdin) {
		open STDIN, '<&', $saved_stdin or die "cannot restore STDIN: $!";
	} else {
		close STDIN;
	}
	if (($die == 1) && ($exit != 0)) {
		say STDERR "exit = $exit";
		say STDERR "STDOUT = $stdout";
		say STDERR "STDERR = $stderr";
		die "$cmd\n failed";
	}
	if ($return eq 'exit') {
		return $exit
	} elsif ($return eq 'stderr') {
		chomp $stderr;
		return $stderr
	} elsif ($return eq 'stdout') {
		chomp $stdout;
		return $stdout
	} elsif ($return eq 'all') {
		chomp $stdout;
		chomp $stderr;
		return {
			exit   => $exit,
			stdout => $stdout,
			stderr => $stderr
		}
	} else {
		die "$return broke pigeonholes"
	}
	return $stdout
}

sub file2string {
	my ($file) = @_;
	open my $fh, '<', $file or die "can't read $file: $!"; # was autodie
	return do { local $/; <$fh> };
}

sub format_commas { # https://stackoverflow.com/questions/33442240/perl-printf-to-use-commas-as-thousands-separator
	my ($n, $format) = @_;
	$format = '.%02d' unless defined $format;
	# '%.0u' is the documented way to ask for a whole number, but sprintf
	# prints nothing for it only when the hundredths are 0: 1234.56 came out
	# "1,23456".  So '%.0u' is recognised here, rounds half up to a whole
	# number, and prints no fraction at all.
	my $whole = $format eq '%.0u';
	my $neg = $n < 0;
	my $abs = abs $n;
	my ($int, $cents);
	if ($whole) {
		$int   = int($abs + .5);
		$cents = 0;
	} else {
		$int = int $abs;
		# int(100 * (.005 + frac)) is the original expression, and is exactly
		# round-half-up to hundredths -- .005 * 100 is the +0.5 before truncation.
		# It is kept verbatim so no already-correct result shifts by a cent.
		$cents = int(100 * (.005 + ($abs - $int)));
		# ...but it can land on 100 (.999 rounds up to 1.00), which used to be
		# printed straight into the fraction: 999999.999 came out "999,999.100".
		# The carry has to go into the integer part instead.
		if ($cents >= 100) {
			$int++;
			$cents -= 100;
		}
	}
	# Split off the sign and work on the magnitude: the old code fed a negative
	# through int()/sprintf and produced "-1,234.-49" for -1234.5, and lost the
	# sign entirely for -0.5.  A value that rounds to zero stays unsigned, so
	# -0.001 is "0.00" rather than "-0.00".
	my $sign = ($neg && ($int || $cents)) ? '-' : '';
	# '%.0f' rather than interpolating $int: a large magnitude stringifies in
	# scientific notation, and the reverse/unpack grouping shredded that into
	# "1e,+20" for 1e20.
	my $digits = sprintf '%.0f', $int;
	return $sign . reverse(join(',', unpack('(A3)*', reverse $digits))) . ($whole ? '' : sprintf($format, $cents));
}

sub json_file_to_ref {
	my ($json_filename) = @_;
	die "$json_filename doesn't exist or isn't a file" unless -f $json_filename;
	die "$json_filename has 0 size" if -s $json_filename == 0;
	open my $fh, '<:raw', $json_filename or die "can't read $json_filename: $!";
	my $json = do { local $/; <$fh> }; # slurp; $/ restored immediately
	close $fh;
	# Python/NumPy emit bare NaN / Infinity / -Infinity, which are not valid
	# JSON. Rewrite them to null (-> undef) only when they sit in JSON value
	# position (after '[', ',' or ':').  That test alone also matched text
	# inside a string -- "values: [1, NaN, 2]" became "values: [1, null, 2]"
	# -- so the first alternative matches each whole string literal and
	# (*SKIP)(*FAIL) resumes the scan after its closing quote.
	$json =~ s/"(?:[^"\\]++|\\.)*+"(*SKIP)(*FAIL)|[\[,:]\s*\K-?(?:NaN|Infinity)(?=\s*[,\]}])/null/gs;
	require JSON::MaybeXS; # ~4.3 ms
	return JSON::MaybeXS::decode_json($json);
}

# These return *some* key/value from the hash, not a random one -- whichever
# pair the hash's internal iterator yields first.
#
# They used to be `foreach my $key (keys %{$hash}) { return $key }`, which is
# O(n): `keys` in list context materializes EVERY key into a temporary list,
# and then the loop throws all but the first away.  On a 50,000-key hash that
# was 1.48 ms per call; via each() it is 0.15 us, ~10,000x faster.
#
# The bare `keys` in void context resets the iterator, so repeated calls keep
# returning the first pair instead of walking off the end of the hash.  It is
# reset again after the each(), which would otherwise leave it one pair in, so
# that a caller's own `while (each %h)` afterwards skipped the first pair.
# The old `keys`-in-list-context version left it at the start, and so do these.
#
# Falling off a foreach also returned '' rather than undef in scalar context;
# each() on an empty hash returns an empty list, so these now yield a true
# undef, which is what t/random.t always asserted.
sub random_key {
	my ($hash) = @_;
	keys %{ $hash };                 # reset the iterator
	my ($key) = each %{ $hash };
	keys %{ $hash };
	return $key;
}

sub random_value {
	my ($hash) = @_;
	keys %{ $hash };                 # reset the iterator
	my (undef, $value) = each %{ $hash };
	keys %{ $hash };
	return $value;
}

sub ref_to_json_file {
	my ($ref, $json_filename) = @_;
	my $ref_json_filename = ref $json_filename;
	unless ($ref_json_filename eq '') {
		die "$json_filename isn't a scalar/string";
	}
	require JSON::MaybeXS;
	require Term::ANSIColor;
	open my $fh, '>:raw', $json_filename   # Write it unmangled
		or die "can't write $json_filename: $!"; # was autodie
	say $fh JSON::MaybeXS::encode_json($ref);
	say 'Wrote ' . Term::ANSIColor::colored(['blue on_red'], $json_filename);
	return $json_filename;
}

# ----------------------------------------------------------------------------
# structure(): print the *shape* of a data structure instead of its values.
#
# p() from Data::Printer shows you every value; when a 50,000-element array
# holds the same kind of record over and over, that is the wrong tool.  This
# merges all elements of an array into ONE representative node, so you see the
# schema once.  Keys absent from some of the merged records are flagged '?';
# values that disagree about their type become a UNION.
#
# Two entry points, mirroring DDP's own p()/np() split:
#   st()        - prototyped, so `st %hash` works like `p %hash`.  Use this
#                 interactively.
#   structure() - plain sub, takes a reference: structure(\%hash), or the
#                 return value of another call.  Use this from other code.
#
# Scalar::Util and Term::ANSIColor are require'd in structure(), which st()
# also funnels through, so the per-value helpers below can call them fully
# qualified without re-checking %INC on every node.  Scalar::Util is not loaded
# at `use` time because it drags in List::Util's XS bootstrap (~4 ms) and only
# this family ever touches it.

my %STRUCTURE_COLOR = (
	key    => 'bold',            # hash key names
	opt    => 'red',             # the '?' optional marker
	HASH   => 'bold cyan',
	ARRAY  => 'bold yellow',
	UNION  => 'bold magenta',
	elem   => 'bright_black',    # the '[*]' / '<alt>' / '(empty)' markers
	class  => 'bold white',      # blessed package names
	number => 'green',
	string => 'bright_blue',
	bool   => 'bright_magenta',
	null   => 'bright_black',
	CODE   => 'yellow',
	other  => 'red',             # anything unexpected
);

sub _structure_color {
	my ($name, $text, $use_color) = @_;
	return $text unless $use_color;
	return Term::ANSIColor::colored([$STRUCTURE_COLOR{$name} // $STRUCTURE_COLOR{other}], $text);
}

# Classify one value.  Blessed containers keep their package name so that
# Foo=HASH and a plain HASH don't get merged into the same node.
sub _structure_kind {
	my ($v) = @_;
	return 'null' unless defined $v;
	my $r = ref $v;
	return (Scalar::Util::looks_like_number($v) ? 'number' : 'string') if $r eq '';
	if (my $class = Scalar::Util::blessed($v)) {
		return 'bool' if $class eq 'JSON::PP::Boolean' || $class eq 'Types::Serialiser::Boolean';
		return 'Regexp' if $class eq 'Regexp';
		my $rt = Scalar::Util::reftype($v) // '';
		return "$class=$rt" if $rt eq 'HASH' || $rt eq 'ARRAY' || $rt eq 'SCALAR' || $rt eq 'REF';
		return $class;
	}
	return $r; # HASH ARRAY SCALAR REF CODE GLOB
}

# Merge a list of same-position values into a single structural node:
#   { kind => 'hash',  keys => { k => { node => .., optional => 0|1 } }, n, class }
#   { kind => 'array', node => .., n => #instances, lens => [lengths], class }
#   { kind => 'sref',  node => .. }                       # \$x and \\$x
#   { kind => 'leaf',  types => { typename => 1, ... } }
#   { kind => 'union', alts => { kindname => node } }
# $stack holds the refaddrs of the containers we are currently inside, so a
# self-referential structure terminates instead of recursing forever.
sub _structure_describe {
	my ($values, $opt, $depth, $stack) = @_;
	my %by_kind;
	push @{ $by_kind{ _structure_kind($_) } }, $_ for @{ $values };
	my @kinds = sort keys %by_kind;

	if (@kinds > 1) {
		return {
			kind => 'union',
			alts => { map { $_ => _structure_describe($by_kind{$_}, $opt, $depth, $stack) } @kinds },
		};
	}
	my $k = $kinds[0] // 'null';
	my ($class, $reftype) = $k =~ /\A(.+)=(HASH|ARRAY|SCALAR|REF)\z/;
	$reftype //= $k;

	if ($reftype eq 'HASH' || $reftype eq 'ARRAY' || $reftype eq 'SCALAR' || $reftype eq 'REF') {
		# Drop anything we're already inside: its shape is an ancestor's shape.
		my @fresh = grep { !$stack->{ Scalar::Util::refaddr($_) } } @{ $values };
		return { kind => 'leaf', types => { '(cycle)' => 1 } } unless @fresh;
		if ($opt->{max_depth} && $depth >= $opt->{max_depth}) {
			return { kind => 'leaf', types => { '(...)' => 1 } };
		}
		local @{ $stack }{ map { Scalar::Util::refaddr($_) } @fresh } = (1) x @fresh;

		if ($reftype eq 'HASH') {
			my %keys; # key => { vals => [...], seen => n }
			for my $h (@fresh) {
				for my $key (keys %{ $h }) {
					push @{ $keys{$key}{vals} }, $h->{$key};
					$keys{$key}{seen}++;
				}
			}
			# A wide hash used as a dictionary has no interesting key names:
			# merge every value into one representative entry instead.
			if ($opt->{hash_max} && keys %keys > $opt->{hash_max}) {
				my @all = map { @{ $keys{$_}{vals} } } keys %keys;
				return {
					kind  => 'hash',
					class => $class,
					n     => scalar @fresh,
					wide  => scalar keys %keys,
					keys  => { '*' => {
						node     => _structure_describe(\@all, $opt, $depth + 1, $stack),
						optional => 0,
					}},
				};
			}
			my %out;
			for my $key (keys %keys) {
				$out{$key} = {
					node     => _structure_describe($keys{$key}{vals}, $opt, $depth + 1, $stack),
					optional => ($keys{$key}{seen} < @fresh ? 1 : 0),
				};
			}
			return { kind => 'hash', class => $class, n => scalar @fresh, keys => \%out };
		}
		elsif ($reftype eq 'ARRAY') {
			my (@elems, @lens);
			for my $a (@fresh) {
				push @lens,  scalar @{ $a };
				push @elems, @{ $a };
			}
			return {
				kind  => 'array',
				class => $class,
				node  => (@elems ? _structure_describe(\@elems, $opt, $depth + 1, $stack) : undef),
				n     => scalar @fresh,
				lens  => \@lens,
			};
		}
		return { # SCALAR / REF
			kind  => 'sref',
			class => $class,
			node  => _structure_describe([map { ${ $_ } } @fresh], $opt, $depth + 1, $stack),
		};
	}
	return { kind => 'leaf', types => { $k => 1 } };
}

sub _structure_array_desc {
	my ($node, $c) = @_;
	my @lens = @{ $node->{lens} };
	my ($min, $max) = ($lens[0], $lens[0]);
	for (@lens) { $min = $_ if $_ < $min; $max = $_ if $_ > $max }
	my $range = $min == $max ? $min : "$min-$max";
	my $out = $c->('ARRAY', "ARRAY[$range]");
	$out .= " (from $node->{n} instances)" if $node->{n} > 1;
	return $out;
}

sub _structure_render {
	my ($label, $node, $indent, $opt, $c, $lines) = @_;
	my $pad = ('    ' x $indent) . ($label // '');
	my $class = defined $node->{class} ? $c->('class', "$node->{class}=") : '';

	if ($node->{kind} eq 'hash') {
		my @k = sort keys %{ $node->{keys} };
		my $count = $node->{wide} // scalar @k;
		push @{ $lines }, $pad . $class . $c->('HASH', "HASH{$count}")
			. ($node->{n} > 1 ? " (from $node->{n} instances)" : '')
			. ($node->{wide} ? ' ' . $c->('elem', '(keys merged)') : '');
		for my $key (@k) {
			my $entry = $node->{keys}{$key};
			my $name  = ($key eq '*' && $node->{wide})
				? $c->('elem', '<*>') . ': '
				: $c->('key', $key) . ($entry->{optional} ? $c->('opt', '?') : '') . ': ';
			_structure_render($name, $entry->{node}, $indent + 1, $opt, $c, $lines);
		}
	}
	elsif ($node->{kind} eq 'array') {
		push @{ $lines }, $pad . $class . _structure_array_desc($node, $c);
		if ($node->{node}) {
			_structure_render($c->('elem', '[*]') . ': ', $node->{node}, $indent + 1, $opt, $c, $lines);
		} else {
			push @{ $lines }, ('    ' x ($indent + 1)) . $c->('elem', '(empty)');
		}
	}
	elsif ($node->{kind} eq 'sref') { # \$x: stay on the same line, no extra indent level
		# The '\ ' joins the label rather than the pad, and $indent passes
		# through unchanged, so whatever the referent holds is still indented
		# from this line.  Passing $pad with indent 0 put the line right but
		# dropped the referent's own children back to depth 1.
		_structure_render(($label // '') . $class . $c->('elem', '\\') . ' ', $node->{node}, $indent, $opt, $c, $lines);
	}
	elsif ($node->{kind} eq 'union') {
		push @{ $lines }, $pad . $c->('UNION', 'UNION');
		for my $alt (sort keys %{ $node->{alts} }) {
			_structure_render($c->('elem', "<$alt>") . ' ', $node->{alts}{$alt}, $indent + 1, $opt, $c, $lines);
		}
	}
	else { # leaf
		push @{ $lines }, $pad . join($c->('elem', '|'),
			map { $c->($_, $_) } sort keys %{ $node->{types} });
	}
	return;
}

sub structure {
	my ($ref, %args) = @_;
	my %opt = (
		output    => 'stdout', # 'stdout' | 'stderr' | 'string' (string: return it, print nothing)
		color     => 'auto',   # 'auto' | 1 | 0
		max_depth => 0,        # 0 = unlimited
		hash_max  => 32,       # hashes wider than this collapse to one '<*>' entry; 0 = never
		as        => undef,    # optional header line, like DDP's "as"
		%args,
	);
	my %allowed = map { $_ => 1 } qw(output color max_depth hash_max as);
	if (my @bad = grep { !$allowed{$_} } keys %opt) {
		die "Unrecognized arguments: @bad\nAccepted args: " . join(', ', sort keys %allowed);
	}
	die "output must be one of stdout, stderr, string" if $opt{output} !~ m/\A(stdout|stderr|string)\z/;

	require Scalar::Util; # ~4 ms (List::Util XS bootstrap); see header note

	my $fh = $opt{output} eq 'stderr' ? \*STDERR : \*STDOUT;
	my $use_color = $opt{color} eq 'auto'
		? ((($ENV{CLICOLOR_FORCE} || ($opt{output} ne 'string' && -t $fh)) && !$ENV{NO_COLOR}) ? 1 : 0)
		: $opt{color};
	require Term::ANSIColor if $use_color; # ~0.8 ms, skipped entirely when piping
	my $c = sub { _structure_color($_[0], $_[1], $use_color) };

	my @lines;
	push @lines, $c->('key', $opt{as}) if defined $opt{as};
	_structure_render(undef, _structure_describe([$ref], \%opt, 0, {}), 0, \%opt, $c, \@lines);
	my $out = join("\n", @lines) . "\n";
	print {$fh} $out unless $opt{output} eq 'string';
	return $out;
}

# st(): structure() with DDP's calling convention, so you can write
#
#   st %hash;   st @array;   st $ref;   st %hash, max_depth => 2;
#
# instead of backslashing by hand.  The \[@$%&] prototype makes perl pass a
# reference to the caller's variable, which is the whole trick -- but it also
# means the argument must BE a variable: st(\%h), st({...}) and
# st(func()) are compile-time errors, exactly as they are for DDP's p().
# Call structure() directly in those cases.
#
# NOTE: the obvious short name 's' is impossible.  perl's tokenizer resolves a
# bare 's' to the substitution operator before it ever looks for a sub of that
# name, so `s $ref` dies with "Substitution pattern not terminated" and even
# `s($ref)` is parsed as s(pat)(repl).  Only `&s($ref)` would work, which
# defeats the point.  Hence 'st'.
sub st (\[@$%&];%) {
	my ($item, @args) = @_;
	# `st %h` / `st @a` / `st &c` hand us the HASH/ARRAY/CODE ref directly, but
	# `st $x` hands us a ref to the scalar $x -- one layer more than we want.
	# The prototype rejects everything except a plain variable, so a SCALAR/REF
	# here is always that added layer: peel exactly one.  `st $hashref` then
	# describes the hash, and `my $x = 42; st $x` prints 'number', not '\ number'.
	my $ref = (ref($item) eq 'SCALAR' || ref($item) eq 'REF') ? ${ $item } : $item;
	return structure($ref, @args);
}

1;
# from md2pod.pl πατερ ημων ο εν τοις ουρανοις, ἁγιασθήτω τὸ ὄνομά σου
=encoding utf8

=head1 NAME

Cn::Util - Small everyday helpers: directory listing, shell commands, JSON files, number formatting, and data-structure shapes

=head1 Synopsis

 use Cn::Util;
 
 my @scripts = dir(dir => '.', regex => '\.pl$', recursive => 1);
 my $branch  = execute('git rev-parse --abbrev-ref HEAD', 'stdout');
 my $text    = file2string('notes.txt');
 print format_commas(1234567.891), "\n";   # 1,234,567.89
 
 my $data = json_file_to_ref('results.json');
 ref_to_json_file($data, 'copy.json');
 
 st $data;    # print the shape of $data, not its values
 p  $data;    # Data::Printer's p(), loaded on first use

=head1 Description

C<Cn::Util> is a collection of the functions I reach for in nearly every script: listing a directory with file tests and a regex, running a shell command and keeping its output, slurping a file, reading and writing JSON, putting commas in a number, and seeing the I<shape> of a large data structure without scrolling through every value in it.

Loading it is meant to be cheap.  Everything that is not needed to compile the caller is loaded the first time a function needs it, so a script that only calls C<format_commas> does not pay for C<JSON::MaybeXS>, C<Capture::Tiny> or C<Data::Printer>.

=head2 What C<use Cn::Util> does

Besides exporting the ten functions below, C<use Cn::Util> does three things to the file and package that loads it:

=over

=item * It turns on C<autodie ':default'> in that file, from the C<use> line onward, so a bare C<open> or C<close> that fails dies with a message rather than returning false.

=item * It gives that package C<p> and C<np> from C<Data::Printer> (C<DDP>).  They are stubs until first called, so C<DDP> is loaded only by a script that prints something.  A C<p> or C<np> the package already has, such as one from an earlier C<use DDP>, is left alone.

=item * It loads C<Devel::Confess>, which is process-wide: every C<die> and C<warn> in the program carries a stack trace.

=back

C<use Cn::Util ();> imports nothing and skips the first two; C<Devel::Confess> is still loaded.  C<use Cn::Util 'format_commas';> imports only the names given, and still does all three.

=head1 Functions

All functions are exported by default.

=head2 dir

 my @files = dir(dir => '/data', regex => '\.csv$');
 my @tree  = dir(dir => '/data', regex => '\.csv$', recursive => 1, cpu => 8);
 dir(dir => '/data', recursive => 1, on_match => sub { say $_[0] });

Returns the paths under C<dir> whose base name matches C<regex> and that pass every file test in C<tests>.  The paths are C<dir> joined to the entry with C</>; with the default C<< dir =E<gt> '.' >>, the leading C<./> is left off.  C<.> and C<..> are never returned.

It takes these named arguments:

=over

=item * C<dir> (default C<.>): The directory to list.  Trailing slashes are removed, but C</> stays C</>.  A C<dir> that is a symbolic link to a directory is listed through the link, recursively or not.

=item * C<regex> (default C<.>): A pattern the base name must match, given as a string or a C<qr//>.  An invalid pattern dies, naming it.

=item * C<tests> (default C<f>): One or more of perl's file tests, as letters: C<rwxoRWXOezsfdlpSbcugkTB>.  Every one must pass.  C<'d'> lists directories; C<''> applies no test at all.

=item * C<recursive> (default C<0>): C<1> descends into subdirectories, through C<File::Find>, without following symbolic links.

=item * C<cpu> (default C<1>): For a recursive listing, the number of worker processes (through C<Parallel::ForkManager>).  Ignored when C<recursive> is C<0>.

=item * C<on_match> (no default): A code reference called with each path as it is found; C<dir> then returns an empty list, so a very large tree is never held in memory.

=back

The file tests share one C<stat> per path, so asking for four of them costs no more than asking for one.  C<-l> is checked first, with C<lstat>.

With C<cpu> greater than 1, C<dir> walks the tree breadth-first until one level holds four directories per worker, then shares those directories out.  The results are the same as a serial walk, in a different order.  C<on_match> still runs in the calling process, so it can change the caller's variables, but it is called once a worker's whole batch arrives rather than as each file is found.

An unknown argument, a letter that is not a file test, a C<cpu> that is not a positive integer, and a directory that cannot be opened all die.

=head2 execute

 my $exit   = execute('make test');                  # 0, or dies
 my $out    = execute('git log -1 --format=%H', 'stdout');
 my $err    = execute('perl -c script.pl', 'stderr');
 my $all    = execute('ls /nonexistent', 'all', 0);  # does not die
 # $all = { exit => 512, stdout => '', stderr => "ls: cannot access ..." }

Runs C<$cmd> through the shell with C<system>, capturing its standard output and standard error with C<Capture::Tiny>.  The second argument says what to return:

=over

=item * C<exit> (the default): the wait status, C<$?> -- 0 for success, 256 for C<exit 1>

=item * C<stdout>: standard output, chomped

=item * C<stderr>: standard error, chomped

=item * C<all>: a hash reference with C<exit>, C<stdout> and C<stderr>

=back

The third argument, C<$die>, is 1 by default: a command that exits non-zero prints its exit status, standard output and standard error to C<STDERR> and dies.  Pass 0 to have the status returned instead.

The command's standard input is the null device (C</dev/null>, or C<nul> on Windows).  A command that would prompt -- C<rm> on a write-protected file, C<cp -i> -- reads end-of-file and declines rather than waiting, unseen, for an answer.  The caller's C<STDIN> is restored afterwards.

=head2 file2string

 my $text = file2string('notes.txt');

Returns the whole of a file as one string, read without any decoding layer.  A file that cannot be opened dies, naming it.

=head2 format_commas

 format_commas(1234567.891);         # '1,234,567.89'
 format_commas(1234567, '%.0u');     # '1,234,567'
 format_commas(999999.999);          # '1,000,000.00'
 format_commas(-0.5);                # '-0.50'
 format_commas(1e20);                # '100,000,000,000,000,000,000.00'

Puts a comma between each group of three digits of the integer part and appends the hundredths, rounded half up.  The second argument is the C<sprintf> format the hundredths are printed with, C<'.%02d'> by default; C<'%.0u'> rounds half up to a whole number and prints no fraction.  Rounding that carries into the integer part does so (C<0.999> is C<1.00>), a negative number keeps its sign, a number that rounds to zero has none, and a large number is grouped as digits rather than printed in exponent form.

=head2 json_file_to_ref

 my $ref = json_file_to_ref('results.json');

Reads a JSON file and returns the decoded data, through C<JSON::MaybeXS>.  Python's C<json> module and NumPy write C<NaN>, C<Infinity> and C<-Infinity> as bare words, which are not JSON; where one of those stands as a value it is read as C<null>, so it becomes C<undef>.  The same words inside a string are left alone.  A file that does not exist, or is empty, dies.

=head2 ref_to_json_file

 ref_to_json_file($data, 'results.json');   # prints "Wrote results.json"

Writes a data structure to a file as JSON, through C<JSON::MaybeXS>, prints C<Wrote> and the file name, and returns the file name.  The file name must be a plain string; a reference dies.

=head2 random_key, random_value

 my $key   = random_key(\%hash);
 my $value = random_value(\%hash);

Return one key, or one value, of a hash -- whichever pair perl's hash iterator yields first, which is quick no matter how big the hash is.  This is I<any> key, not a randomly chosen one: the same hash returns the same pair each time.  It is useful for looking at one record of a hash of records.  An empty hash returns C<undef>.

Both reset the hash's iterator, so do not call them on a hash in the middle of an C<each> loop.

=head2 structure

 my $text = structure($ref, output => 'string');
 structure(\%config, max_depth => 2, as => 'config');

Prints the I<shape> of a data structure rather than its values: C<p> shows every element of a 50,000-element array of records, while C<structure> merges them into one and shows the record once.

 my @people = (
     { name => 'Ann', age => 31, langs => ['perl', 'R'] },
     { name => 'Bo',  age => 28, langs => [], email => undef },
 );
 st @people;

prints

 ARRAY[2]
     [*]: HASH{4} (from 2 instances)
         age: number
         email?: null
         langs: ARRAY[0-2] (from 2 instances)
             [*]: string
         name: string

A key that only some of the merged hashes have is marked C<?>.  Values in the same place that are of different kinds are shown as a C<UNION> of each kind.  Arrays show the range of their lengths.  Blessed references show their class.  A reference back to a containing structure is shown as C<(cycle)> rather than followed.

It takes these options after the reference:

=over

=item * C<output> (default C<stdout>): C<stdout> or C<stderr> to print there; C<string> to print nothing.  The text is returned in every case.

=item * C<color> (default C<auto>): C<1> or C<0>.  C<auto> colours the output when it goes to a terminal, or when C<CLICOLOR_FORCE> is set, unless C<NO_COLOR> is set.

=item * C<max_depth> (default C<0>): How many levels to descend before printing C<(...)>; C<0> is no limit.

=item * C<hash_max> (default C<32>): A hash with more keys than this is taken to be a lookup table, and its values are merged into one entry, C<< E<lt>*E<gt> >>, rather than listed by key.  C<0> lists every key.

=item * C<as> (no default): A line to print above the structure.

=back

=head2 st

 st %hash;
 st @array;
 st $ref, max_depth => 2;

C<structure>, called the way C<p> is called: the argument is a variable, not a reference to one, and the options follow it.  As with C<p>, it must be a variable -- C<st(\%h)> and C<st(func())> do not compile; call C<structure> for those.

=head1 Installation

 cpanm Cn::Util

or, from a copy of the repository:

 perl Makefile.PL
 make
 make test
 make install

=head1 Compatibility

C<Cn::Util> runs on perl 5.10.1 and later, and is tested there.  C<execute> hands its command to the shell, so the command has to be written for the shell of the system it runs on.  On Windows, the paths C<dir> returns are joined with C</>, which perl accepts there, and a C<\> in the C<dir> argument is returned as C</>, so C<< dir =E<gt> q{C:\Temp} >> lists C<C:/Temp/a.txt>; recursive listings with C<cpu> rely on C<Parallel::ForkManager>'s emulated C<fork>.

=head1 Author

David E. Condon L<mailto:dec986@gmail.com>

=head1 License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 Thanks

A lot of this work used Claude AI, which was paid for by the University of Idaho's IMCI
