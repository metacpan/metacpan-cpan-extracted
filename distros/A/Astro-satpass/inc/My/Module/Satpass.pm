package My::Module::Satpass;

use strict;
use warnings;

use Config;
use Cwd;
use File::Spec;
use Test;



#	We may need IO::String for the test. If we do, make sure it
#	is available. If it is not, skip everything.

my $gblskip = $] >= 5.008 && $Config{useperlio} ? '' :
    not_available ('IO::String');

#	We also need Date::Manip.

$gblskip ||= not_available ('Date::Manip');

#	We also need the actual script.

my $script = File::Spec->catfile (qw{bin satpass});
$gblskip ||= -e $script ? '' : 'Can not find satpass script.';


#	Initialize.

my $data = '';		# Test data;
my $failure;		# Notes to output if the next test fails.
my $home = getcwd;	# Directory test runs in.
my $skip;		# Skip indicator
my $test = 0;		# Test number;
my @todo = ();		# Tests expected to fail.
my %h_todo;		# Hash of tests expected to fail.

sub satpass {
    my $handle = shift;

#	If we can not get off the ground, do not try.

    if ($gblskip) {
	plan tests => 1;
	skip ($gblskip, 1);
	return;
    }

    local $| = 1;

#	Set up the testing hook in satpass.
# >>>	This interface is undocumented, and unsupported except for its
# >>>	use in this test script.

    no warnings qw{once};
    $Astro::satpass::Test::Hook = \&tester;
    $Astro::satpass::Test::Handle = $handle;
    use warnings qw{once};

#	Make a pass through the <DATA> to figure out how many tests
#	there are. Tell the Test package how many.

    my $start = tell ($handle);
    while (<$handle>) {
	if (m/^\s*-test\b/) {
	    $test++
	} elsif (m/^\s*-todo\b/) {
	    push @todo, $test;
	} elsif (m/^\s*-end\b/) {
	    last;
	}
    }
    seek ($handle, $start, 0);
    plan tests => $test, todo => \@todo;
    %h_todo = map {$_ => 1} @todo;

#	We start from test 1 (since we increment before use).

    $test = 0;

#	Set up the command arguments and 'do' the satpass script. All
#	further work is done by tester() when the script calls it.

    local @ARGV = ('-filter', -initialization_file => File::Spec->devnull ());
    $skip = '';
    do $script;
    print $@ if $@;
    return;
}

#	not_available(module ...) is a utility to determine whether the
#	given modules are available. If so, it loads them. If not, it
#	returns a message for the first module that can not be loaded.

sub not_available {
    foreach my $module (@_) {
	eval "require $module; 1"
	    or return "Module $module can not be loaded.";
    }
    return '';
}

#	not_reachable($url ...) is a utilty to determine whether the given
#	URLs are reachable. If so, it returns false. If not, it returns
#	a suitable message. Makes use of LWP::UserAgent, so may return
#	the results of not_available ('LWP::UserAgent').

sub not_reachable {
    my @args = @_;
    my $ok = not_available ('LWP::UserAgent');
    return $ok if $ok;
    my $ua = LWP::UserAgent->new ()
	or return "Cannot instantiate LWP::UserAgent.\n$@";
    foreach my $url (@args) {
	my $resp = $ua->get ($url);
	return $resp->status_line unless $resp->is_success;
    }
    return '';
}

#	tester() is the test callback. It is called whenever the
#	satpass script wants top-level input. The arguments are the
#	handle used for test I/O (God knows what you would do with
#	this), the _previous_ input line, all output since the previous
#	input was done, and the exception generated (or undef if none).
#	It returns the next line of input, or undef for end-of-file.

#	At least, that's what satpass expects of it. What it does
#	from the point of view of this script is to read the <DATA>
#	handle, parsing the file as it goes. A line that begins with
#	'-' is a test directive; these will be documented in-line.
#	Empty lines and lines beginning with '#' are ignored.
#	Any thing else is returned intact to the caller if the $skip
#	indicator (see below) is false, or ignored if it is true.

#	The test mechanism relies on the values of four local
#	variables:
#	    $data is the expected output of the test, though you
#		will find it is used for other purposes as well.
#	    $output is the output from the satpass script, which
#		was passed by the caller. There are a couple
#		mechanisms to replace this by other data.
#	    $except is the exception encountered, if any, which
#		was passed from the caller.
#	    $skip is the skip indicator.
#	All tests are of the form skip ($skip, $output eq $data).
#	That is, they are skipped if the $skip indicator is true,
#	otherwise they are true if $output eq $data.

sub tester {
##  my ( $handle, $input, $output, $except ) = @_;
    my ( $handle, undef, $output, $except ) = @_;	# Input unused
##  print "foo> $input" if $input;
##  print $output if $output;
    while (<$handle>) {
	chomp;
	s/^\s+//;
	s/\s+$//;
	next unless $_;
	next if m/^#/;
	unless (m/^-/) {
	    next if $skip;
	    return "$_\n";
	}

#	We support here documents in directives. The syntax is
#	pretty much the same as Perl's, except the indicator may
#	not be quoted, and we don't do interpolation.

	s|<<(.*)|| and do {
	    my $flag = ($1 || '') . "\n";
	    my $buffer = $_ . "\n";
	    while (<$handle>) {
		$_ eq $flag and do {$flag = undef; last};
		$buffer .= $_;
		}
	    die <<eod if defined $flag;
Error - Failed to find end of here document '<<$flag' before EOF.
eod
	    $_ = $buffer;
	};

#	-data loads the rest of the text into  $data.

	s/-data\b\s*//m and do {$data = $_; next};

#	-end ends the script early.

	s/-end\b// and last;

#	-fail specifies a note to be output if the next test fails.

	s/-fail\b\s*//m and do {$failure = $_; next};

#	-home sets us back to the directory we started in.

	s/-home\b\s*//m and do {chdir $home; next};

#	-read reads the named file into $output. The presumption is
#	that we're testing output redirected to a file.

	s/-read\b\s*//m and do {
	    my $fh;
	    my $fn = File::Spec->catfile(cwd, $_);
	    open $fh, '<', $fn
		or die "Failed to open $fn: $!";
	    local $/ = undef;	# Slurp mode
	    $output = <$fh>;
	    close $fh;
	    next;
	};

#	-result evals the rest of the line, placing the output into
#	$output. The presumption is that we're doing some computation
#	to determine the actual results of the test.

	s/-result\b\s*//m and do {
	    # Perl::Critic does not like string evals, but it's the only
	    # way to execute arbitrary code out of the data.
	    $output = eval $_;	## no critic (ProhibitStringyEval)
	    die $@ if $@; next
	};

#	-skip evals the rest of the line, placing the output into the
#	$skip variable. This will _not_ override any global
#	considerations that force the whole shebang to be skipped.

	s/-skip\b\s*//m and do {
	    # Perl::Critic does not like string evals, but it's the only
	    # way to execute arbitrary code out of the data.
	    $skip = eval $_;	## no critic (ProhibitStringyEval)
	    die $@ if $@; next
	};

#	-test actually performs the test. The rest of the line is an
#	optional title for the test. Note that if $except is defined,
#	it becomes the thing we test.

	s/-test\b\s*//m and do {
	    $test++;
	    print "#\n";
	    print $_ ? "# Test $test - $_\n" : "# Test $test\n";
##	    $data =~ s/^\s*\n//m;
	    chomp $data;
	    print $data !~ m/\n/g ?
		"#      Expected: $data\n" :
	       ("#      Expected:\n", map {"#         $_\n"} split '\n', $data);
	    $output = $except if defined $except;
	    $output =~ s/^\s*\n//m;
	    chomp $output;
	    print $output !~ m/\n/g ?
		"#           Got: $output\n" :
	       ("#           Got:\n", map {"#         $_\n"} split '\n', $output);
	    skip ($skip, $data eq $output);
	    warn sprintf "\n\n$failure\n\n", $test
		unless $skip || $h_todo{$test} || $data eq $output || !$failure;
	    $failure = undef;
	    next;
	};

#	-todo tells the tester that the PREVIOUS -test is expected to
#	fail. It is no-opped here, because we took care of it in the
#	first pass through the test script.

	s/-todo\b\s*// and next;

#	-unlink unlinks the named file. It would be nice if there were
#	automatic cleanup, but there is not.

	s/-unlink\b\s*//m and do {
	    unlink File::Spec->catfile (cwd, $_);
	    next
	};

#	-write writes the content of $data to the named file. It's
#	$data because I figured it could always be reset before the
#	next -test, but $output once clobbered is gone for good.
#	Interestingly, in the first use of this (testing the source
#	command) the text written to the file was also what I wanted
#	to test the results against, but I can't say I planned that.

	s/-write\b\s*//m and do {
	    my $fh;
	    my $fn = File::Spec->catfile(getcwd, $_);
	    open $fh, '>', $fn
		or die "Failed to open $fn: $!\n";
	    print $fh $data;
	    close $fh;
	    next;
	};

#	If we get here, die complaining of an unknown directive.

	die <<eod;
Error - Unknown directive: $_
eod

    }

#	If we run out of <DATA>, we return undef to request the script
#	to exit.

    return;
}

1;
