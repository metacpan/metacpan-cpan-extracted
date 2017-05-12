package Tester;
use strict;

use Test::More 'no_plan';

require Acme::Steganography::Image::Png;
ok ("Well, it loads");

my $file = $^X;

cmp_ok (-s $^X, '>', 0, "$^X has some contents");

my $data;

{
  local $/;
  open FH, $^X or die "Can't open $^X: $!";
  binmode FH;
  $data = <FH>;
}

is (length $data, -s $^X, "Read in $^X for testing");

sub test_package {
    my $package = shift;

    my $writer = $package->new();

    ok($writer, "Testing $package");

    $writer->data(\$data);

    my @filenames = $writer->write_images(@_);

    cmp_ok (@filenames, '>', 0, "Generated some images");

    foreach (@filenames) {
	ok (-e $_, "$_ exists");
    }

    my $reread = $package->read_files(reverse @filenames);

    is (length $reread, length $data, "Same length");
    # No. I don't want not equal diagnsotics sent to stderr
    ok ( $reread eq $data, "Same contents");

    unlink @filenames unless $::DEBUG;
}

1;
