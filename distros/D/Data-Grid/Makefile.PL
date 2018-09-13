use strict;
use warnings;
use inc::Module::Install;

name     'Data-Grid';
abstract  'Data::Grid provides basic, incremental access to grid-shaped data.';
readme_from 'lib/Data/Grid.pm';
all_from 'lib/Data/Grid.pm';

resources (
   homepage   => 'https://github.com/doriantaylor/p5-data-grid',
   license    => 'http://www.apache.org/licenses/LICENSE-2.0',
   repository => 'git://github.com/doriantaylor/p5-data-grid.git',
   bugtracker => 'https://github.com/doriantaylor/p5-data-grid/issues',
);

# metaobject/housekeepy stuff
requires 'Moo'                   => '2.0';
requires 'Type::Tiny'            => '1.0';
requires 'Types::XSD::Lite'      => '0.005';
requires 'Class::Load'           => '0.23';
requires 'String::RewritePrefix' => '0.007';

# actual do-the-job stuff

requires 'IO::Scalar'              => '2.110';
requires 'IO::ScalarArray'         => '2.110';
requires 'Spreadsheet::ParseExcel' => '0.65';
requires 'Spreadsheet::ParseXLSX'  => '0.27';
requires 'Text::CSV'               => '1.18';

# ugh god cpants is gonna whine without these

test_requires 'File::MMagic'   => '1.27';
test_requires 'File::MimeInfo' => '0.27';

# don't strictly need these but they are useful

recommends 'Text::CSV_XS'   => '1.18';
recommends 'File::MMagic'   => '1.27';
recommends 'File::MimeInfo' => '0.27';
recommends 'Data::Table'    => '1.54';

auto_install;
WriteAll;
