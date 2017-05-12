# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use DBZ_File;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$filename = 'testing';
@msgids = qw(<1@msgid.com> <2@domain.com> <blurle3@clari.net>);
@offsets = qw(0 26 53);

open(FP, ">$filename") || die "Unable to open $filename: $!";
tie(%hist, DBZ_File, $filename, 1, 0664) || die $!;

foreach (@msgids) {
    $pos = tell(FP);
    print FP "$_\t1234~-~4321\n";
    $hist{$_} = $pos;
}
print 'not ' if !(-s "$filename.pag");
print "ok 2\n";

untie(%hist);
undef(%hist);
close(FP);

open(FP, "<$filename") || die "Unable to open $filename: $!";
tie(%hist, DBZ_File, $filename) || die $!;

foreach (@msgids) {
    $val = $hist{$_};
    $should_be = shift @offsets;
    if ($val != $should_be) {
	##print "($val != $should_be) ";
	print 'not ';
	last;
    }
}
print "ok 3\n";

$val = $hist{'<undefined@foo.com>'};
print 'not ' if defined($val);
print "ok 4\n";

untie(%hist);
undef(%hist);

unlink($filename);
unlink("$filename.dir");
unlink("$filename.pag");
