#!/usr/bin/perl
# 08_hoax.t (was nasty.t)

use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

# my $have_stderr_redirect = 1;
# if ($^O eq 'MSWin32') {
#    Win32::IsWinNT() or $have_stderr_redirect = 0;
# }
# print $have_stderr_redirect ? "1..7\n" : "1..3\n";

print "1..8\n";

# --------------------------------------------------

my $camelstr = get_eye_string('camel');
my $tmpf = 'bill.tmp';
my $tmpf2 = 'bill2.tmp';

# -------------------------------------------------

my $itest = 0;
my $prog;

# Camel beginend.pl --------------------------------

# This tests BEGIN/END blocks.

my $evalstr = qq#eval eval '"'.\n\n\n#;
$evalstr =~ tr/!-~/#/;
my $teststr = $evalstr . $camelstr;
my $srcstr = qq#BEGIN {print "begin\\n"}\n# .
             qq#END {print "end\\n"}\n# .
             qq#print "line1\\nline2\\n";\n#;
$prog = sightly({ Shape         => 'camel',
                  SourceString  => $srcstr,
                  Regex         => 0,
                  InformHandler => sub {},
                  TrapEvalDie   => 0 } );
build_file($tmpf, $prog);

my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - BEGIN/END rc\n";
$outstr eq "begin\nline1\nline2\nend\n" or print "not ";
++$itest; print "ok $itest - BEGIN/END output\n";
$prog =~ tr/!-~/#/;
$prog eq $teststr or print "not ";
++$itest; print "ok $itest - BEGIN/END shape\n";

# Camel hellodie.pl --------------------------------

# This tests catching die inside eval.

$evalstr = qq#eval eval '"'.\n\n\n#;
$evalstr =~ tr/!-~/#/;
my $diestr = qq#\n\n\n;die \$\@ if \$\@\n#;
$diestr =~ tr/!-~/#/;
$teststr = $evalstr . $camelstr . $diestr;
$srcstr = 'die "hello die\\n";';
$prog = sightly({ Shape         => 'camel',
                  SourceString  => $srcstr,
                  Regex         => 0,
                  InformHandler => sub {},
                  TrapEvalDie   => 1 } );
build_file($tmpf, $prog);

local *SAVERR; open(SAVERR, ">&STDERR");  # save original STDERR
open(STDERR, '>'.$tmpf2) or die "Could not create '$tmpf2': $!";
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
open(STDERR, ">&SAVERR");  # restore STDERR

$rc == 0 and print "not ";
++$itest; print "ok $itest - die inside eval rc\n";
$outstr eq "" or print "not ";
++$itest; print "ok $itest - die inside eval output\n";
Acme::EyeDrops::_slurp_tfile($tmpf2) eq "hello die\n" or print "not ";
++$itest; print "ok $itest - die inside die output\n";
$prog =~ tr/!-~/#/;
$prog eq $teststr or print "not ";
++$itest; print "ok $itest - die inside die shape\n";

# --------------------------------------------------

unlink($tmpf2) or die "error: unlink '$tmpf2': $!";
unlink($tmpf) or die "error: unlink '$tmpf': $!";

# --------------------------------------------------
# Test slurp of non-existent file.

eval { Acme::EyeDrops::_slurp_tfile($tmpf) };
$@ =~ m|open \Q'$tmpf'\E| or print "not ";
++$itest; print "ok $itest - slurp of non-existent file\n";
