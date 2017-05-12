#!/usr/bin/perl

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

plan tests => 2;
# We can't use Apache::UploadMeter, since we can't call Apache2::Module::add from here
ok(1); # If we made it this far, we're ok.

my $file = "MANIFEST";
my $size = -s $file;
my $expected =<<"TEST1";
Results:
Parsed upload field filename:
	Filename: $file
	Size: $size

Done
TEST1

my $data = UPLOAD_BODY "/perl/upload?meter_id=1234", filename => $file;

ok t_cmp(
           $data,
           $expected,
           "simple upload test",
          );
