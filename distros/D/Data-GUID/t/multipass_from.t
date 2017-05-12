#!perl

use strict;
use warnings;
use Test::More tests => 52;

BEGIN { use_ok('Data::GUID', ':all'); }

my @multipass_methods = qw(best_guess from_any_string);

my $guid = Data::GUID->guid;
isa_ok($guid, 'Data::GUID', 'guid from guid method');

for my $method (@multipass_methods) {
  is(
    $guid->compare_to_guid(Data::GUID->$method($guid)),
    0,
    "$method returns equivalent guid for Data::GUID object"
  );

  for (undef, '', 'your face', {}) {
    eval { Data::GUID->$method($_); };
    like($@, qr/not a valid GUID/, "bogus value makes $method carp");

    my $_guid = eval { guid_from_anything($_) };
    is($@, '', "guid_from_anything doesn't carp on bad data...");
    is($_guid, undef, "...but doesn't return anything either");
  }

  for my $type (qw(string base64 hex)) {
    my $new  = "guid_$type";

    my $from_method = Data::GUID->$new;
    my $from_export = main->can($new)->();

    for my $guid ($from_method, $from_export) {
      like(
        $guid,
        Data::GUID->__type_regex($type),
        "$new gave $type-like string"
      );

      isa_ok(
        Data::GUID->$method($guid),
        'Data::GUID',
        "remade from string via $method"
      );
    }
  }
}
