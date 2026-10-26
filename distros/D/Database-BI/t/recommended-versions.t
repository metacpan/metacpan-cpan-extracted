#!/usr/bin/env perl

# A test that loads a recommended module has to say which version it needs.
#
# "Is it installed" is not the question the test is asking.  The application
# asks HTML::OSM for 0.12 and Geo::Coder::Free for 0.48; a machine with 0.11
# installed answers an installation check truthfully and then fails every
# assertion about the page, in a run that reads like a bug in the application.
# The floor is already written down once, in Makefile.PL's prereqs recommends
# and in the cpanfile generated from it; this file holds the tests to it, so the
# assumption cannot come back one eval { require ... } at a time.
#
# What is checked:
#
#   * every load of a recommended module - require M or use M - in t/*.t and
#     t/lib/**/*.pm is gated, in the same statement, by M->VERSION(n) with n no
#     lower than the declared floor.  The gate and the load in one statement is
#     the idiom the tree already uses, and it keeps the check independent of
#     what else the file does with the module;
#   * every Test::Needs spec that names a recommended module declares the floor
#     too.  A spec without a version - { 'M' => 0 }, or M in the bare list -
#     skips on any installed copy, which is the same assumption as a bare
#     require and drifts the same way; the module a test hides with
#     Test::Without::Module has no version to name and is reported as such;
#   * a skip message that reports a recommended module as not there, or not new
#     enough, names the floor as well.  A skipped run is all most readers ever
#     see of such a test, and "HTML::OSM not available" leaves them unable to
#     tell a missing 0.12 from a machine with 0.11 on it.  A skip about
#     something else - "already loaded", "has no $method()" - names the module
#     without being about its version, and is not checked; neither is a message
#     held in a variable, which this file cannot read;
#   * the application's own check and message say the same thing.  The
#     M->VERSION(x) call in lib/ that decides whether an optional module is
#     usable asks for the floor - written into the call, or through a variable
#     the file declares, or through its $MIN_*VERSION constant when the argument
#     is an expression this file cannot follow - and the sentence shown to a user
#     when the module is missing or too old names that same version.  An
#     application that accepts HTML::OSM 0.10 says nothing at all on a machine
#     with 0.11, and one that asks for 0.47 while the distribution recommends
#     0.48 tells the user to install a version it will reject again;
#   * a recommended module with no declared floor (Redis) is reported rather
#     than quietly exempt, so nothing is unchecked by accident;
#   * Makefile.PL and cpanfile still agree on the set, because a floor only one
#     of them knows about is enforced nowhere;
#   * the checker itself, on probe files it writes: a bare load is rejected, a
#     gate below the floor is rejected, a gate in a multi-line probe counts, a
#     skip message without the floor is rejected, a message that interpolates a
#     constant is read through it, a check through an unreadable expression is
#     answered by the floor constant, and a module that is a hard prerequisite is
#     left alone.  A regex that had stopped matching would otherwise let this file
#     pass while checking nothing.
#
# Nothing is executed from the tree: the files are read.
#
#   prove -l t/recommended-versions.t

use strict;
use warnings;

use Test::Most;
use File::Find ();
use File::Spec ();
use File::Temp qw(tempdir);

# ---------------------------------------------------------------------------
# What the distribution recommends, and at what version
# ---------------------------------------------------------------------------

# A floor of 0 or '' is no floor: 'Redis' => 0 says "nice to have", not "this
# version".  Everything else is a decimal version, compared as a number like
# the rest of the distribution compares them.
sub _floor {
	my ($value) = @_;

	return undef unless defined $value;

	# The value arrives as '0.12' from Makefile.PL, as 0.12 from cpanfile, and
	# with the trailing comma of the hash entry when it is the last one.
	$value =~ s/[^0-9._]//g;

	return undef if !length($value) || $value eq '0';

	return $value;
}

# The recommends blocks of META_MERGE, runtime and test alike.  Comments inside
# them carry the reason for a floor, so they are dropped before the keys are
# read.
sub _makefile_recommends {
	open my $fh, '<', 'Makefile.PL' or BAIL_OUT("cannot read Makefile.PL: $!");

	my %floor;
	my $in_block = 0;
	while (my $line = <$fh>) {
		chomp $line;

		if (!$in_block) {
			$in_block = 1 if $line =~ /^\s*recommends\s*=>\s*\{/;
			next;
		}

		if ($line =~ /^\s*\}\s*,?\s*$/) {
			$in_block = 0;
			next;
		}

		next if $line =~ /^\s*#/;
		$line =~ s/\s+#.*\z//;

		next unless $line =~ /^\s*'([\w:]+)'\s*=>\s*(\S+)/;
		$floor{$1} = _floor($2);
	}
	close $fh;

	return \%floor;
}

sub _cpanfile_recommends {
	open my $fh, '<', 'cpanfile' or BAIL_OUT("cannot read cpanfile: $!");

	my %floor;
	while (my $line = <$fh>) {
		next unless $line =~ /^\s*recommends\s+'([\w:]+)'(?:\s*,\s*'([^']*)')?\s*;/;
		$floor{$1} = _floor($2);
	}
	close $fh;

	return \%floor;
}

my $from_makefile = _makefile_recommends();
my $from_cpanfile = _cpanfile_recommends();

ok(scalar(keys %$from_makefile), 'Makefile.PL declares recommended modules')
	or BAIL_OUT('no recommends were parsed, so this file would check nothing');

is_deeply($from_cpanfile, $from_makefile,
	'cpanfile recommends the same modules at the same versions as Makefile.PL')
	or diag('a floor only one of the two files knows about is enforced nowhere');

# The floor this file is about: without it the rest of the checks are a scan
# of a set that could have lost its only interesting member.
is($from_makefile->{'HTML::OSM'}, 0.12,
	'HTML::OSM is recommended at 0.12, the version /map needs');
ok(!defined $from_makefile->{'HTML::D3'},
	'HTML::D3 is a hard prerequisite, so loading it needs no gate of its own');

my $minima = $from_makefile;

# ---------------------------------------------------------------------------
# Reading a test file
# ---------------------------------------------------------------------------

# POD and comments are dropped: a load or a gate that is commented out is not
# one, and a comment that mentions a version should not satisfy the check.  An
# inline comment is recognised by the whitespace before it, which is how they
# are written here and what keeps a '#' inside a quoted string - '#visual-0' in
# the browser tests - out of it.
sub _source_lines {
	my ($file) = @_;

	open my $fh, '<', $file or BAIL_OUT("cannot read $file: $!");
	my @raw = <$fh>;
	close $fh;
	chomp @raw;

	my @clean;
	my $in_pod = 0;
	for my $line (@raw) {
		if ($in_pod) {
			$in_pod = 0 if $line =~ /^=cut\b/;
			push @clean, '';
			next;
		}

		if ($line =~ /^=\w/) {
			$in_pod = 1 unless $line =~ /^=cut\b/;
			push @clean, '';
			next;
		}

		$line = '' if $line =~ /^\s*#/;
		$line =~ s/\s+#.*\z//;

		push @clean, $line;
	}

	return @clean;
}

# How deeply the text is inside braces, brackets and parentheses.  Approximate
# by design: it decides where a statement ends, and a probe written over
# several lines is the only thing it has to get right.
#
# Escapes and quoted strings come out first.  A regex may hold an escaped
# bracket - \( and \[ are common - and a message may hold one of its own; counted
# as structure they would leave every statement after them open to the end of
# the file, which is how a checker silently stops checking.
sub _depth {
	my ($text) = @_;

	$text =~ s/\\.//gs;
	$text =~ s/'(?:[^'])*'//gs;
	$text =~ s/"(?:[^"]*)"//gs;

	my $opens  = () = $text =~ /[\{\(\[]/g;
	my $closes = () = $text =~ /[\}\)\]]/g;

	return $opens - $closes;
}

# The file, split into statements, each with the lines it spans.  A statement
# runs on until what it opened is closed and a semicolon has been seen, and a
# closing brace on its own ends one, so a probe written over several lines is a
# single statement whether the load comes first or last in it.  Splitting the
# file once, rather than walking forward from each load, is what makes the
# load's line and the gate's line the same statement.
sub _statements {
	my ($lines) = @_;

	my @statements;
	my ($text, $start) = ('', 0);
	for my $index (0 .. $#$lines) {
		if (!length $text) {
			$start = $index;
			$text  = $lines->[$index];
		} else {
			$text .= "\n" . $lines->[$index];
		}

		my $depth = _depth($text);
		next unless $depth <= 0 && ($text =~ /;/ || $text =~ /\}\s*\z/);

		push @statements, { start => $start, end => $index, text => $text };
		$text = '';
	}
	push @statements, { start => $start, end => $#$lines, text => $text } if length $text;

	return \@statements;
}

# Which statement each line is in, so a load can be handed the whole of it
# without the file being walked again.
sub _statement_by_line {
	my ($lines) = @_;

	my %text;
	for my $statement (@{ _statements($lines) }) {
		$text{$_} = $statement->{text} for $statement->{start} .. $statement->{end};
	}

	return \%text;
}

# The highest version a statement asks of the module, or undef when it asks
# nothing.  M->VERSION with no argument is "what is installed", which is the
# question this file exists to tell apart from "is it new enough".
sub _gated_version {
	my ($statement, $module) = @_;

	my $highest;
	while ($statement =~ /\Q$module\E\s*->\s*VERSION\s*\(\s*([0-9][0-9._]*)\s*\)/g) {
		$highest = $1 if !defined($highest) || $1 >= $highest;
	}

	return $highest;
}

# How a skip message says a module is not usable.  A message about something
# else - "already loaded", "has no method" - names the module without being
# about the version the test wants, and is not the subject of this check.
my $UNAVAILABLE_RE = qr/\b(?:
	not\s+installed | not\s+available | not\s+loadable | unavailable |
	missing | required | needed | too\s+old | or\s+later
)\b/ix;

# The versions a message names: a number with a fractional part, so a count of
# assertions ('4 tests skipped') cannot be read as one.  0.12 is a version;
# 10.12 and 0.120 are different ones, which is why the digits either side are
# checked as well.
sub _versions_named {
	my ($message) = @_;

	return $message =~ /(?<![\d.])(\d+\.\d+(?:\.\d+)*)(?![\d.])/g;
}

# Whether the message names a version that would satisfy the floor.  A message
# about a test that needs something newer than the floor counts too: it still
# tells the reader why the run was skipped.
sub _names_floor {
	my ($message, $needs) = @_;

	return scalar grep { $_ >= $needs } _versions_named($message);
}

# The message a skip or skip_all call is given, or undef when it is not a
# literal.  Only the message is checked, not the condition beside it: a version
# in a gate that fails says nothing to a reader of the skip, which is the point.
# The capture is the second group - the first is the quote that delimits it.
sub _skip_message {
	my ($statement) = @_;

	return $2 if $statement =~ /\bskip_all\s*=>\s*(['"])(.*?)\1/s;
	return $2 if $statement =~ /\bskip\s*\(?\s*(['"])(.*?)\1/s;

	return undef;
}

# Every place a file skips because a recommended module cannot be used.  The
# message is the only thing a reader of a skipped run sees, so it is where the
# floor has to be written down.
sub _skip_messages {
	my ($file, $lines, $minima) = @_;

	my $statement_of = _statement_by_line($lines);

	my @skips;
	for my $index (0 .. $#$lines) {
		next unless $lines->[$index] =~ /\b(?:skip_all|skip)\b/;

		my $message = _skip_message($statement_of->{$index});
		next unless defined $message;

		for my $module (sort keys %$minima) {
			my $needs = $minima->{$module};
			next unless defined $needs;
			next unless $message =~ /\Q$module\E/;
			next unless $message =~ $UNAVAILABLE_RE;

			push @skips, {
				file    => $file,
				line    => $index + 1,
				module  => $module,
				needs   => $needs,
				message => $message,
				names   => _names_floor($message, $needs),
			};
		}
	}

	return @skips;
}

# ---------------------------------------------------------------------------
# The application's own messages
# ---------------------------------------------------------------------------
#
# A skipping test is not the only reader who needs the number.  The application
# reports a missing or too-old optional module too, and that sentence is what an
# operator acts on: "Drawing a map needs HTML::OSM 0.12 or later, but the
# installed HTML::OSM is 0.11" says what to install, and "your HTML::OSM is out
# of date" does not.  Those sentences live in lib/, and they are held to the same
# floor as the tests.
#
# The number can be written into the string or interpolated from a variable the
# same file declares; both are read.  A template that leaves it to a placeholder
# the caller fills in is read through the file's floor constant, which is where
# the caller's default comes from.  That is not proof that the placeholder is
# given it - this file reads text, not data flow - but it does mean the number a
# user is shown is one this file has checked, and that a message with no version
# anywhere is caught.
#
# The check the message reports is a second thing to hold to the floor: an
# application that accepts HTML::OSM 0.10 reports nothing at all on a machine
# with 0.11, and the message then names a version the distribution does not
# recommend.  So M->VERSION(x) is read too, and x has to resolve to a version at
# the floor - written into the call, or through a variable the file declares, or
# through the file's own floor constant when the argument is an expression this
# check cannot follow.

# The versions a file declares, by variable name, so "$MIN_FOO or later" can be
# read as the 0.12 it is.
sub _declared_versions {
	my ($lines) = @_;

	my %version;
	for my $line (@$lines) {
		while ($line =~ /\b(?:Readonly\s+)?(?:my|our)\s+\$(\w+)\s*(?:=>|=)\s*['"]?(\d+\.\d+(?:\.\d+)*)['"]?/g) {
			$version{$1} = $2;
		}
		while ($line =~ /\buse\s+constant\s+(\w+)\s*=>\s*['"]?(\d+\.\d+(?:\.\d+)*)['"]?/g) {
			$version{$1} = $2;
		}
	}

	return \%version;
}

# Every single-line quoted string in the file, with the line it is on.  A
# message is written that way here; a literal split over several lines is not
# read.
sub _strings {
	my ($lines) = @_;

	my @strings;
	for my $index (0 .. $#$lines) {
		my $line = $lines->[$index];
		while ($line =~ /'((?:[^'\\]|\\.)*)'/g) {
			push @strings, { line => $index + 1, text => $1 };
		}
		while ($line =~ /"((?:[^"\\]|\\.)*)"/g) {
			push @strings, { line => $index + 1, text => $1 };
		}
	}

	return @strings;
}

# The versions a message names: written into it, or interpolated from a variable
# the file declares with one.
sub _message_versions {
	my ($text, $declared) = @_;

	my @versions = _versions_named($text);
	while ($text =~ /\$\{(\w+)\}|\$(\w+)/g) {
		my $name = defined $1 ? $1 : $2;
		push @versions, $declared->{$name} if defined $declared->{$name};
	}

	return @versions;
}

# Every string in the file that reports a recommended module as missing or too
# old, and the highest version it names.
sub _app_messages {
	my ($file, $lines, $minima) = @_;

	my $declared = _declared_versions($lines);

	my @messages;
	for my $string (_strings($lines)) {
		for my $module (sort keys %$minima) {
			my $needs = $minima->{$module};
			next unless defined $needs;
			next unless $string->{text} =~ /\Q$module\E/;
			next unless $string->{text} =~ $UNAVAILABLE_RE;

			my @versions = sort { $b <=> $a }
				_message_versions($string->{text}, $declared);

			push @messages, {
				file        => $file,
				line        => $string->{line},
				module      => $module,
				needs       => $needs,
				text        => $string->{text},
				named       => @versions ? $versions[0] : undef,
				placeholder => $string->{text} =~ /%(?:s|d)/ ? 1 : 0,
				declared    => $declared,
			};
		}
	}

	return @messages;
}

# Every place the application asks a module for a version.  VERSION() with no
# argument asks what is installed, which is not a floor, and is not read.
sub _runtime_gates {
	my ($file, $lines, $minima) = @_;

	my $declared = _declared_versions($lines);

	my @gates;
	for my $index (0 .. $#$lines) {
		for my $module (sort keys %$minima) {
			my $needs = $minima->{$module};
			next unless defined $needs;

			while ($lines->[$index] =~ /\Q$module\E\s*->\s*VERSION\s*\(\s*([^)]+?)\s*\)/g) {
				my $argument = $1;

				my ($asks, $through);
				if ($argument =~ /\A['"]?(\d+\.\d+(?:\.\d+)*)['"]?\z/) {
					$asks = $1;
				} elsif ($argument =~ /\A\$(\w+)\z/ && defined $declared->{$1}) {
					$asks    = $declared->{$1};
					$through = "\$$1";
				}

				push @gates, {
					file     => $file,
					line     => $index + 1,
					module   => $module,
					needs    => $needs,
					argument => $argument,
					asks     => $asks,
					through  => $through,
					declared => $declared,
				};
			}
		}
	}

	return @gates;
}

# The number a file's floor constant holds, when it has exactly one.  The
# convention the tree already follows is one $MIN_*VERSION for the module a file
# checks.  Two of them is ambiguous and answers nothing rather than guessing
# which module one belongs to.
sub _floor_constant_version {
	my ($declared) = @_;

	my @names = sort grep { /MIN/i && /VERSION/i } keys %{ $declared };
	return undef unless @names == 1;

	return $declared->{ $names[0] };
}

# The version a gate enforces.  A call whose argument the file does not make
# readable is read through the file's floor constant.
sub _gate_floor {
	my ($gate) = @_;

	return $gate->{asks} if defined $gate->{asks};

	return _floor_constant_version($gate->{declared});
}

# The version a message says the module needs: the one it names, or the one its
# file's floor constant holds when the number is left to a placeholder.  Nothing
# when neither can be read.
sub _message_floor {
	my ($message) = @_;

	return $message->{named} if defined $message->{named};
	return undef unless $message->{placeholder};

	return _floor_constant_version($message->{declared});
}

# Every place a file loads a recommended module.  The module name has to end
# there: HTML::OSM::Extra is a different module.
sub _recommended_loads {
	my ($file, $lines, $minima) = @_;

	my $statement_of = _statement_by_line($lines);

	my @loads;
	for my $index (0 .. $#$lines) {
		for my $module (sort keys %$minima) {
			next unless $lines->[$index] =~ /\b(?:require|use)\s+\Q$module\E\b(?![\w:])/;

			my $statement = $statement_of->{$index};
			push @loads, {
				file  => $file,
				line  => $index + 1,
				module => $module,
				needs => $minima->{$module},
				gated => _gated_version($statement, $module),
			};
		}
	}

	return @loads;
}

sub _is_gated {
	my ($load) = @_;

	return 1 unless defined $load->{needs};
	return 0 unless defined $load->{gated};

	return $load->{gated} >= $load->{needs} ? 1 : 0;
}

# The version a Test::Needs spec asks for, or undef when it asks for none.  Both
# forms the module accepts are read: { 'M' => '1.2' } and { 'M' => 0 } are a hash
# entry, and 'M' on its own in the bare list cannot carry a version at all.
sub _spec_version {
	my ($statement, $module) = @_;

	return $1
		if $statement =~ /['"]?\Q$module\E['"]?\s*=>\s*['"]?([0-9][0-9._]*)/;

	return undef;
}

sub _spec_is_floor {
	my ($spec) = @_;

	return 0 unless defined $spec->{specifies};

	return $spec->{specifies} >= $spec->{needs} ? 1 : 0;
}

# Test::Needs is the other place a test declares what it needs, and it is read
# the same way: the statement that mentions it, and the recommended modules in
# it.  A spec for a module that is a hard prerequisite is not this file's
# business.
sub _recommended_specs {
	my ($file, $lines, $minima) = @_;

	my $statement_of = _statement_by_line($lines);

	my @specs;
	for my $index (0 .. $#$lines) {
		next unless $lines->[$index] =~ /\bTest::Needs\b/;

		my $statement = $statement_of->{$index};
		for my $module (sort keys %$minima) {
			next unless $statement =~ /['"]?\Q$module\E['"]?/;

			push @specs, {
				file      => $file,
				line      => $index + 1,
				module    => $module,
				needs     => $minima->{$module},
				specifies => _spec_version($statement, $module),
			};
		}
	}

	return @specs;
}

# A recommended module a test hides, rather than loads, has no version to name:
# hiding it is how the "not installed" branch is reached.  It is collected so the
# run says which declaration forms were looked at.
sub _hidden_modules {
	my ($file, $lines, $minima) = @_;

	my $statement_of = _statement_by_line($lines);

	my @hidden;
	for my $index (0 .. $#$lines) {
		next unless $lines->[$index] =~ /\bTest::Without::Module\b/;

		my $statement = $statement_of->{$index};
		for my $module (sort keys %$minima) {
			next unless $statement =~ /['"]?\Q$module\E['"]?/;

			push @hidden, { file => $file, line => $index + 1, module => $module };
		}
	}

	return @hidden;
}

# ---------------------------------------------------------------------------
# The checker, on files it writes
# ---------------------------------------------------------------------------

# Probe sources interpolate the module name, so this file contains no load of
# its own for the real scan below to find and complain about.
sub _write_probe {
	my ($source) = @_;

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'probe.t');
	open my $fh, '>', $file or BAIL_OUT("cannot write $file: $!");
	print {$fh} $source;
	close $fh;

	return $file;
}

sub _probe_loads {
	my ($source) = @_;

	my $file  = _write_probe($source);
	my @lines = _source_lines($file);

	return _recommended_loads('probe.t', \@lines, $minima);
}

sub _probe_specs {
	my ($source) = @_;

	my $file  = _write_probe($source);
	my @lines = _source_lines($file);

	return _recommended_specs('probe.t', \@lines, $minima);
}

sub _probe_hidden {
	my ($source) = @_;

	my $file  = _write_probe($source);
	my @lines = _source_lines($file);

	return _hidden_modules('probe.t', \@lines, $minima);
}

sub _probe_skips {
	my ($source) = @_;

	my $file  = _write_probe($source);
	my @lines = _source_lines($file);

	return _skip_messages('probe.t', \@lines, $minima);
}

sub _probe_gates {
	my ($source) = @_;

	my $file  = _write_probe($source);
	my @lines = _source_lines($file);

	return _runtime_gates('probe.pm', \@lines, $minima);
}

sub _probe_messages {
	my ($source) = @_;

	my $file  = _write_probe($source);
	my @lines = _source_lines($file);

	return _app_messages('probe.pm', \@lines, $minima);
}

my $gated_module = 'HTML::OSM';
my $gated_floor  = $minima->{$gated_module};

subtest 'the checker rejects what it is meant to reject' => sub {
	my @bare = _probe_loads("my \$ok = eval { require $gated_module; 1 };\n");
	is(scalar @bare, 1, 'a bare load is seen');
	ok(!_is_gated($bare[0]), 'and rejected, because it only asks whether the module is there');
	like($bare[0]->{module}, qr/\A\Q$gated_module\E\z/, 'and named');
	is($bare[0]->{line}, 1, 'with the line it is on');

	my $below = '0.01';
	my @low = _probe_loads(
		"my \$ok = eval { require $gated_module; $gated_module->VERSION($below); 1 };\n"
	);
	is(scalar @low, 1, 'a gate below the floor is seen');
	ok(!_is_gated($low[0]), 'and rejected, because naming a version is not the same as naming the one needed');

	my @uses = _probe_loads("use $gated_module;\nmy \$map = $gated_module->new;\n");
	is(scalar @uses, 1, 'a load by use is seen too');
	ok(!_is_gated($uses[0]), 'and needs the same gate');
};

subtest 'the checker accepts what it is meant to accept' => sub {
	my @gated = _probe_loads(
		"my \$ok = eval { require $gated_module; $gated_module->VERSION($gated_floor); 1 };\n"
	);
	is(scalar @gated, 1, 'a gated load is seen');
	ok(_is_gated($gated[0]), 'and accepted');

	my $above = '99.0';
	my @newer = _probe_loads(
		"my \$ok = eval { require $gated_module; $gated_module->VERSION($above); 1 };\n"
	);
	ok(_is_gated($newer[0]), 'a gate above the floor is accepted as well');

	my $spread = "my \$ok = eval {\n"
		. "\trequire $gated_module;\n"
		. "\t$gated_module->VERSION($gated_floor);\n"
		. "\t1;\n"
		. "};\n";
	my @multi = _probe_loads($spread);
	is(scalar @multi, 1, 'a probe written over several lines is one load');
	ok(_is_gated($multi[0]), 'and its gate counts even on another line');

	my @hard = _probe_loads("my \$ok = eval { require HTML::D3; 1 };\n");
	is(scalar @hard, 0, 'a module that is a hard prerequisite is not this file\'s business');

	my @commented = _probe_loads(
		"# my \$ok = eval { require $gated_module; 1 };\n"
		. "my \$ok = eval { require $gated_module; $gated_module->VERSION($gated_floor); 1 };\n"
	);
	is(scalar @commented, 1, 'a commented-out load is not a load');
	ok(_is_gated($commented[0]), 'so it does not need a gate of its own');
};

subtest 'the checker reads the other ways a test declares an optional module' => sub {
	my @pinned = _probe_specs("use Test::Needs { '$gated_module' => '$gated_floor' };\n");
	is(scalar @pinned, 1, 'a Test::Needs spec is seen');
	ok(_spec_is_floor($pinned[0]), 'and accepted when it names the floor');

	my $below = '0.01';
	my @low = _probe_specs("use Test::Needs { '$gated_module' => '$below' };\n");
	is(scalar @low, 1, 'a spec below the floor is seen');
	ok(!_spec_is_floor($low[0]), 'and rejected, because it would run against the old copy too');

	my @unversioned = _probe_specs("use Test::Needs { '$gated_module' => 0 };\n");
	is(scalar @unversioned, 1, 'a spec that asks for any version is seen');
	ok(!_spec_is_floor($unversioned[0]), 'and rejected: Test::Needs would skip only a machine with no copy at all');

	my @listed = _probe_specs("use Test::Needs '$gated_module';\n");
	is(scalar @listed, 1, 'the bare list form is seen');
	ok(!_spec_is_floor($listed[0]), 'and cannot name a version, so it is rejected too');

	my $spread = "use Test::Needs {\n\t'$gated_module' => '$gated_floor'\n};\n";
	my @multi = _probe_specs($spread);
	is(scalar @multi, 1, 'a spec written over several lines is one spec');
	ok(_spec_is_floor($multi[0]), 'and its version counts');

	my @hard = _probe_specs("use Test::Needs { 'Test::CheckManifest' => '0.9' };\n");
	is(scalar @hard, 0, 'a spec for a hard prerequisite is not this file\'s business');

	my @hidden = _probe_hidden("Test::Without::Module->import('$gated_module');\n");
	is(scalar @hidden, 1, 'a module hidden rather than loaded is seen');
	is($hidden[0]->{module}, $gated_module, 'and named, so the run says the form was looked at');
};

subtest 'the checker reads the version an application message and check name' => sub {
	my @named = _probe_messages(
		"my \$why = 'Drawing a map needs $gated_module $gated_floor or later';\n"
	);
	is(scalar @named, 1, 'a message about a recommended module is seen');
	is($named[0]->{named}, $gated_floor, 'and the floor it names is read');
	is($named[0]->{line}, 1, 'with the line it is on');

	my @bare = _probe_messages("my \$why = '$gated_module is not installed';\n");
	is(scalar @bare, 1, 'a message without a version is seen too');
	is($bare[0]->{named}, undef, 'and names nothing, so it is rejected');

	my $below = '0.01';
	my @low = _probe_messages("my \$why = '$gated_module $below is too old';\n");
	is($low[0]->{named}, $below, 'a version below the floor is read, and rejected by the check beside it');

	my @constant = _probe_messages(
		"Readonly my \$MIN_VERSION => '$gated_floor';\n"
		. "my \$why = \"needs $gated_module \$MIN_VERSION or later\";\n"
	);
	is(scalar @constant, 1, 'a message that interpolates the floor is seen');
	is($constant[0]->{named}, $gated_floor, 'and the value of the variable is what it names');

	my @template = _probe_messages(
		"Readonly my \$MIN_VERSION => '$gated_floor';\n"
		. "my \$why = 'needs $gated_module %s or later, and %s';\n"
	);
	is(_message_floor($template[0]), $gated_floor,
		'a template that leaves the number to a placeholder is read through the floor constant');

	my @templated = _probe_messages("my \$why = 'needs $gated_module %s or later';\n");
	is(_message_floor($templated[0]), undef,
		'and without a floor constant there is nothing to read, so it is rejected');

	my @low_constant = _probe_messages(
		"Readonly my \$MIN_VERSION => '$below';\n"
		. "my \$why = 'needs $gated_module %s or later';\n"
	);
	is(_message_floor($low_constant[0]), $below,
		'a constant below the floor is read as what it holds, and rejected by the check beside it');

	my @unrelated = _probe_messages("my \$why = 'the table could not be opened';\n");
	is(scalar @unrelated, 0, 'a message about something else is not this file\'s business');

	my @pinged = _probe_messages(
		"my \$why = '$gated_module loaded; the options are not read';\n"
	);
	is(scalar @pinged, 0, 'nor is one that says the module is there');

	my @literal = _probe_gates(
		"my \$ok = eval { require $gated_module; $gated_module->VERSION($gated_floor); 1 };\n"
	);
	is(scalar @literal, 1, 'a version check is seen');
	is(_gate_floor($literal[0]), $gated_floor, 'and the version written into it is read');

	my @low_gate = _probe_gates(
		"my \$ok = eval { require $gated_module; $gated_module->VERSION($below); 1 };\n"
	);
	is(_gate_floor($low_gate[0]), $below, 'a check that asks for less is read as what it asks for');

	my @through = _probe_gates(
		"Readonly my \$MIN_VERSION => '$gated_floor';\n"
		. "my \$ok = eval { require $gated_module; $gated_module->VERSION(\$MIN_VERSION); 1 };\n"
	);
	is(_gate_floor($through[0]), $gated_floor, 'a check through a declared variable is read too');

	my @opaque = _probe_gates(
		"my \$ok = eval { require $gated_module; $gated_module->VERSION(\$self->{'min'}); 1 };\n"
	);
	is(_gate_floor($opaque[0]), undef,
		'a check through an expression the file does not make readable answers nothing');

	my @answered = _probe_gates(
		"Readonly my \$MIN_VERSION => '$gated_floor';\n"
		. "my \$ok = eval { require $gated_module; $gated_module->VERSION(\$self->{'min'}); 1 };\n"
	);
	is(_gate_floor($answered[0]), $gated_floor,
		'and is read through the file\'s floor constant, which is what names it');

	my @ambiguous = _probe_gates(
		"Readonly my \$MIN_VERSION => '$gated_floor';\n"
		. "Readonly my \$MIN_OTHER_VERSION => '$gated_floor';\n"
		. "my \$ok = eval { require $gated_module; $gated_module->VERSION(\$self->{'min'}); 1 };\n"
	);
	is(_gate_floor($ambiguous[0]), undef,
		'two floor constants are ambiguous, so neither is assumed to be the one');

	my @installed = _probe_gates("my \$ok = eval { require $gated_module; $gated_module->VERSION; 1 };\n");
	is(scalar @installed, 0, 'and asking for whatever is installed is not a version check');
};

subtest 'the checker reads what a skip says about a recommended module' => sub {
	my @named = _probe_skips(
		"plan skip_all => '$gated_module $gated_floor or later is needed to draw a map';\n"
	);
	is(scalar @named, 1, 'a skip message about a recommended module is seen');
	ok($named[0]->{names}, 'and accepted when it names the floor');
	is($named[0]->{module}, $gated_module, 'with the module named');
	is($named[0]->{line}, 1, 'and the line it is on');

	# The message, not the quote that delimits it.  Reading $1 instead of $2
	# would hand every check a single character, and every probe would pass.
	like($named[0]->{message}, qr/\A\Q$gated_module\E /,
		'and the text of the message rather than its opening quote');

	my @bare = _probe_skips(
		"\tskip '$gated_module is not installed here', 4;\n"
	);
	is(scalar @bare, 1, 'a message that names the module without its version is seen');
	ok(!$bare[0]->{names}, 'and rejected: a reader cannot tell 0.11 from no copy at all');

	my @newer = _probe_skips(
		"\tskip '$gated_module 99.0 is needed for this', 1;\n"
	);
	ok($newer[0]->{names}, 'a message asking for more than the floor is accepted');

	my @old = _probe_skips(
		"\tskip '$gated_module 0.01 is missing', 1;\n"
	);
	ok(!$old[0]->{names}, 'a floor below the one needed is not accepted');

	my @count = _probe_skips(
		"\tskip '$gated_module is not installed here', 4;\n"
	);
	ok(!$count[0]->{names}, 'the number of skipped assertions is not read as a version');

	my @ungated = _probe_skips(
		"\tskip '$gated_module is missing', 1 unless \$have;\n"
	);
	is(scalar @ungated, 1, 'the condition beside the message is not part of what is checked');

	my @loaded = _probe_skips(
		"plan skip_all => '$gated_module already loaded; cannot simulate absence';\n"
	);
	is(scalar @loaded, 0, 'a skip about something other than the module\'s version is left alone');

	my @variable = _probe_skips("\tmy \$why = '$gated_module is missing';\n\tskip \$why, 1;\n");
	is(scalar @variable, 0, 'a message held in a variable is not read');
};

# ---------------------------------------------------------------------------
# The tests in the tree
# ---------------------------------------------------------------------------

sub _test_files {
	my @files;
	File::Find::find({
		no_chdir => 1,
		wanted   => sub {
			my $file = $File::Find::name;
			return unless -f $file;
			push @files, $file if $file =~ /\.t\z/ || $file =~ m{\At/lib/.*\.pm\z};
		},
	}, 't');

	return sort @files;
}

my @files = _test_files();
cmp_ok(scalar @files, '>', 20, 'the scan found the test suite')
	or BAIL_OUT('the file scan found almost nothing, so it is not testing anything');

my (@loads, @specs, @hidden, @skips);
for my $file (@files) {
	my @lines = _source_lines($file);
	push @loads,  _recommended_loads($file, \@lines, $minima);
	push @specs,  _recommended_specs($file, \@lines, $minima);
	push @hidden, _hidden_modules($file, \@lines, $minima);
	push @skips,  _skip_messages($file, \@lines, $minima);
}

cmp_ok(scalar @loads, '>', 5, 'the scan found the loads of recommended modules')
	or BAIL_OUT('no recommended module is loaded anywhere, so the scan proves nothing');

ok(scalar(grep { defined $_->{needs} } @loads),
	'and some of them are loads of a module with a version floor');

for my $load (@loads) {
	my $where  = "$load->{file} line $load->{line}";
	my $module = $load->{module};
	my $needs  = $load->{needs};

	if (!defined $needs) {
		pass("$where loads $module, which declares no version, so there is none to name");
		next;
	}

	ok(_is_gated($load), "$where checks that $module is $needs or later")
		or diag(sprintf(
			"%s loads %s without checking the version it needs.\n"
			. "Installed is not the same as new enough: the application asks for %s,\n"
			. "and on a machine with an older copy every assertion about the result\n"
			. "fails for a reason the test cannot see.  Gate the load, in the same\n"
			. "statement, and skip below the floor:\n"
			. "    eval { require %s; %s->VERSION(%s); 1 }",
			$where, $module, $needs, $module, $module, $needs,
		));
}

cmp_ok(scalar @specs, '>', 0, 'the scan found Test::Needs specs for recommended modules')
	or BAIL_OUT('no spec was found, so the Test::Needs half of this file checks nothing');

for my $spec (@specs) {
	my $where  = "$spec->{file} line $spec->{line}";
	my $module = $spec->{module};
	my $needs  = $spec->{needs};

	ok(_spec_is_floor($spec), "$where asks Test::Needs for $module $needs or later")
		or diag(sprintf(
			"%s names %s without the version it needs.\n"
			. "Test::Needs skips a machine that has no copy; with no version in the\n"
			. "spec it accepts any copy there is, so a machine with an older one runs\n"
			. "the test and fails for a reason the spec was meant to stop.  Declare\n"
			. "the floor:\n"
			. "    use Test::Needs { '%s' => '%s' }",
			$where, $module, $module, $needs,
		));
}

for my $hidden (@hidden) {
	pass("$hidden->{file} line $hidden->{line} hides $hidden->{module}, so there is no version to name");
}

cmp_ok(scalar @skips, '>', 0,
	'the scan found skip messages about recommended modules')
	or BAIL_OUT('no skip message mentions a recommended module, so that check proves nothing');

for my $skip (@skips) {
	my $where = "$skip->{file} line $skip->{line}";

	ok($skip->{names}, "$where says which version of $skip->{module} it needed")
		or diag(sprintf(
			"%s skips because %s cannot be used, but the message does not say\n"
			. "which version it needed:\n"
			. "    %s\n"
			. "A skipped run is all most readers see of this test, and this message\n"
			. "reads the same on a machine with 0.11 on it as on one with no copy\n"
			. "at all.  Name the floor:\n"
			. "    skip '%s %s is not installed here', \$tests;",
			$where, $skip->{module}, $skip->{message},
			$skip->{module}, $skip->{needs},
		));
}

# ---------------------------------------------------------------------------
# The application
# ---------------------------------------------------------------------------
#
# The same floor, in the code an operator runs rather than the tests: the check
# that decides whether the module is usable, and the sentence a user is given
# when it is not.
sub _lib_files {
	my @files;
	File::Find::find({
		no_chdir => 1,
		wanted   => sub {
			my $file = $File::Find::name;
			push @files, $file if -f $file && $file =~ /\.pm\z/;
		},
	}, 'lib');

	return sort @files;
}

my @lib_files = _lib_files();
cmp_ok(scalar @lib_files, '>', 10, 'the scan found the application')
	or BAIL_OUT('the scan found almost no modules, so the checks below prove nothing');

my (@gates, @messages);
for my $file (@lib_files) {
	my @lines = _source_lines($file);
	push @gates,    _runtime_gates($file, \@lines, $minima);
	push @messages, _app_messages($file, \@lines, $minima);
}

for my $module (sort grep { defined $minima->{$_} } keys %$minima) {
	my $needs = $minima->{$module};

	ok(scalar(grep { $_->{module} eq $module } @gates),
		"the application checks which $module it has")
		or diag("no $module->VERSION(...) call was found in lib/, so the floor $needs is enforced nowhere");

	ok(scalar(grep { $_->{module} eq $module } @messages),
		"and has a message for a $module that is missing or too old")
		or diag("no message about $module was found in lib/, so a user with the wrong version is told nothing");
}

# What each file's own check asks for, so a message can be held to it as well as
# to the floor: a message that names a version the check would not accept sends
# the operator round the same loop twice.
my %asks;
for my $gate (@gates) {
	next unless defined $gate->{asks};

	my $key = "$gate->{file}\0$gate->{module}";
	$asks{$key} = $gate->{asks}
		if !defined $asks{$key} || $gate->{asks} > $asks{$key};
}

for my $gate (@gates) {
	my $where  = "$gate->{file} line $gate->{line}";
	my $module = $gate->{module};
	my $needs  = $gate->{needs};
	my $floor  = _gate_floor($gate);

	# What the diag says the check asks for: the number written into it, the one
	# its floor constant holds, or nothing when neither can be read.
	my $asking = defined $gate->{asks}  ? $gate->{asks}
		: defined $floor                ? "$floor, from the file's floor constant"
		:                                 'a version this file does not make readable';

	ok(defined $floor && $floor >= $needs,
		"$where checks $module at the $needs the distribution recommends")
		or diag(sprintf(
			"%s asks %s for %s, but the distribution recommends %s.\n"
			. "A machine with the older version gets an application that starts and\n"
			. "then meets the feature that needs the newer one - the same split the\n"
			. "tests had, on the other side.  Ask for the version Makefile.PL\n"
			. "recommends, and name it in a \$MIN_*VERSION constant if the call cannot\n"
			. "show it:",
			$where, $module, $asking, $needs,
		));
}

for my $message (@messages) {
	my $where  = "$message->{file} line $message->{line}";
	my $module = $message->{module};
	my $needs  = $message->{needs};

	my $key  = "$message->{file}\0$module";
	my $want = defined $asks{$key} && $asks{$key} > $needs ? $asks{$key} : $needs;
	my $says = _message_floor($message);

	ok(defined $says && $says >= $want,
		"$where says which $module version it needs")
		or diag(sprintf(
			"%s reports %s as missing or too old, but the message does not say %s\n"
			. "or later:\n"
			. "    %s\n"
			. "The sentence is what an operator acts on, so it has to name the version\n"
			. "the application accepts - the floor, or the constant the check uses,\n"
			. "interpolated into the template - rather than leaving it out or naming an\n"
			. "older one:",
			$where, $module, $want, $message->{text},
		));
}

done_testing();
