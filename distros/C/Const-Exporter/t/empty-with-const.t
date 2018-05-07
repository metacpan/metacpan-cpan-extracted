#!perl

use Test::Most;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Package::Stash;

use lib 't/lib';

my $name = 'Test::Const::Exporter::Empty';

use_ok( $name, 'const' );
can_ok( __PACKAGE__, qw/ const / );

can_ok( $name, qw/ const / );

my $stash = Package::Stash->new($name);

my $export = $stash->get_symbol('@EXPORT');
is_deeply $export, [], '@EXPORT';

my $export_ok = $stash->get_symbol('@EXPORT_OK');
is_deeply $export_ok, ['const'], '@EXPORT_OK';

my $export_tags = $stash->get_symbol('%EXPORT_TAGS');
is_deeply $export_tags, { all => ['const'] }, '%EXPORT_TAGS';

done_testing;
