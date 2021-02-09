#!/usr/local/bin/perl

use lib '../lib','./lib','./blib/lib';

# using globals and uninit variables here for convenience
no warnings;

@mods = qw/
    Cipher::AES
    Rijndael
    Blowfish
    Blowfish_PP
    IDEA
    DES
          /;
@pads = qw/standard oneandzeroes space null/;

for $mod (@mods) {
   eval "use Crypt::$mod(); 1" && push @in,$mod;
}

unless ($#in > -1) {
   print "1..0 # Skipped: no cryptographic modules found\n";
   exit;
}

# ($#in + 1): number of installed modules
# ($#pads + 1): number of padding methods
# 64: number of per-module, per-pad tests
# 1: the first test -- loading Crypt::CBC module

print '1..', ($#in + 1) * ($#pads + 1) * 64 + 1, "\n";

$tnum = 0;

eval "use Crypt::CBC";
test(\$tnum,!$@,"Couldn't load module");

for $mod (@in) {
   for $pad (@pads) {

      $test_data = <<END;
Mary had a little lamb,
Its fleece was black as coal,
And everywere that Mary went,
That lamb would dig a hole.
END
    ;

      test(\$tnum,$i = Crypt::CBC->new(-key => 'secret',
				       -cipher => $mod,
				       -padding => $pad,
				       -pbkdf   => 'opensslv2',
                                      ),
                                      "Couldn't create new object");

      test(\$tnum,$c = $i->encrypt($test_data),"Couldn't encrypt");
      test(\$tnum,$p = $i->decrypt($c),"Couldn't decrypt");
      test(\$tnum,$p eq $test_data,"Decrypted ciphertext doesn't match plaintext with cipher=$mod, pad=$pad and plaintext size=".length $test_data);

# now try various truncations of the whole string.
# iteration 3 ends in ' ' so 'space should fail

      for ($c=1;$c<=7;$c++) {

         substr($test_data,-$c) = '';

         if ($c == 3 && $pad eq 'space') {
            test(\$tnum,$i->decrypt($i->encrypt($test_data)) ne $test_data);
         } else {
            test(\$tnum,$i->decrypt($i->encrypt($test_data)) eq $test_data);
         }
      }

# try various short strings

      for ($c=0;$c<=18;$c++) {
        $test_data = 'i' x $c;
        test(\$tnum,$i->decrypt($i->encrypt($test_data)) eq $test_data);
      }

# try adding a "\001" to the end of the string
      for ($c=0;$c<=31;$c++) {
	  $test_data = 'i' x $c;
	  $test_data .= "\001";
	  test(\$tnum,$i->decrypt($i->encrypt($test_data)) eq $test_data,"failed to decrypt with cipher=$mod, padding=$pad, and plaintext length=".($c+1));
      }

# 'space' should fail. others should succeed.

      $test_data = "This string ends in some spaces  ";

      if ($pad eq 'space') { 
         test(\$tnum,$i->decrypt($i->encrypt($test_data)) ne $test_data);
      } else {
         test(\$tnum,$i->decrypt($i->encrypt($test_data)) eq $test_data);
      }

# 'null' should fail. others should succeed.

      $test_data = "This string ends in a null\0";

      if ($pad eq 'null') { 
         test(\$tnum,$i->decrypt($i->encrypt($test_data)) ne $test_data);
      } else {
         test(\$tnum,$i->decrypt($i->encrypt($test_data)) eq $test_data);
      }
   }
}

sub test {
    my($num, $true, $msg) = @_;
    $msg ||= "cipher=$mod, padding=$pad, plaintext length=$c";
    $$num++;
    print($true ? "ok $$num\n" : "not ok $$num $msg\n");
}

