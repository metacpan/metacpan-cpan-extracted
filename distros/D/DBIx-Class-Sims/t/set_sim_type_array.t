# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing is );

use DBIx::Class::Sims;
BEGIN {
  DBIx::Class::Sims->set_sim_type([
    [ one => qr/on+e/ => sub { 1 } ],
  ]);

  {
    package MyApp::Schema::Result::SimTypeArray;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('sim_type_array');
    __PACKAGE__->add_columns(
      id => {
        data_type => 'int',
        is_nullable => 0,
        is_auto_increment => 1,
      },
      one => {
        data_type => 'int',
        is_nullable => 0,
        sim => { type => 'one' },
      },
      onnnnne => {
        data_type => 'int',
        is_nullable => 0,
        sim => { type => 'onnnnne' },
      },
    );
    __PACKAGE__->set_primary_key('id');
  }


  {
    package MyApp::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->register_class(SimTypeArray => 'MyApp::Schema::Result::SimTypeArray');
    __PACKAGE__->load_components('Sims');
  }
}

use Test::DBIx::Class qw(:resultsets);

{
  my $count = grep { $_ != 0 } map { ResultSet($_)->count } Schema->sources;
  is $count, 0, "There are no tables loaded at first";
}

Schema->load_sims({ SimTypeArray => [{}] });

is( SimTypeArray->count, 1, 'The number of rows is correct' );
my $row = SimTypeArray->first;

is($row->one, 1, 'The one column is correct');
is($row->onnnnne, 1, 'The onnnnne column is correct');

done_testing;
