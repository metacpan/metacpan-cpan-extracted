use strict;
use warnings;
use inc::Module::Install 0.91;

name 'Catalyst-Plugin-Bread-Board';
all_from 'lib/Catalyst/Plugin/Bread/Board.pm';
license 'perl';

# prereqs
requires 'Moose'                      => '1.00';
requires 'Bread::Board'               => '0.13';
requires 'MooseX::Types::Path::Class' => '0';
requires 'Catalyst'                   => '0';

# things the tests need
build_requires 'Test::More'      => '0.62';
build_requires 'Test::Exception' => '0.21';

# for the catalyst test ..
build_requires 'Catalyst::Action::RenderView'  => '0';
build_requires 'Catalyst::View::TT'            => '0';
build_requires 'Catalyst::Model::DBIC::Schema' => '0';

tests('t/*.t');

WriteAll();

