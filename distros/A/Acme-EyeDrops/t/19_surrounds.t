#!/usr/bin/perl
# 19_surrounds.t
# Generate a new EyeDrops.pm as described in the doco:
# "EyeDropping EyeDrops.pm" section.
# Run various tests on the EyeDrop'ed EyeDrops.pm.
# Also generate sightly versions of 0..18 tests with a 'z' prefix.
# Since this test is very slow only run if the
# PERL_SMOKE environment variable is set.
#
# zsightly.t test works but the following might be written to stderr:
# Scalar found where operator expected at (eval 2) line 41, near "regex_eval_sightly($hellostr"
# This seems to happen only on Perl versions before 5.6.1. Is this a Perl bug?

use strict;
use File::Basename ();
use File::Copy ();
use File::Path ();
use Acme::EyeDrops qw(sightly);
use Test::Harness ();

$|=1;

# --------------------------------------------------

sub skip_test { print "1..0 # Skipped: $_[0]\n"; exit }

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

sub get_first_line {
   my $f = shift; local *T; open(T, $f) or die "open '$f': $!";
   my $s = <T>; close(T); $s;
}

sub rm_f_dir
{
   my $d = shift;
   -d $d or return;
   File::Path::rmtree($d, 0, 0);
   -d $d and die "error: could not delete everything in '$d': $!";
}

# --------------------------------------------------

skip_test('Skipping long running generator tests unless $ENV{PERL_SMOKE} is true')
   unless $ENV{PERL_SMOKE};

print STDERR "Long running generated tests running...\n";
print STDERR "(these are only run if PERL_SMOKE environment variable is true).\n";

print "1..4\n";

# --------------------------------------------------

sub eye_drop_eyedrops_pm {
   # Slurp EyeDrops.pm into $orig string.
   my $orig = Acme::EyeDrops::slurp_yerself();
   # Split $orig into the source ($src) and the pod ($doc).
   my ($src, $doc) = split(/\n1;\n/, $orig, 2);
   # Remove the line containing $eye_dir = __FILE__ ...
   # because this line confuses eval.
   $src =~ s/^(my \$eye_dir\b.*)$//m;
   # Return the new sightly version of EyeDrops.pm.
   $1 . sightly( { Regex         => 0,
                   Compact       => 1,
                   TrapEvalDie   => 1,
                   FillerVar     => ';#',
                   InformHandler => sub {},
                   Shape         => 'camel',
                   Gap           => 1,
                   SourceString  => $src } )
   . ";\n1;\n" . $doc;
}

# Copy lib/Acme to temporary new $genbase.
sub create_eyedrops_tree {
   my ($fromdir, $todir) = @_;

   my $fromdrops = "$fromdir/lib/Acme/EyeDrops";
   my $todrops   = "$todir/lib/Acme/EyeDrops";
   File::Path::mkpath($todrops, 0, 0777) or
      die "error: mkpath '$todrops': $!";

   local *D;
   opendir(D, $fromdrops) or die "error: opendir '$fromdrops': $!";
   my @eye = grep(/\.ey[ep]$/, readdir(D));
   closedir(D);

   for my $f (@eye) {
      File::Copy::copy("$fromdrops/$f", "$todrops/$f")
         or die "error: File::Copy::copy '$f': $!";
   }
   build_file("$todir/lib/Acme/EyeDrops.pm", eye_drop_eyedrops_pm());
}

# --------------------------------------------------

my $genbase = 'knob';

my $base = File::Basename::dirname($0);
# In the normal case, $base will be set to 't'.
# If you are naughtily running the tests from the t directory,
# base will probably be set to '.'.
my $frombase = $base eq 't' ? '.' : '..';

rm_f_dir($genbase);
create_eyedrops_tree($frombase, $genbase);

# --------------------------------------------------
# This saving and re-directing of STDOUT/STDERR in temporary files
# (implemented in test_one() below) is simple but not very clean.
# An alternative may be to use tie in some way, for example:
#    my $knob;
#    package MyStdout;
#    sub TIEHANDLE {
#       my $class = shift;
#       bless [], $class;
#    }
#    sub PRINT { my $self = shift; $knob .= join('', @_) }
#    sub PRINTF {
#       my $self = shift; my $fmt = shift;
#       $knob .= sprintf($fmt, @_);
#    }
#    package main;
#    tie *STDOUT, 'MyStdout';
# See, for example, TieOut.pm in the t/lib directory of ExtUtils-MakeMaker.
# (TieOut.pm is a little invention of chromatic's).

my $outf = 'out.tmp';
my $errf = 'err.tmp';
-f $outf and (unlink($outf) or die "error: unlink '$outf': $!");
-f $errf and (unlink($errf) or die "error: unlink '$errf': $!");

my $itest = 0;

sub test_one {
   my ($e, $rtests) = @_;

   local *SAVERR; open(SAVERR, ">&STDERR");  # save original STDERR
   local *SAVOUT; open(SAVOUT, ">&STDOUT");  # save original STDOUT
   open(STDOUT, '>'.$outf) or die "Could not create '$outf': $!";
   open(STDERR, '>'.$errf) or die "Could not create '$errf': $!";
   my $status = Test::Harness::runtests(@{$rtests});
   # XXX: Test harness does not like the next two closes.
   # close(STDOUT) or die "error: close STDOUT: $!";
   # close(STDERR) or die "error: close STDERR: $!";
   open(STDERR, ">&SAVERR") or die "error: restore STDERR: $!";
   open(STDOUT, ">&SAVOUT") or die "error: restore STDOUT: $!";
   # XXX: is this necessary to prevent leaks?
   close(SAVOUT) or die "error: close SAVOUT: $!";
   close(SAVERR) or die "error: close SAVERR: $!";

   my $outstr = Acme::EyeDrops::_slurp_tfile($outf);
   my $errstr = Acme::EyeDrops::_slurp_tfile($errf);

   print STDERR "\nstdout of TestHarness::runtests:\n$outstr\n";
   print STDERR "stderr of TestHarness::runtests:\n$errstr\n";

   $status or print "not ";
   ++$itest; print "ok $itest - TestHarness::runtests of $e\n";
}

# --------------------------------------------------

my %attrs = (
   Shape          => 'camel',
   Regex          => 0,
   Compact        => 1,
   TrapEvalDie    => 1,
   InformHandler  => sub {},
   Shape          => 'camel',
   Gap            => 1
);

my @unames = (
   '00_Coffee.t',
   '01_mug.t',
   '02_shatters.t',
   '03_Larry.t',
   '04_Apocalyptic.t',
   '05_Parrot.t',
   '06_not.t',
   '07_a.t',
   '08_hoax.t',
   '09_Gallop.t',
   '10_Ponie.t',
   '11_bold.t',
   '12_Beer.t',
   '13_to.t',
   '14_gulp.t',
   '15_Buffy.t',
   '16_astride.t',
   '17_Orange.t',
   '18_sky.t',
);
my @tests  = map("$base/$_",  @unames);
my @ztests = map("$base/z$_", @unames);

# Generate sightly-encoded versions of test programs (see also gen.t).
for my $i (0..$#unames) {
   $attrs{SourceFile} = $tests[$i];
   # Assume first line is #!/usr/bin/perl (needed for taint mode tests).
   my $s_new = get_first_line($attrs{SourceFile}) . "# This program was generated by $0\n";
   $s_new .= sightly(\%attrs);
   build_file($ztests[$i], $s_new);
}

# --------------------------------------------------
# Run with normal EyeDrops.pm as a speed comparison.

test_one('unsightly EyeDrops.pm, plain tests', \@tests);
test_one('unsightly EyeDrops.pm, generated tests', \@ztests);

# Now run with generated EyeDrops.pm.
{
   local @INC = @INC; unshift(@INC, "$genbase/lib");
   test_one('sightly EyeDrops.pm, plain tests', \@tests);
   test_one('sightly EyeDrops.pm, generated tests', \@ztests);
}

# ----------------------------------------------------

for my $t (@ztests) { unlink($t) or die "error: unlink '$t': $!" }

rm_f_dir($genbase);

unlink($outf) or die "error: unlink '$outf': $!";
unlink($errf) or die "error: unlink '$errf': $!";
