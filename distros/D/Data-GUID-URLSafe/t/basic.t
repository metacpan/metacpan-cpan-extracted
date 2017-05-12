
use strict;

use Test::More tests => 8;

use_ok('Data::GUID::URLSafe');

my $guid = Data::GUID->new;

isa_ok($guid, 'Data::GUID');
can_ok($guid, qw(as_base64_urlsafe));

my $string = $guid->as_base64_urlsafe;

unlike($string, qr{[/=+]}, "no bad characters in encoded guid");
is(length $string, 22, "all base64_urlsafe guids are 22 chars");

can_ok('Data::GUID', qw(from_base64_urlsafe));

my $recreate_guid = Data::GUID->from_base64_urlsafe($string);
isa_ok($recreate_guid, 'Data::GUID', 'guid from string');

is(
  $guid->compare_to_guid($recreate_guid),
  0,
  "the two GUIDs are identical",
);
