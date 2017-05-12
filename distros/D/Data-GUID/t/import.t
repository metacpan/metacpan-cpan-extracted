#!perl

use strict;
use warnings;

use Test::More tests => 11;

BEGIN { use_ok('Data::GUID'); }

package Test::Data::GUID::BAD_EXPORT;

eval { Data::GUID->import('strong_crypto'); };
main::like($@, qr/"strong_crypto" is not exported/, "croak on bad import arg");

package Test::Data::GUID::ALL;

BEGIN { Data::GUID->import(':all'); }

for my $sub (qw(guid_string guid_hex guid_base64)) {
  main::isa_ok(__PACKAGE__->can($sub), 'CODE', "the $sub sub imported (:all)");
  # Why doesn't the following line work?  Replacing __PACKAGE__ doesn't help.
  # main::can_ok(__PACKAGE__, $sub, "$sub properly imported");
}

package Test::Data::GUID::ALL_LIST;

BEGIN { Data::GUID->import(qw(guid_string guid_hex guid_base64)); }

for my $sub (qw(guid_string guid_hex guid_base64)) {
  main::isa_ok(__PACKAGE__->can($sub), 'CODE', "the $sub sub imported (named)");
}

package Test::Data::GUID::GUID_STRING;

BEGIN { Data::GUID->import(qw(guid_string)); }

for my $sub (qw(guid_string)) {
  main::isa_ok(__PACKAGE__->can($sub), 'CODE', "the $sub sub imported (alone)");
}

for my $sub (qw(guid_hex guid_base64)) {
  main::is(__PACKAGE__->can($sub), undef, "the $sub sub was not imported");
}
