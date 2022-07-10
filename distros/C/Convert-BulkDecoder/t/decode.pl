#! perl

use strict;
use Test::More;

my ($type, $sub) = @ARGV;
my @files = glob("data/".$type.$sub."??");

if ( @files ) {
    plan tests => 33;
}
else {
    plan skip_all => "No data for test $type$sub";
    exit;
}

require_ok('Convert::BulkDecoder');

my $ref = "data/${type}ref";
$ref = "data/Zref" unless -s $ref;
my $tst = "${type}tst";
my @art;
my $digest;
my $lines;

foreach my $file ( @files ) {
    open(F, $file) or die("$file: $!\n");
    while ( <F> ) {
	# Read lines and checksum from first data file.
	unless ( $lines ) {
	    chomp;
	    ($lines, $digest) = split;
	    next;
	}
	push(@art, $_);
    }
    close(F);
}
ok(@art == $lines, scalar(@art) . " lines of raw data");

# Plain unpacking.
my @tst = (lc($tst), $tst, lc($tst)."1", $tst."1");
unlink(@tst);
my $e = new Convert::BulkDecoder (destdir => ".", md5 => 0, verbose => 1);
$e->decode(\@art);
ok($e->{type} eq $type, "type is " . $e->{type});
ok($e->{name} eq $tst, "name is " . $e->{name});
ok($e->{file} eq "./".$tst, "file is " . $e->{file});
ok($e->{result} eq "OK", $e->{result});
ok(!differ($e->{file}, $ref), "PASS");
ok($e->{size} == -s $ref, "size is " . $e->{size});

if ( $type eq "M" ) {
    my $e = $e->{parts}->[1];
    ok($e->{type} eq $type, "type[1] is " . $e->{type});
    ok($e->{name} eq $tst."1", "name[1] is " . $e->{name});
    ok($e->{file} eq "./".$tst."1", "file[1] is " . $e->{file});
    ok($e->{result} eq "OK", $e->{result} . "[1]");
    ok(!differ($e->{file}, $ref), "PASS[1]");
    ok($e->{size} == -s $ref, "size[1] is " . $e->{size});
}
else {
    my $e = $e->{parts}->[0];
    ok($e->{type} eq $type, "type[0] is " . $e->{type});
    ok($e->{name} eq $tst, "name[0] is " . $e->{name});
    ok($e->{file} eq "./".$tst, "file[0] is " . $e->{file});
    ok($e->{result} eq "OK", $e->{result} . "[0]");
    ok(!differ($e->{file}, $ref), "PASS[0]");
    ok($e->{size} == -s $ref, "size[0] is " . $e->{size});
}

# Duplicate detection.
$e = new Convert::BulkDecoder (md5 => 0, verbose => 0);
$e->decode(\@art);
ok($e->{result} eq "DUP", $e->{result});
ok(!differ($e->{file}, $ref), "PASS");
ok($e->{size} == -s $ref, "size is " . $e->{size});

# Duplicate detection.
$e = new Convert::BulkDecoder (md5 => 0, force => 1, verbose => 0);
$e->decode(\@art);
ok($e->{type} eq $type, "type is " . $e->{type});
ok($e->{name} eq $tst, "name is " . $e->{name});
ok($e->{file} eq $tst, "file is " . $e->{file});
ok($e->{result} eq "OK", $e->{result});
ok(!differ($e->{file}, $ref), "PASS");
ok($e->{size} == -s $ref, "size is " . $e->{size});

# Unpack with MD5 digest.
unlink(@tst);
$e = new Convert::BulkDecoder (md5 => 1, verbose => 0);
$e->decode(\@art);
ok($e->{result} eq "OK", $e->{result});
ok(!differ($e->{file}, $ref), "PASS");
ok($e->{md5} eq $digest, "MD5: " . $e->{md5});
ok($e->{size} == -s $ref, "size is " . $e->{size});

# Unpack with MD5 and messages. No file name massaging.
unlink(@tst);
$e = new Convert::BulkDecoder
  (
   verbose => 1,
   md5 => 1,
   destdir => ".",
   neat => sub { lc(shift) },
  );
$e->decode(\@art);
ok($e->{result} eq "OK", $e->{result});
ok($e->{name} eq lc($tst), "name is " . $e->{name});
ok($e->{file} eq "./".lc($tst), "file is " . $e->{file});
ok(!differ($e->{file}, $ref), "PASS");
ok($e->{md5} eq $digest, "MD5");
ok($e->{size} == -s $ref, "size is " . $e->{size});

# Clean up.
unlink(@tst);

sub differ {
    # Perl version of the 'cmp' program.
    # Returns 1 if the files differ, 0 if the contents are equal.
    my ($old, $new) = @_;
    unless ( open (F1, $old) ) {
	print STDERR ("$old: $!\n");
	return 1;
    }
    unless ( open (F2, $new) ) {
	print STDERR ("$new: $!\n");
	return 1;
    }
    my ($buf1, $buf2);
    my ($len1, $len2);
    while ( 1 ) {
	$len1 = sysread (F1, $buf1, 10240);
	$len2 = sysread (F2, $buf2, 10240);
	return 0 if $len1 == $len2 && $len1 == 0;
	return 1 if $len1 != $len2 || ( $len1 && $buf1 ne $buf2 );
    }
}

1;
