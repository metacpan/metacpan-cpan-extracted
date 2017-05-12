#!perl
use strict;
use warnings;

use Test::More 0.88;

BEGIN { use_ok('Data::GUID'); }

my $guid = Data::GUID->new;
isa_ok($guid, 'Data::GUID');

like(
  $guid->as_string,
  Data::GUID->string_guid_regex,
  "GUID as_string looks OK",
);

like(
  "$guid",
  Data::GUID->string_guid_regex,
  "stringified GUID looks OK",
);

like(
  $guid->as_hex,
  Data::GUID->hex_guid_regex,
  "GUID as_hex looks OK",
);

like(
  $guid->as_base64,
  Data::GUID->base64_guid_regex,
  "GUID as_hex looks OK",
);

ok(
  ($guid <=> $guid) == 0,
  "guid is equal to itself",
);

{
  my $non_guid_value = 10;

  is(
    (($non_guid_value <=> $guid) * +1),
    (($guid <=> $non_guid_value) * -1),
    "guid on rhs of unbalanced <=> is (x * -1)",
  );
}

{
  my $uuid = Data::UUID->new->create;

  isa_ok(
    Data::GUID->from_data_uuid($uuid),
    'Data::GUID',
    "from_data_uuid",
  );

  for my $value (undef, '', 'foo') {
    eval { Data::GUID->from_data_uuid($value) };
    like($@, qr/not a valid Data::UUID/, "invalid Data::UUID value rejected");
  }
}

for my $type (qw(hex string base64)) {
  my $as   = "as_$type";
  my $from = "from_$type";
  my $copy = Data::GUID->$from($guid->$as);
  isa_ok($copy, 'Data::GUID', "guid from $type");
  is(
    $guid <=> $copy,
    0,
    "original guid is equal to copy round-tripped via $type",
  );

  my $guid_str_method = "guid_$type";
  my $guid_str = Data::GUID->$guid_str_method;

  for my $value (undef, '', 'foo') {
    eval { Data::GUID->$from($value); };
    like($@, qr/not a valid $type/, "invalid input to $from croaks");
  }

  my $re_method = "$type\_guid_regex";
  like($guid_str, Data::GUID->$re_method, "guid_$type method ok");
}

{
  my $guid = Data::GUID->new;
  my $str  = $guid->as_string;
  $str =~ s/-//g;
  my $copy = Data::GUID->from_string($str);
  is($guid->as_string, $copy->as_string, "we can from_string a dash-less str");
}

done_testing;
