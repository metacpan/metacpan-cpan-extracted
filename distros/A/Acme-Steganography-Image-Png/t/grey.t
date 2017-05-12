#!perl -w
use strict;

use FindBin;

use lib $FindBin::Bin;

use Tester;

Tester::test_package('Acme::Steganography::Image::Png::FlashingNeonSignGrey');
