#!perl 
use warnings;
use strict;

use File::Temp;
use File::Slurp qw(read_file);

# tests that all the perl modules matchine ./bin/fdb* compile 

# the GLOBAL LIST of files we're going to test
our @files;

my $child_name = "";    # the name of this child
my $child_signal = 0;
my $perl = $^X;

############################################
# we run the whole setup in a BEGIN block so we know how many tests to run before
# we call main()
BEGIN {
	use strict;

    @files = glob( "bin/fdb*" );

    use Test::More;# qw(no_plan); 
    # two tests for each file: with and without the current %ENV
};

############################################
main();


############################################
# main() : RUN THE TESTS
sub main {
    # install a signal handler for the CHLD signal
    $SIG{CHLD} = \&on_exit;

    unless ( $ENV{RELEASE_TESTING} ) {
        plan( skip_all => "Author tests not required for installation" );
        ok(1);
        exit(0);
    }
    my $num_tests = scalar(@files) + 1; 
    plan tests => $num_tests;

    ok( scalar( @files ), "Found scripts to test" );
    for my $file (@files) {
        chomp($file);
        test_file( $file, "" ); # test it, with the current %ENV
    }
}

############################################
# test_file($file, $test_method)
# 
sub test_file {
    my ($file, $test_method) = @_;
	my $cmd = "$perl -c $file";
	$child_name = "$file, $test_method";
    my ($out, $err, $dollarquestionmark) = RunCommand( $cmd );
	my @errors = grep { !/syntax ok/i } split(/\n/, $err);
	$err = join(" ... ", @errors);

	#print "$file: '@errors'\n";
    cmp_ok($err, 'eq', "", "$child_name (@errors)"); 
}

############################################
# this is a signal handler for the CHLD signal
sub on_exit {
    my $signame = shift;
    if ($?) {
        warn "$0: detected child's signal '$signame' in $child_name: $?\n" ;
        #exit(1);
    }
}

# RunCommand's block, to encapsulate @tmpfiles.
{
    my @tmpfiles = ();
    # given a command and optional tmpdir, returns (stdout, stderr, $?) 
    # uses the shell underneath
    sub RunCommand {
        my ($cmd, $tmpdir, $should_be_undef) = @_;
        die "$0: Internal Error: RunCommand called with three arguments\n" 
            if $should_be_undef;
        $tmpdir = "/tmp" unless defined $tmpdir;
        my ($out, $err) = ("", "");
        my ($ofh, $outfile) = File::Temp::tempfile( "cmd-out.XXXXX", DIR => $tmpdir);
        my ($efh, $errfile) = File::Temp::tempfile( "cmd-err.XXXXX", DIR => $tmpdir);
        # use two temporary filenames 
        my $torun = "$cmd 1>$outfile 2>$errfile";
        push(@tmpfiles, $outfile, $errfile);    # in case of SIG
        #print "RUNNING $torun\n";
        system($torun);
        if ($?) {
            my $exit  = $? >> 8;
            my $signal = $? & 127;
            my $dumped = $? & 128;

            $err .= "** ERROR: $torun\n";
            $err .= "exitvalue $exit";
            $err .= ", got signal $signal" if $signal;
            $err .= ", dumped core" if $dumped;
            $err .= "\n";
        }
        my $dollarquestionmark = $?;
            
        $out .= read_file($outfile);
        $err .= read_file($errfile);

        unlink($errfile) || warn "$0: couldn't unlink $errfile: $!";
        pop(@tmpfiles);
        unlink($outfile) || warn "$0: couldn't unlink $outfile: $!";
        pop(@tmpfiles);

        return ($out, $err, $dollarquestionmark);
    }
    END {   # hopefully this will get triggered 
            # if RunCommand throws an exception
        for my $tmpfile (@tmpfiles) {
            unlink($tmpfile) || warn "** Couldn't unlink tmp file $tmpfile"; 
        }
    }
}
