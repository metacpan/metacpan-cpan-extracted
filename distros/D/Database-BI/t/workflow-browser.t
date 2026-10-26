#!/usr/bin/env perl

# The renderer job is the only CI run in which the map's drawing assertions are
# exercised rather than skipped: it installs HTML::OSM 0.12 and runs the three
# files that draw.  Nothing else notices if that list is narrowed.  The files
# dropped from it still pass when run on their own, the absent-renderer jobs run
# different ones, and the keyboard job's glob reaches t/browser-map-panel.t and
# t/browser-seed-canvas.t but not t/browser-map-page-renderer.t, whose
# usable-renderer control skips itself wherever the module is missing.  So
# dropping a file from that step - or commenting one out while tidying the
# explanation around it - would leave every job green while GET /map stopped
# being drawn anywhere in CI.
#
# What is checked is what the job runs, not what it mentions: the files are read
# out of the command lines in the renderer job's own block, comments removed
# first, so a file that survives only in the prose above the prove line no
# longer counts.  The parsers are run over workflows this test writes first, and
# over a copy of the real one with a file taken out, so a pattern that had
# stopped matching - or a check that could no longer fail - fails here instead
# of finding nothing to complain about.
#
# .github is not in the MANIFEST, so an installed copy of this distribution has
# no workflow to read: there the file says so and skips.  This checks CI, not
# the module.
#
#   prove -l t/workflow-browser.t

use strict;
use warnings;

use Test::Most;

my $WORKFLOW = '.github/workflows/browser.yml';

# The three files the job exists for, and why each one is there.  A fourth file
# would not need an entry here - the job running more than these three is not
# what this guards against - but dropping one of them is.
my @REQUIRED = (
	[ 't/browser-map-page-renderer.t',
		'the page: GET /map in both degraded states and in the control the absent-renderer jobs never reach' ],
	[ 't/browser-map-panel.t',
		'the table\'s Map panel, the page it opens and a canvas it saves and edits' ],
	[ 't/browser-seed-canvas.t',
		'a canvas made from every chart route, so the map card is drawn where a user creates one' ],
);

sub _slurp {
	my ($file) = @_;

	open(my $fh, '<', $file) or return;
	local $/;
	my $text = <$fh>;
	close($fh);

	# Normalised, because the indentation checks below are anchored to the end
	# of a line and a checkout that kept CRLF would put the \r inside the
	# match: the job would then look absent and this file would say so.
	$text =~ s/\r\n/\n/g;

	return $text;
}

# One job from `jobs:`, up to the next job or the next top-level key.  Scoped by
# indentation because that is what a job is: the job name two spaces in, its
# keys four or more, the next job back at two.  The name has to match from the
# start of the line as well as to the end of it, because `no-renderer:` is not
# `renderer:` and the absent-renderer job comes first in the file.
sub _job_block {
	my ($text, $job) = @_;

	my @lines = split /\n/, $text;

	my ($start) = grep { $lines[$_] =~ /\A  \Q$job\E:[ \t]*\z/ } 0 .. $#lines;
	return unless defined $start;

	my @block;
	for my $i ($start + 1 .. $#lines) {
		last if $lines[$i] =~ /\A\S/;		# a top-level key, e.g. the next section
		last if $lines[$i] =~ /\A  \S/;		# the next job
		push @block, $lines[$i];
	}

	return @block;
}

# The test files a job's commands run.  Comments go before anything else is
# read, because the explanation above a prove line names the same files; and a
# command that outgrew the line length is joined back together, because a
# continuation is not a second command.
sub _run_files {
	my @lines = @_;

	my (@files, $command);
	$command = '';

	for my $line (@lines) {
		next if $line =~ /\A[ \t]*#/;

		if ($line =~ s/\\[ \t]*\z//) {
			$command .= ' ' . $line;
			next;
		}

		$command .= ' ' . $line;
		push @files, _files_in($command);
		$command = '';
	}

	push @files, _files_in($command) if length $command;

	return @files;
}

# The files in one command - only if that command is a test runner.  A file that
# is echoed, grepped for or written to is named by the step but not run by it.
sub _files_in {
	my ($command) = @_;

	return unless $command =~ /\b(?:prove|yath)\b/;

	return ($command =~ /\bt\/[\w.\/-]+\.t\b/g);
}

# Which of the three a job has stopped running.
sub _missing_files {
	my @lines = @_;

	my %run = map { $_ => 1 } _run_files(@lines);

	return [ map { $_->[0] } grep { !$run{ $_->[0] } } @REQUIRED ];
}

# An installed copy of this distribution has no .github, and then there is no
# workflow to guard.  Said before anything is run, so the file is a clean skip
# rather than a plan that changes halfway through.
my $TEXT = _slurp($WORKFLOW);

plan skip_all => "there is no $WORKFLOW here: .github is not part of the distribution"
	unless defined $TEXT;

# ---------------------------------------------------------------------------
# The parsers, over workflows written here, so that a pattern which stopped
# matching is a failure rather than an empty list that agrees with everything.
# ---------------------------------------------------------------------------

my $SAMPLE = <<'YAML';
jobs:
  no-renderer:
    steps:
      - name: Run
        run: |
          prove -l -v t/absent.t
  renderer:
    steps:
      - name: Run
        run: |
          prove -l -v t/one.t t/two.t \
            t/three.t 2>&1 | tee out.txt
  no-geocoder:
    steps:
      - name: Run
        run: |
          prove -l -v t/later.t
YAML

# sort is given the comparison explicitly: `sort some_sub(...)` names some_sub as
# the comparison, not as the list, and would call it with the wrong arguments.
is_deeply [ sort { $a cmp $b } _run_files(_job_block($SAMPLE, 'renderer')) ],
	[qw(t/one.t t/three.t t/two.t)],
	'a continued prove line is one command, and every file in it is found';

is_deeply [ sort { $a cmp $b } _run_files(_job_block($SAMPLE, 'no-renderer')) ], ['t/absent.t'],
	'the job block ends at the next job, so no job is credited with its neighbour\'s files';

my $MENTIONS = <<'YAML';
jobs:
  renderer:
    steps:
      - name: Run
        run: |
          # t/commented.t is named here only to explain the step
          echo t/echoed.t
          prove -l -v t/run.t
YAML

is_deeply [ sort { $a cmp $b } _run_files(_job_block($MENTIONS, 'renderer')) ], ['t/run.t'],
	'a file named in a comment, or echoed, is mentioned by the job and not run by it';

# ---------------------------------------------------------------------------
# The workflow this checkout has.
# ---------------------------------------------------------------------------

my @JOB = _job_block($TEXT, 'renderer');

ok scalar(@JOB), 'the workflow still has a renderer job';

my @RUN = _run_files(@JOB);
ok scalar(@RUN), 'the renderer job still runs test files rather than only describing them';

my %RUN = map { $_ => 1 } @RUN;

for my $required (@REQUIRED) {
	my ($file, $why) = @$required;

	ok $RUN{$file}, "the renderer job runs $file - $why";
}

# And each of those checks can fail: the same file with one of the three taken
# out has to be reported, or a green run here would mean nothing.  Every copy of
# the name goes, not just the first: the workflow names all three in the prose
# above the job as well, and a version that only lost the mention in a comment
# is a file the job still runs.
for my $required (@REQUIRED) {
	my $file = $required->[0];

	my $narrowed = $TEXT;
	$narrowed =~ s/\b\Q$file\E\b//g;

	is_deeply _missing_files(_job_block($narrowed, 'renderer')), [$file],
		"a copy of the workflow that stopped running $file is reported as missing it";
}

done_testing();
