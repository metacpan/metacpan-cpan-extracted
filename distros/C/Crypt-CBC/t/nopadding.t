#!/usr/local/bin/perl

use lib '../lib','./lib','./blib/lib';

my (@mods,@pads,@in,$tnum);

@mods = qw/
    Cipher::AES
    Rijndael
    Blowfish
    Blowfish_PP
    IDEA
    DES
          /;

for $mod (@mods) {
   eval "use Crypt::$mod(); 1" && push @in,$mod;
}

unless ($#in > -1) {
   print "1..0 # Skipped: no cryptographic modules found\n";
   exit;
} else {
    print "1..2\n";
}

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    $$num++;
    print($true ? "ok $$num\n" : "not ok $$num $msg\n");
}

$tnum = 0;

eval "use Crypt::CBC";
print STDERR "using Crypt\:\:$in[0] for testing\n";
test(\$tnum,!$@,"Couldn't load module");

my $key = "\x00" x "Crypt::$in[0]"->keysize;
my $iv  = "\x00" x "Crypt::$in[0]"->blocksize;

my $cipher = Crypt::CBC->new(
    {
	cipher => $in[0],
	key    => $key,
	iv     => $iv,
	literal_key => 1,
	header   => 'none',
	padding  => 'none',
	nodeprecate=>1,
    }
);
my $string = 'A' x "Crypt::$in[0]"->blocksize;

test(\$tnum,length $cipher->encrypt($string) == "Crypt::$in[0]"->blocksize,"nopadding not working\n");

exit 0;

