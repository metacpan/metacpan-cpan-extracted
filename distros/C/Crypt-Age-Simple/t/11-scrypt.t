#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental qw< signatures >;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp qw< tempfile >;

use Crypt::Age::Simple qw< :scrypt >;

can_ok __PACKAGE__, qw< age_scrypt_decrypt age_scrypt_encrypt  >;

my $cleartext = 'foo that bar!';
my $password = rand();

{
   my $ciphertext = age_scrypt_encrypt($password, $cleartext);
   ok length($ciphertext), 'generated some ciphertext';
   my $clear = age_scrypt_decrypt($password, $ciphertext);
   is $clear, $cleartext, 'decrypt via string';
}

my $infile = my_tempfile();
my $encfile = my_tempfile();
my $outfile = my_tempfile();

spew($infile, $cleartext);
age_scrypt_encrypt_file($password, $infile, $encfile);
ok -s $encfile, 'generated output encrypted file';

age_scrypt_decrypt_file($password, $encfile, $outfile);
ok -s $outfile, 'generated output decrypted file';
is slurp($outfile), $cleartext, 'decrypt via file';

open my $ifh, '<', $infile or die "open($infile): $!";
my $buffer = '';
open my $ofh, '>', \$buffer or die "open() on string: $!";
age_scrypt_encrypt_fh($password, $ifh, $ofh);
close $ofh;
close $ifh;
ok length($buffer), 'encryption yielded something';
is age_scrypt_decrypt($password, $buffer), $cleartext,
   'encryption as expected';

$ifh = undef;
open $ifh, '<:raw', $encfile or die "open($encfile): $!";
$ofh = undef;
open $ofh, '>:raw', $outfile or die "open($outfile): $!";
age_scrypt_decrypt_fh($password, $ifh, $ofh);
close $ofh;
close $ifh;
is slurp($outfile), $cleartext, 'decryption as expected';

sub spew ($path, $data) {
   open my $fh, '>:raw', $path or die "open($path): $!";
   print {$fh} $data or die "print($path): $!";
   close $fh or die "close($path): $!";
}

sub slurp ($path) {
   open my $fh, '<:raw', $path or die "open($path): $!";
   local $/;
   defined(my $retval = readline($fh)) or die "readline($path): $!";
   close $fh or die "close($path): $!";
   return $retval;
}

sub my_tempfile {
   my ($fh, $path) = tempfile(UNLINK => 1);
   return ($fh, $path) if wantarray;
   return $path;
}
