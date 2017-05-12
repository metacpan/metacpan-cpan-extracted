#! /usr/bin/env perl

use lib qw+../blib/lib/+;
use Alien::BWIPP;
use Data::Dumper;

my $ean13 = new Alien::BWIPP::ean13;

open OUT, ">", "ean13.ps";
print OUT "% ean13 dependencies: " . $ean13->REQUIRES . "\n";
print OUT $ean13->post_script_source_code;

print OUT <<"END";
420 700 moveto (977147396801 05) (includetext guardwhitespace) /ean13 /uk.co.terryburton.bwipp findresource exec
0 -17 rmoveto (EAN-13) show
END
close OUT;


my $qrcode = new Alien::BWIPP::qrcode;

open OUT, ">", "qrcode.ps";
print OUT "% qrcode dependencies: " . $qrcode->REQUIRES . "\n";
print OUT $qrcode->post_script_source_code;

print OUT <<"END";
245 105 moveto (http://www.perl.org/ - this is a QR Code) () /qrcode /uk.co.terryburton.bwipp findresource exec
0 -10 rmoveto (QR Code) show
END
close OUT;
