use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# OFFLINE half of karr k118 (t/148 has the live half): a relationship whose
# target is a view source writes no FOREIGN KEY.
#
# WHY IT MATTERS. install_ddl wrote a FOREIGN KEY for every belongs_to whose
# target source exists, so Track (DBIO::Test::Schema), which points at the two
# virtual views year1999cds and year2000cds, got a key on a name that is no
# table, and MySQL and MariaDB refused the CREATE TABLE (1824). A foreign key
# cannot reference a view on either server. The relationship stays valid (a
# join still works); only the key is left out, for a virtual view and for a
# real one alike. The diff builds its target by running install_ddl, so one
# fix covers install and diff. A belongs_to to a table keeps its key.

{
  package K118::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package K118::Schema::Result::Base;
  use DBIO 'Core', -mysql;
  __PACKAGE__->table('base_t');
  __PACKAGE__->add_columns(id => { data_type => 'int' });
  __PACKAGE__->set_primary_key('id');
  K118::Schema->register_class(Base => __PACKAGE__);
}
{
  package K118::Schema::Result::RealView;
  use DBIO 'Core', -mysql;
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('real_v');
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM base_t');
  __PACKAGE__->add_columns(id => { data_type => 'int' });
  __PACKAGE__->set_primary_key('id');
  K118::Schema->register_class(RealView => __PACKAGE__);
}
{
  package K118::Schema::Result::VirtView;
  use DBIO 'Core', -mysql;
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('virt_v');
  __PACKAGE__->result_source_instance->is_virtual(1);
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM base_t');
  __PACKAGE__->add_columns(id => { data_type => 'int' });
  __PACKAGE__->set_primary_key('id');
  K118::Schema->register_class(VirtView => __PACKAGE__);
}
{
  package K118::Schema::Result::Child;
  use DBIO 'Core', -mysql;
  __PACKAGE__->table('child_t');
  __PACKAGE__->add_columns(
    id      => { data_type => 'int' },
    base_id => { data_type => 'int' },
    real_id => { data_type => 'int' },
    virt_id => { data_type => 'int' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(base => 'K118::Schema::Result::Base',     'base_id');
  __PACKAGE__->belongs_to(real => 'K118::Schema::Result::RealView', 'real_id');
  __PACKAGE__->belongs_to(virt => 'K118::Schema::Result::VirtView', 'virt_id');
  K118::Schema->register_class(Child => __PACKAGE__);
}

my $ddl = DBIO::MySQL::DDL->install_ddl('K118::Schema');

like $ddl, qr/FOREIGN KEY \(`base_id`\) REFERENCES `base_t`/, 'a: the key to a table stays';
unlike $ddl, qr/REFERENCES `real_v`/,  'b: no key on a real view';
unlike $ddl, qr/REFERENCES `virt_v`/,  'c: no key on a virtual view';
is scalar(() = $ddl =~ /FOREIGN KEY/g), 1, 'd: exactly one key is written';

ok( K118::Schema->source('Child')->relationship_info('virt'),
  'e: the relationship itself is still there' );

done_testing;
