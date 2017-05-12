use Test::Most tests => 10;

die_on_fail;

use Config;

my $obj = {
   results => [
      {
         address_components => [
            {
               long_name  => 1600,
               short_name => 1600,
               types      => [ 'street_number' ]
            },
            {
               long_name  => "President's Park",
               short_name => "President's Park",
               types      => [ 'establishment' ]
            },
            {
               long_name  => 'Pennsylvania Avenue Northwest',
               short_name => 'Pennsylvania Ave NW',
               types      => [ 'route' ]
            },
            {
               long_name  => 'Washington',
               short_name => 'Washington',
               types      => [ 'locality', 'political' ]
            },
            {
               long_name  => 'District of Columbia',
               short_name => 'DC',
               types      => [ 'administrative_area_level_1', 'political' ]
            },
            {
               long_name  => 'United States',
               short_name => 'US',
               types      => [ 'country', 'political' ]
            },
            {
               long_name  => 20500,
               short_name => 20500,
               types      => [ 'postal_code' ]
            },
            # Extra thing for undef/dupe checking
            {
               long_name  => undef,
               short_name => undef,
               types      => [ 'administrative_area_level_1', 'political' ]
            },
         ],
         formatted_address => "1600 Pennsylvania Avenue Northwest, President's Park, Washington, DC 20500, USA",
         geometry => {
            location => {
               lat => 38.8970960,
               lng => -77.03654499999999
            },
            location_type => 'ROOFTOP',
            viewport => {
               northeast => {
                  lat => 38.89844498029149,
                  lng => -77.03519601970849
               },
               southwest => {
                  lat => 38.89574701970849,
                  lng => -77.03789398029150
               }
            }
         },
         types => [ 'street_address' ]
      }
   ],
   status => 'OK'
};

BEGIN { use_ok('DBI'); }

my $dbh = DBI->connect('dbi:TreeData:', '', '', {
   tree_table_name => 'geocode',
   tree_data       => $obj,
});
isa_ok($dbh, 'DBI::db');
restore_fail;

is_deeply( $dbh->table_info->fetchall_arrayref(), [
   [undef, undef, 'type_groups',              'TABLE', 'AnyData'],
   [undef, undef, 'types',                    'TABLE', 'AnyData'],
   [undef, undef, 'address_component_groups', 'TABLE', 'AnyData'],
   [undef, undef, 'southwests',               'TABLE', 'AnyData'],
   [undef, undef, 'locations',                'TABLE', 'AnyData'],
   [undef, undef, 'address_components',       'TABLE', 'AnyData'],
   [undef, undef, 'result_groups',            'TABLE', 'AnyData'],
   [undef, undef, 'northeasts',               'TABLE', 'AnyData'],
   [undef, undef, 'viewports',                'TABLE', 'AnyData'],
   [undef, undef, 'geocode',                  'TABLE', 'AnyData'],
   [undef, undef, 'geometries',               'TABLE', 'AnyData'],
   [undef, undef, 'results',                  'TABLE', 'AnyData'],
], 'table_info');

my $nbits = $Config{ptrsize} * 16 - 11;

is_deeply([ map { [ @{$_}[2 .. 6] ] } @{
   $dbh->column_info('','','','')->fetchall_arrayref
} ], [

   [qw( address_component_groups address_component_group_id PID    4  32         )],
   [qw( address_component_groups address_component_id       ID     4  32         )],

   [qw( address_components       address_component_id       PID    4  32         )],
   [qw( address_components       long_name                  STRING 12 2147483648 )],
   [qw( address_components       short_name                 STRING 12 2147483648 )],
   [qw( address_components       type_group_id              ID     4  32         )],

   [qw( geocode                  geocode_id                 PID    4  32         )],
   [qw( geocode                  result_group_id            ID     4  32         )],
   [qw( geocode                  status                     STRING 12 2147483648 )],

   [qw( geometries               geometry_id                PID    4  32         )],
   [qw( geometries               location_id                ID     4  32         )],
   [qw( geometries               location_type              STRING 12 2147483648 )],
   [qw( geometries               viewport_id                ID     4  32         )],

   [qw( locations                location_id                PID    4  32         )],
   [qw( locations                lat                        NUMBER 2), $nbits     ],
   [qw( locations                lng                        NUMBER 2), $nbits     ],

   [qw( northeasts               northeast_id               PID    4  32         )],
   [qw( northeasts               lat                        NUMBER 2), $nbits     ],
   [qw( northeasts               lng                        NUMBER 2), $nbits     ],

   [qw( result_groups            result_group_id            PID    4  32         )],
   [qw( result_groups            result_id                  ID     4  32         )],

   [qw( results                  result_id                  PID    4  32         )],
   [qw( results                  address_component_group_id ID     4  32         )],
   [qw( results                  formatted_address          STRING 12 2147483648 )],
   [qw( results                  geometry_id                ID     4  32         )],
   [qw( results                  type_group_id              ID     4  32         )],

   [qw( southwests               southwest_id               PID    4  32         )],
   [qw( southwests               lat                        NUMBER 2), $nbits     ],
   [qw( southwests               lng                        NUMBER 2), $nbits     ],

   [qw( type_groups              type_group_id              PID    4  32         )],
   [qw( type_groups              type_id                    ID     4  32         )],

   [qw( types                    type_id                    PID    4  32         )],
   [qw( types                    type                       STRING 12 2147483648 )],

   [qw( viewports                viewport_id                PID    4  32         )],
   [qw( viewports                northeast_id               ID     4  32         )],
   [qw( viewports                southwest_id               ID     4  32         )],

], 'column_info');

is_deeply( $dbh->primary_key_info('','','address_components')->fetchall_arrayref, [
   [undef, undef, 'address_components', 'address_component_id', 1, 'address_component_id_pkey']
], 'address_components primary keys');

### Foreign key info ###
is_deeply( $dbh->foreign_key_info('','','address_components','','','address_component_groups')->fetchall_arrayref, [
   [
      undef, undef, 'address_components', 'address_component_id',
      undef, undef, 'address_component_groups', 'address_component_id',
      1, 3, 3,
      'address_component_groups_address_component_id_fkey',
      'address_component_id_pkey',
      7,
      'PRIMARY',
   ],
], 'address_components PK+FK foreign keys');

is_deeply( $dbh->foreign_key_info('','','address_components','','','')->fetchall_arrayref, [
   [
      undef, undef, 'address_components', 'address_component_id',
      undef, undef, 'address_component_groups', 'address_component_id',
      1, 3, 3,
      'address_component_groups_address_component_id_fkey',
      'address_component_id_pkey',
      7,
      'PRIMARY',
   ],
   [
      undef, undef, 'address_components', 'address_component_id',
      undef, undef, 'address_components', 'address_component_id',
      1, 3, 3,
      'address_components_address_component_id_fkey',
      'address_component_id_pkey',
      7,
      'PRIMARY',
   ],
], 'address_components PK foreign keys');

is_deeply( $dbh->foreign_key_info('','','','','','results')->fetchall_arrayref, [
   [
      undef, undef, 'address_component_groups', 'address_component_group_id',
      undef, undef, 'results', 'address_component_group_id',
      1, 3, 3,
      'results_address_component_group_id_fkey',
      'address_component_group_id_pkey',
      7,
      'PRIMARY',
   ],
   [
      undef, undef, 'geometries', 'geometry_id',
      undef, undef, 'results', 'geometry_id',
      1, 3, 3,
      'results_geometry_id_fkey',
      'geometry_id_pkey',
      7,
      'PRIMARY',
   ],
   [
      undef, undef, 'type_groups', 'type_group_id',
      undef, undef, 'results', 'type_group_id',
      1, 3, 3,
      'results_type_group_id_fkey',
      'type_group_id_pkey',
      7,
      'PRIMARY',
   ],
], 'results FK foreign keys');

is_deeply( $dbh->statistics_info('','','address_components',0,0)->fetchall_arrayref, [
   [
      undef, undef, 'address_components', 0, undef, undef, 'table',
      undef, undef, undef, 8, undef, undef
   ],
   [
      undef, undef, 'address_components', 0, undef, 'address_component_id_pkey', 'content',
      1, 'address_component_id', 'A', 8, undef, undef
   ],
], 'address_components statistics');

is_deeply( $dbh->selectall_arrayref('SELECT * FROM address_components'), [
   [1, 1600,                            1600,                  2],
   [2, "President's Park",              "President's Park",    3],
   [3, 'Pennsylvania Avenue Northwest', 'Pennsylvania Ave NW', 4],
   [4, 'Washington',                    'Washington',          5],
   [5, 'District of Columbia',          'DC',                  6],
   [6, 'United States',                 'US',                  7],
   [7, 20500,                           20500,                 8],
   [8, undef,                           undef,                 6],
], 'address_components SELECT');

### TODO: CRUD operations ###
