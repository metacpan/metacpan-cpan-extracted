package Batch::Interpreter::TestSupport;

=head1 NAME

Batch::Interpreter::TestSupport - support code for testing Batch::Interpreter

=head1 SYNOPSIS

The output of runbat is compared with the output of CMD.EXE. On systems with CMD.EXE the batch files can be run with CMD.EXE to store the expected output. The switch --complete combines both steps.

=head1 METHODS

=cut

use v5.10;
use warnings;
use strict;
use parent 'Exporter';
our @EXPORT_OK = qw(
	get_test_attr compare_output
	read_file
);

our $VERSION = 0.01;

use Getopt::Long;
use Test::More;
use Test::Differences;
use Data::Dump qw(dump);
use File::Spec;
use File::Temp;
use Cwd;

=head2 ->get_test_attr()

Read C<@ARGV> to generate a C<$test_attr> HashRef, that is returned for (possibly modified) use in ->compare_output().

=cut
sub get_test_attr {
	my ($record, $compare, $complete);
	my $dump;
	my $verbose;
	my $help;
	GetOptions(
		'record' => \$record,
		'compare' => \$compare,
		'complete' => \$complete,
		'dump' => \$dump,
		'verbose!' => \$verbose,
		'help|h|?!' => \$help,
	);
	if ($help) {
		say <<"EOH";
usage: $0 [--record|--compare|--complete] [--dump] [--[no-]verbose] [--help|-h|-?] [-- <runbat arguments>]

	--record
		Run the test script with the system shell and store the	output.
		Only available under Win32.
	--compare
		Run the test script with runbat and compare the output.
		This is the default.
	--complete
		First --record, then --compare.

	--dump	Dump the outputs before comparison.

	--verbose
		Be verbose.

	--help
		This help.
EOH
		exit 1;
	}
	my $mode = $complete ? 'record,compare'
		: $record ? 'record'
		: 'compare';
	return {
		mode => $mode,
		dump => $dump,
		argv => [ @ARGV ],
		verbose => $verbose,
		number => 0,
	};
}

# TODO: use a prepackaged implementation
sub quote_argument {
	$_ = shift;
	s/([\\\"])/\\$1/gi;
	return /[\s\\\"]/ ? "\"$_\"" : $_;
}

# Some archivers may restore test files with the wrong newlines, so ship the
# files in hex and decode before use.
sub decode_file {
	my ($filename) = @_;
	my $hexname = "$filename.hex";
	if (-e $hexname && !-e $filename) {
		open my $in, '<', $hexname or die "$hexname: $!";
		open my $out, '>:raw', $filename or die "$filename: $!";
		local $/;
		print $out pack 'H*', <$in>;
		close $_ for $in, $out;

		# file may need some time to be visible on network filesystems
		while (!-e $filename) {
			say STDERR "Waiting for creation of $filename...";
			sleep 1;
		}
	}
}

=head2 read_file($filename)

Read C<$filename> in the same way as compare_output() reads it (including possible decoding) and return the content as a binary string.
=cut
sub read_file {
	my ($filename) = @_;
	decode_file $filename;
	open my $fh, '<:raw', $filename
		or die "open '$filename': $!";
	local $/;
	return scalar <$fh>;
}


sub filter_log {
	my ($type, $stream, $attr, $content) = @_;

	# system and emulated CMD may have different CWDs (virtual mount
	# points) and they may be differently slashed.
	# the tested program maps t/ to B:/test/, but we have to translate
	# the output of CMD.EXE, where at least the absolute paths are
	# easily matched
	$type eq 'cmd' and
		$content =~
			s([A-Za-z]\:[\\\/][^\:]*\bBatch-Interpreter.*[\\\/]t\b)
			(B:\\test)gm;

	$content =~ s/\r//g
		if $attr->{unix_nl};

	$content = $attr->{filter_log}->($type, $stream, $content)
		if $attr->{filter_log};

	return $content;
}

sub read_content {
	my ($fh) = @_;
	seek $fh, 0, SEEK_SET
		or die $!;
	binmode $fh;
	local $/;
	return scalar <$fh>;
}

sub store_content {
	my ($output, $content) = @_;

	if ('SCALAR' eq ref $output) {
		$$output = $content;
	} else {
		open my $out, '>:raw', $output;
		print $out $content;
	}
}

sub run_redirected {
	my ($type, $attr, @commandline) = @_;
	my $cmd = join ' ', map quote_argument($_), @commandline;

	say STDERR "COMMAND: $cmd"
		if $attr->{verbose};

	my ($old_stdout, $old_stderr);
	my ($stdout, $stderr);
	if ($attr->{stdout}) {
		$stdout = File::Temp->new();
		open $old_stdout, '>&', \*STDOUT;
		open \*STDOUT, '>&', $stdout;
	}
	if ($attr->{stderr}) {
		$stderr = File::Temp->new();
		open $old_stderr, '>&', \*STDERR;
		open \*STDERR, '>&', $stderr;
	}

	system $cmd;

	if ($stderr) {
		open \*STDERR, '>&', $old_stderr;
		store_content $attr->{stderr},
			filter_log $type, 'stderr', $attr,
				read_content $stderr;
	}
	if ($stdout) {
		open \*STDOUT, '>&', $old_stdout;
		store_content $attr->{stdout},
			filter_log $type, 'stdout', $attr,
				read_content $stdout;
	}

	return !($? & 127);
}

=head2 compare_output($test_attr, $subtest_name, @commandline)

Compare the output of running C<@commandline> with CMD.EXE and Batch::Interpreter.

C<$subtest_name> can be given as undef, in which case the subtests are simply numbered.

Attributes that can be added to C<$test_attr> are:

=over

=item verbose

Be verbose.

=item filter_log

A callback CodeRef, that is used to filter the output, which is called as

	$content = $attr->{filter_log}->($type, $stream, $content)

C<$type> can be 'cmd' or 'lib', C<$stream> can be 'stdout' or 'stderr'.

=item unix_nl

Normalize the data to unix newlines before comparison. Note 'before comparison' includes the point in time the CMD.EXE output is saved.

=item skip_stderr

Only STDOUT is compared, not STDERR.

=item in_dir

The command is run in the given directory.

=back

=cut
sub compare_output {
	my ($test_attr, $subtest_name, @commandline) = @_;

	my $runbat = 'bin/runbat';
	my $lib = 'lib';
	my $t = 't';

	my $olddir;
	if ($test_attr->{in_dir}) {
		$_ = File::Spec->rel2abs($_) for $runbat, $lib, $t;

		$olddir = getcwd;
		chdir $test_attr->{in_dir};
	}

	decode_file $_
		for @commandline;

	my $mode = $test_attr->{mode};

	my $basename = (File::Spec->splitpath($0))[2];
	#$basename =~ s/^\d+_//;
	$basename =~ s/\.t$//;

	$subtest_name //= sprintf '%02d', $test_attr->{number}++;

	my $base = join '_', $basename, $subtest_name;
	my $digest = "$base: @commandline"; 

	my @stream = qw(stdout stderr);
	$test_attr->{skip_stderr}
		and @stream = grep $_ ne 'stderr', @stream;

	my %attr = map +($_ => \(my $data)), @stream;
	my %cmd_attr = map +($_ => "$t/$base.cmd.$_"), @stream;

	if ($mode =~ /\brecord\b/) {
		$^O =~ /Win/ or die "record mode only possible under windows";

		# run with CMD
		my $ok = run_redirected('cmd', { %$test_attr, %cmd_attr },
			map { y/\//\\/; $_ } @commandline
		);
		# suppress tests for complete mode
		if ($mode eq 'record') {
			ok $ok, "record $digest";
			pass "no comparison: $digest";
		}
	}

	if ($mode =~ /\bcompare\b/) {
		ok run_redirected('lib', { %$test_attr, %attr },
			$^X, '-I', $lib,
			$runbat,
			'--mount', "B:/test=$t",
			@{$test_attr->{argv} // []},
			'--',
			@commandline
		), "run $digest";

		my %result = map +($_ => ${$attr{$_}}), @stream;
		my %cmd_result = map +($_ => read_file $cmd_attr{$_}), @stream;

		$test_attr->{dump} and
			dump [\%result, \%cmd_attr, \%cmd_result];

		eq_or_diff $result{$_}, $cmd_result{$_}, "result($_) $digest"
			for @stream;

		unlink @attr{@stream};
	}

	defined $olddir and chdir $olddir;
}

1;

__END__

=head1 AUTHOR

Ralf Neubauer, C<< <ralf at strcmp.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-batch-interpreter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Batch-Interpreter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Batch::Interpreter::TestSupport


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Batch-Interpreter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Batch-Interpreter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Batch-Interpreter>

=item * Search CPAN

L<http://search.cpan.org/dist/Batch-Interpreter/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ralf Neubauer.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

