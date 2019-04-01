package MyApp::Schema::Result::CdEvent;

use warnings;
use strict;
use JSON::PP ();

use base qw( DBIx::Class::Core );

__PACKAGE__->load_components(qw/ InflateColumn::DateTime /);

__PACKAGE__->table('cd_event');

__PACKAGE__->add_columns(
  cdeventid => {
    data_type => 'integer',
    is_auto_increment => 1
  },
  cdid => {
    data_type => 'integer',
  },
  event => {
    data_type => 'varchar',
  },
  triggered_on => {
    data_type => 'datetime', default_value => \'NOW()',
  },
  details => {
    data_type => 'longtext',
  },
);

__PACKAGE__->set_primary_key('cdeventid');

{
    my $json = JSON::PP->new->utf8;
    __PACKAGE__->inflate_column( 'details' => {
        inflate => sub { $json->decode(shift) },
        deflate => sub { $json->encode(shift) },
    } );
}

#__PACKAGE__->add_unique_constraint([qw( )]);

__PACKAGE__->belongs_to('cd' => 'MyApp::Schema::Result::Cd', 'cdid');

1;
