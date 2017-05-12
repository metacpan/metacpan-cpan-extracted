#! /usr/local/bin/perl -w
# 
# DES_PP benchmarking.
# Copyright 2000, Guido Flohr <guido@imperia.net>

use strict;
use IO::File;
use POSIX;
use Crypt::DES_PP;
use Benchmark;

use constant SECONDS_PER_TEST => 10;
use constant KEY => 'PurePerl';
use constant PLAINTEXT => 'PerlPunk';
use constant CIPHERTEXT => 'PunkPerl';

sub alarm_handler ($);

my $clocks;
my $elapsed = 0;

STDOUT->autoflush (1);

print <<EOF;
1..1
=== Benchmarking DES_PP module. ===
To pace directly against XS (embedded C code) version run \`\`perl test-xs''
in this directory.
EOF

print "checking prerequisites... ";
eval {
    eval 'use POSIX qw (_SC_CLK_TCK); 
              $clocks = sysconf (&POSIX::_SC_CLK_TCK)';
    if ($@) {
	eval 'use POSIX qw (CLK_TCK);
                      $clocks = sysconf (&POSIX::CLK_TCK)';
	if ($@) {
	    eval 'use POSIX qw (TICKS_PER_SEC);
                              $clocks = POSIX::TICKS_PER_SEC';
	}
	die "can't find out your kernel's heartbeat\n" if $@;
    }
    
    if (exists $SIG{ALRM}) {
	# Check if the POSIX version of times(2) is available.
	die "POSIX::times not available\n" 
	    unless exists $POSIX::{times};
	
    } else {
	die "no SIGALRM available\n";
    }
};

if ($@) {
    print <<EOF;
tsk, tsk
Please reformat your harddisk and install an operating system before you
proceed.
ok # Skipped: $@
EOF

    exit 0;
}

print "looks fine\n";

$SIG{ALRM} = \&alarm_handler;

my $starttime;
my $count = 0;

my $des;

print "Initializing 8-byte keys for ", SECONDS_PER_TEST, " seconds... ";
eval {
    (undef, $starttime) = POSIX::times;

    alarm SECONDS_PER_TEST;
    while (1) { $des = Crypt::DES_PP->new (KEY); ++$count };
};
die if $@ and $@ ne "alarm\n";

my $keys_per_sec = ($clocks * $count) / $elapsed;
print "$keys_per_sec keys per second\n";

# Benchmark encryption.
print "Encrypting 8-byte blocks for ", SECONDS_PER_TEST, " seconds... ";
$des = Crypt::DES_PP->new (KEY);
$count = 0;

eval {
    (undef, $starttime) = POSIX::times;

    alarm SECONDS_PER_TEST;
    while (1) { $des->encrypt (PLAINTEXT); ++$count };
};
die if $@ and $@ ne "alarm\n";

my $encrypts_per_sec = ($clocks * $count) / $elapsed;
print "$encrypts_per_sec encryptions per second\n";

# Benchmark encryption.
print "Decrypting 8-byte blocks for ", SECONDS_PER_TEST, " seconds... ";
$des = Crypt::DES_PP->new (KEY);
$count = 0;

eval {
    (undef, $starttime) = POSIX::times;

    alarm SECONDS_PER_TEST;
    while (1) { $des->decrypt (CIPHERTEXT); ++$count };
};
die if $@ and $@ ne "alarm\n";

my $decrypts_per_sec = ($clocks * $count) / $elapsed;
print "$decrypts_per_sec decryptions per second\n";

# Run in Cipher Block Chaining Mode.
use constant EIGHT_BYTE_BLOCKS => 20_000;
my $plaintext = PLAINTEXT x EIGHT_BYTE_BLOCKS;
my ($start, $end);
my $timediff = '';
my $des_driver = 'DES';
my $des_pp_driver = 'DES_PP';

# First pure Perl version.
print "Encrypting ", EIGHT_BYTE_BLOCKS << 3, " bytes in CBC mode...";
eval '
    use Crypt::CBC;
    
    my $cipher = Crypt::CBC->new (KEY, $des_pp_driver);
    my $start = Benchmark->new;
    $cipher->encrypt ($plaintext);
    my $end = Benchmark->new;
    $timediff = timestr timediff $end, $start;
';
print $@ ? " skipped (Crypt::CBC not loadable)\n" : 
    " done\n$timediff\n";

# Now the XS version.
print "XS-Version: Encrypting ", EIGHT_BYTE_BLOCKS << 3, 
    " bytes bytes in CBC mode...";
eval '
    use Crypt::CBC;
    
    my $cipher = Crypt::CBC->new (KEY, $des_driver);
    my $start = Benchmark->new;
    $cipher->encrypt ($plaintext);
    my $end = Benchmark->new;
    $timediff = timestr timediff $end, $start;
';
print $@ ? " skipped (Crypt::CBC or Crypt::DES not loadable)\n" : 
    " done\n$timediff\n";
$timediff = 0;

# Now with a non-cached key and 128 bytes of plaintext.
$plaintext = PLAINTEXT x 16;
print "Encrypting ", EIGHT_BYTE_BLOCKS, 
    " 128-byte-blocks in non-cached CBC mode...";
eval '
    use Crypt::CBC;
    
    my $start = Benchmark->new;

    for (1 .. EIGHT_BYTE_BLOCKS >> 3) {
	my $cipher = Crypt::CBC->new (KEY, $des_pp_driver);
	$cipher->encrypt ($plaintext);
    }
    my $end = Benchmark->new;
    $timediff = timestr timediff $end, $start;
';
print $@ ? " skipped (Crypt::CBC not loadable)\n" : 
    " done\n$timediff\n";
$timediff = 0;

$plaintext = PLAINTEXT x 16;
print "XS-Version: Encrypting ", EIGHT_BYTE_BLOCKS, 
    " 128-byte-blocks in non-cached CBC mode...";
eval '
    use Crypt::CBC;
    
    my $start = Benchmark->new;

    for (1 .. EIGHT_BYTE_BLOCKS >> 3) {
	my $cipher = Crypt::CBC->new (KEY, $des_driver);
	$cipher->encrypt ($plaintext);
    }
    my $end = Benchmark->new;
    $timediff = timestr timediff $end, $start;
';
print $@ ? " skipped (Crypt::CBC not loadable)\n" : 
    " done\n$timediff\n";
print "ok 1\n";

sub alarm_handler ($) {    
    my (undef, $endtime) = POSIX::times;

    $elapsed = $endtime - $starttime;
    
    die "alarm\n";
}




