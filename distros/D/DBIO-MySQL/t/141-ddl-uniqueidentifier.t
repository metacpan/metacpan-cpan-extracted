use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# OFFLINE half of karr k115 (t/142 has the live half): the type
# uniqueidentifier, as DBIO::Test::Schema::ArtistGUID declares it.
#
# WHY IT MATTERS. MySQL and MariaDB have no uniqueidentifier. install_ddl wrote
# the name through, so the CREATE TABLE of the shared test schema was refused
# (1064) and nothing that deploys it could run. The family spells a GUID as its
# string form, VARCHAR(36) (dbio-sybase k52). AUTO_INCREMENT is for integers
# only: a GUID column that asks for is_auto_increment (the key of ArtistGUID,
# whose value the storage generates, not the server) must not get it, or the
# server refuses the table as well (1063).

{
  package K115::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package K115::Schema::Result::Guid;
  use DBIO 'Core', -mysql;
  __PACKAGE__->table('guid_t');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uniqueidentifier', is_auto_increment => 1 },
    alt  => { data_type => 'uniqueidentifier', is_nullable => 1, size => 99 },
    up   => { data_type => 'UniqueIdentifier', is_nullable => 1 },
    n    => { data_type => 'int', is_auto_increment => 0 },
    memo => { data_type => 'clob', is_nullable => 1 },
    cost => { data_type => 'money', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  K115::Schema->register_class(Guid => __PACKAGE__);
}
{
  package K115::Schema::Result::Count;
  use DBIO 'Core', -mysql;
  __PACKAGE__->table('count_t');
  __PACKAGE__->add_columns(id => { data_type => 'int', is_auto_increment => 1 });
  __PACKAGE__->set_primary_key('id');
  K115::Schema->register_class(Count => __PACKAGE__);
}

my $ddl = DBIO::MySQL::DDL->install_ddl('K115::Schema');
my ($guid)  = grep { /`guid_t`/ } split /\n\n/, $ddl;
my ($count) = grep { /`count_t`/ } split /\n\n/, $ddl;

unlike $guid, qr/uniqueidentifier/i, 'the server has no such type, it is not written';
like $guid, qr/^\s*`id` varchar\(36\) NOT NULL,$/m, 'a: the key is VARCHAR(36), without AUTO_INCREMENT';
like $guid, qr/^\s*`alt` varchar\(36\),$/m, 'b: a size on it does not move the width';
like $guid, qr/^\s*`up` varchar\(36\),$/m, 'c: the type name is read case-insensitive';
unlike $guid, qr/AUTO_INCREMENT/, 'd: no AUTO_INCREMENT on a string column';
like $count, qr/`id` int NOT NULL AUTO_INCREMENT/i, 'e: an integer column keeps AUTO_INCREMENT';

# The shared test schema declares two more names the server does not know,
# found when it was deployed live (t/142): clob and money.
like $guid, qr/^\s*`memo` longtext,$/m, 'f: clob is LONGTEXT';
like $guid, qr/^\s*`cost` decimal\(19,4\),$/m, 'g: money is DECIMAL(19,4)';

done_testing;
