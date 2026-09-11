use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';

my @modules = qw(
    AmberDB
    AmberDB::Base
    AmberDB::Base::Schema
    AmberDB::Base::Encoder
    AmberDB::Base::Index
    AmberDB::Base::Facet
    AmberDB::Base::Junk
    AmberDB::Base::Transact
    AmberDB::Base::Cache
    AmberDB::Base::Ramdisk
    AmberDB::Array
    AmberDB::Date
    AmberDB::Locale
    AmberDB::Locale::Currency
    AmberDB::Locale::Lang::ar
    AmberDB::Locale::Lang::az
    AmberDB::Locale::Lang::de
    AmberDB::Locale::Lang::en
    AmberDB::Locale::Lang::es
    AmberDB::Locale::Lang::fr
    AmberDB::Locale::Lang::gb
    AmberDB::Locale::Lang::ja
    AmberDB::Locale::Lang::ru
    AmberDB::Locale::Lang::tr
    AmberDB::Tools
);

plan tests => scalar(@modules);

for my $mod (@modules) {
    use_ok($mod) or BAIL_OUT("Failed to load module: $mod");
}

diag("Testing AmberDB $AmberDB::VERSION, Perl $], $^X");
