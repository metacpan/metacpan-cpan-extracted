use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use Data::UUID::MT;
use List::AllUtils qw/uniq/;

# for diagnostics
#sub _as_string {
#  return uc join "-", unpack("H8H4H4H4H12", shift);
#}

my @cases = (
  {},
  { version => '1' },
  { version => '4' },
  { version => '4s' },
);

for my $c ( @cases ) {
  my $label = $c->{version} || '4 (default)';
  subtest "version => $label"  => sub {
    my $ug = Data::UUID::MT->new( %$c );
    my $version = $c->{version} || "4";
    my $uuid1= $ug->create;

    # structural test
    my $binary = unpack("B*", $uuid1);
    ok( defined $uuid1, "Created a UUID" );
    is( length $uuid1, 16, "UUID is 16 byte string" );
    is( substr($binary,64,2), "10", "variant field correct" );
    is( substr($binary,48,4),
        substr(unpack("B8", chr(substr($version,0,1))),4,4),
        "version field correct"
    );

    # uniqueness test
    my @uuids;
    push @uuids, $ug->create for 1 .. 10000;
    my @uniq = uniq @uuids;
    is( scalar @uniq, scalar @uuids, "Generated 10,000 unique UUIDs" );

    # sequence test
    my @seq;
    if ( $version eq "1" ) {
      # version 1 is time-low, time-mid, time-high-and-version
      @seq = map { substr($_,6,2) . substr($_,4,2) . substr($_,0,3) } @uuids;
    }
    else {
      # version 4 should be random except for version bits
      # version 4s should be sequential in the first 64 bits (albeit with
      # the version bits 'frozen')
      @seq = map { substr($_,0,8) } @uuids;
    }
    my @sorted = sort @seq;
    if ( $version eq "4" ) {
      ok( join("",@seq) ne join("",@sorted),
        "UUIDs are not ordered for version $version"
      );
    }
    else {
      ok( join("",@seq) eq join("",@sorted),
        "UUIDs are correctly ordered for version $version"
      );
    }
  }
}

# output tests
my $ug = Data::UUID::MT->new;
my $hex = $ug->create_hex;
my $str = $ug->create_string;
my $h = "[0-9a-f]"; # lc
is( length $hex, 34, "create_hex length correct");
like( $hex, qr/\A0x${h}{32}\z/,
  "create_hex format correct" 
);
is( length $str, 36, "create_hex length correct");
like( $str, qr/\A${h}{8}-${h}{4}-${h}{4}-${h}{4}-${h}{12}\z/,
  "create_hex format correct" 
);

# iterator test
my $next = $ug->iterator;
my $uuid = $next->();
my $binary = unpack("B*", $uuid);
is ( length $uuid, 16, "iterator produces 16 byte value" );
is( substr($binary,64,2), "10", "variant field correct" );
is( substr($binary,48,4),
    substr(unpack("B8", chr(4)), 4, 4),
    "version field correct"
);

# reseed test
$ug->reseed(12345);
my $first = $ug->create_string;
$ug->reseed(12345);
my $second = $ug->create_string;
is( $first, $second, "got same UUIDs after reseeding with same values" );
$ug->reseed;
my $third = $ug->create_string;
isnt( $second, $third, "got different UUID after default reseeding" );





done_testing;
#
# This file is part of Data-UUID-MT
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
