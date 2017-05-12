
use strict;
use warnings;

use Test::More;
use Path::Tiny;
require DBI;
require DBD::SQLite;
require DBIx::Class::InflateColumn::Serializer;
require DBIx::Class::Core;
require DBIx::Class::InflateColumn::Serializer::Sereal;

{

  package Test::Schema::Result::Item;
  use parent 'DBIx::Class::Core';

  __PACKAGE__->load_components( 'InflateColumn::Serializer', 'Core' );
  __PACKAGE__->table('item');
  __PACKAGE__->add_column( itemid => { data_type => 'integer' }, );
  __PACKAGE__->set_primary_key('itemid');
  __PACKAGE__->add_column(
    data => {
      data_type        => 'text',
      serializer_class => 'Sereal',
    }
  );
  __PACKAGE__->source_name('Item');
  $INC{'Test/Schema/Result/Item.pm'} = 1;
}
{

  package Test::Schema;
  use parent 'DBIx::Class::Schema';
  __PACKAGE__->load_classes('Result::Item');
  $INC{'Test/Schema.pm'} = 1;
}

my $wd = Path::Tiny->tempdir;

my $db_path = $wd->child('my.db');
my $cstr    = 'dbi:SQLite:' . $db_path;

{
  my $dbh = DBI->connect($cstr);
  my $sth = $dbh->prepare('CREATE TABLE item ( itemid, data )');
  $sth->execute();
}
my $schema = Test::Schema->connect($cstr);

{

  package Test::MockItem;

  sub new {
    my $class = shift;
    return bless {@_}, $class;
  }

  sub good {
    return 1 if $_[0]->{good};
    return;
  }
}
$schema->resultset('Item')->create(
  {
    itemid => 1,
    data   => Test::MockItem->new( good => '1' ),
  }
);

my $item = $schema->resultset('Item')->search( { itemid => 1 } )->first;
can_ok( $item, 'data' );
my $data = $item->data;
can_ok( $data, 'good' );
ok( $data->good, "blessed item works still" );

done_testing;

