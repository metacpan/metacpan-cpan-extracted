#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $data = CLASS->new(
  mount => ['t/fixtures/class-mileage-targets'],
  parse => 'mileage_targets.sii',
)->data;

my %oklacity = $data->{mileage}{ok_oklacity}->%*;
is $oklacity{default_name},    'Oklahoma City',       'oklacity default_name';
is $oklacity{distance_offset}, '2',                   'oklacity distance_offset';
is $oklacity{editor_name},     'OK Oklahoma City',    'oklacity editor_name';
is $oklacity{names},           ['Okla. City'],        'oklacity names';
is $oklacity{node_uid},        'nil',                 'oklacity node_uid';
is $oklacity{position}, '-7257.50342, 21.5687733, 19497.7188', 'oklacity position';
is $oklacity{search_radius},   '50',                  'oklacity search_radius';
is $oklacity{variants},        ['okla_city'],         'oklacity variants';

my %seiling = $data->{mileage}{ok_seiling}->%*;
is $seiling{default_name},     'Seiling',             'seiling default_name';
is $seiling{distance_offset},  '2.5',                 'seiling distance_offset';
is $seiling{editor_name},      'OK Seiling',          'seiling editor_name';
is $seiling{names},            '0',                   'seiling names';
is $seiling{node_uid},         '5427112652697371218', 'seiling node_uid';
is $seiling{position},         'Inf, Inf, Inf',       'seiling position';
is $seiling{search_radius},    '-1',                  'seiling search_radius';
is $seiling{variants},         '0',                   'seiling variants';

done_testing;
