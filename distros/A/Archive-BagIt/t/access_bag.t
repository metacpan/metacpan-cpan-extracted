# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }

use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 35;
use Test::Exception;
use strict;


use lib '../lib';

use File::Spec;
use Data::Printer;
use File::Path;
use File::Copy;

my $Class = 'Archive::BagIt';
use_ok($Class);

my @ROOT = grep {length} 'src';

#warn "what is this: ".Dumper(@ROOT);


my $SRC_BAG = File::Spec->catdir( @ROOT, 'src_bag');
my $SRC_FILES = File::Spec->catdir( @ROOT, 'src_files');
my $DST_BAG = File::Spec->catdir(@ROOT, 'dst_bag');

## tests
my $bag = $Class->new({bag_path=>$SRC_BAG});
{
  my @unsorted = (
      { "Foo", "Baz"},
      { "Foo3", "Bar3"},
      { "Foo", "Bar" },
      { "Foo5", "Bar5"},
      { "Foo2", "Bar2"},
      { "Foo4", "Bar4\n  Baz4\n  Bay4"},
  );
  my @sorted = Archive::BagIt::__sort_bag_info( @unsorted);
  my @expected = (
      { "Foo", "Bar" },
      { "Foo", "Baz"},
      { "Foo2", "Bar2"},
      { "Foo3", "Bar3"},
      { "Foo4", "Bar4\n  Baz4\n  Bay4"},
      { "Foo5", "Bar5"}
  );
  is_deeply( \@sorted, \@expected, "__sort_bag_info");
}



is($bag->bag_version(), "0.96", "has expected bag version");

{
  my $input ="Foo:Bar";
  my @expected = (
      { "Foo", "Bar" },
  );
  my $got = $bag->_parse_bag_info( $input );
  is_deeply( $got, \@expected, "bag-info parsing, single line");
}

{
  my $input =<<BAGINFO;
Foo: Bar
Foo: Baz
Foo2 : Bar2
Foo3:   Bar3
Foo4: Bar4
  Baz4
  Bay4
Foo5: Bar5
Foo6: Bar6: Baz6
BAGINFO
  my @expected = (
      { "Foo", "Bar" },
      { "Foo", "Baz"},
      { "Foo2", "Bar2"},
      { "Foo3", "Bar3"},
      { "Foo4", "Bar4\n  Baz4\n  Bay4"},
      { "Foo5", "Bar5"},
      { "Foo6", "Bar6: Baz6"}
  );
  my $got = $bag->_parse_bag_info( $input );
  is_deeply( $got, \@expected, "bag-info parsing");
}
# real world example
{
  my $input =<<BAGINFO;
Bagging-Date: 2020-03-05
Bag-Software-Agent: Archive::BagIt <https://metacpan.org/pod/Archive::BagIt>
Payload-Oxum: 0.0
Bag-Size: 0 B
SLUBArchiv-archivalValueDescription: Gesetzlicher Auftrag der SLUB Dresden
SLUBArchiv-exportToArchiveDate: 20191127T120000.00
SLUBArchiv-externalId: 99193991991991
SLUBArchiv-externalWorkflow: kitodo
SLUBArchiv-hasConservationReason: true
SLUBArchiv-rightsVersion: 1.0
SLUBArchiv-sipVersion: v2020.1
BAGINFO
  my @expected = (
      {"Bagging-Date", "2020-03-05"},
      {"Bag-Software-Agent", "Archive::BagIt <https://metacpan.org/pod/Archive::BagIt>"},
      {"Payload-Oxum", "0.0"},
      {"Bag-Size", "0 B"},
      {"SLUBArchiv-archivalValueDescription", "Gesetzlicher Auftrag der SLUB Dresden"},
      {"SLUBArchiv-exportToArchiveDate", "20191127T120000.00"},
      {"SLUBArchiv-externalId", "99193991991991"},
      {"SLUBArchiv-externalWorkflow", "kitodo"},
      {"SLUBArchiv-hasConservationReason", "true"},
      {"SLUBArchiv-rightsVersion", "1.0"},
      {"SLUBArchiv-sipVersion", "v2020.1"},
  );
  my $got = $bag->_parse_bag_info( $input );
  is_deeply( $got, \@expected, "bag-info parsing (2)");
}

{
  my $got = $bag->bag_info();
  my @expected = (
      { "Bag-Software-Agent", "bagit.py <http://github.com/edsu/bagit>" },
      { "Bagging-Date", "2013-04-09"},
      { "Payload-Oxum", "4.2"}
    );
  is_deeply( $got, \@expected, "has all bag-info entries");
}
is_deeply ($bag->get_baginfo_values_by_key("Payload-Oxum"), "4.2", "bag_info_by_key, existing");
ok($bag->exists_baginfo_key("Payload-Oxum"), "exists_baginfo_key, existing");
is_deeply ($bag->get_baginfo_values_by_key("Bagging-Date"), "2013-04-09", "bag_info_by_key, existing2");
is_deeply ($bag->get_baginfo_values_by_key("Bag-Software-Agent"), "bagit.py <http://github.com/edsu/bagit>", "bag_info_by_key, existing3");
is ($bag->get_baginfo_values_by_key("NoKEY"), undef, "bag_info_by_key, not found");
ok(! $bag->exists_baginfo_key("NoKEY"), "exists_baginfo_key, not found");
is ($bag->_replace_baginfo_by_first_match("NoKey", "test"), undef, "_replace_bag_info_by_first_match, not found");
is ($bag->add_or_replace_baginfo_by_key("Key", "Value"), -1, "add a new key-value");
is ($bag->_replace_baginfo_by_first_match("Key", "0.0"), 3, "_replace_bag_info_by_first_match, index");
is_deeply ($bag->get_baginfo_values_by_key("Key"), "0.0", "_replace_bag_info_by_first_match, check new value");
is ($bag->add_or_replace_baginfo_by_key("key", "Noch ein Eintrag"), "-1", "add_or_replace key value");
is_deeply ($bag->get_baginfo_values_by_key("key"), "Noch ein Eintrag", "bag_info_by_key, existing");
is_deeply ($bag->get_baginfo_values_by_key("Payload-Oxum"), "4.2", "bag_info_by_key, existing");
is_deeply ($bag->get_baginfo_values_by_key("Bagging-Date"), "2013-04-09", "bag_info_by_key, existing2");
is_deeply ($bag->get_baginfo_values_by_key("Bag-Software-Agent"), "bagit.py <http://github.com/edsu/bagit>", "bag_info_by_key, existing3");
is ($bag->append_baginfo_by_key("key", "Und ein weiterer Eintrag"), 1, "append_bag_info");
is ($bag->get_baginfo_values_by_key("keY"), undef, "bag_info_by_key, check case sensitive");
my @got = $bag->get_baginfo_values_by_key("key", );
my @expected = ("Noch ein Eintrag", "Und ein weiterer Eintrag");
is_deeply( \@got, \@expected, "append_bag_info, check if both entries exist");
my $all_expected = $bag->bag_info();
ok($bag->delete_baginfo_by_key("NoKey"), "delete_baginfo_by_key(), not found");
my $all_got = $bag->bag_info();
is_deeply( $all_got, $all_expected, "delete_baginfo_by_key(), check if no other key is deleted");
ok($bag->delete_baginfo_by_key("key"), "delete_baginfo_by_key(), delete existing key 'key'");
{
  my @got = $bag->get_baginfo_values_by_key("key");
  my @expected = ("Noch ein Eintrag");
  is_deeply(\@got, \@expected, "delete_baginfo_by_key(), check if last entry of key 'key' is already deleted");
}
ok($bag->delete_baginfo_by_key("key"), "delete_baginfo_by_key(), delete existing key 'key' again");
{
  my @got = $bag->get_baginfo_values_by_key("key");
  my @expected = ();
  is_deeply(\@got, \@expected, "delete_baginfo_by_key(), check if deleted key 'key' is already deleted");
}
ok (! $bag->append_baginfo_by_key("payload-oxUm", "Völlig falsch"), "append_bag_info of uniq value");
my @got2 = $bag->get_baginfo_values_by_key("paylOAD-oxum", );
my @expected2 = ("4.2");
is_deeply( \@got2, \@expected2, "append_bag_info, check that value is not added");

throws_ok ( sub {$bag->add_or_replace_baginfo_by_key("Foo:Bar", "Baz")}, qr/key should not contain a colon/, "_add_or_replace_bag_info, invalid key check");
throws_ok ( sub {$bag->_replace_baginfo_by_first_match("Foo:Bar", "Baz")}, qr/key should not contain a colon/, "_replace_bag_info_by_first_match, invalid key check");

__END__
