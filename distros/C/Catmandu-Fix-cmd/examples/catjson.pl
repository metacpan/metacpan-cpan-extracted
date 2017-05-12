#!/usr/bin/env perl

use JSON;
while (<STDIN>) {
   my $data = decode_json($_);
   print encode_json($data);
}
