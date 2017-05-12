#!perl -w
use strict;

use FindBin;
use File::Spec;
use lib $FindBin::Bin;
use Tester;
use Test::More;

my $test_image = File::Spec->catfile($FindBin::Bin, 'Elsa');
ok (-e $test_image, "We have our test image '$test_image'");

Tester::test_package('Acme::Steganography::Image::Png::RGB::556', $test_image);
Tester::test_package('Acme::Steganography::Image::Png::RGB::323', $test_image);
Tester::test_package('Acme::Steganography::Image::Png::RGB::556FS',
		     $test_image);
