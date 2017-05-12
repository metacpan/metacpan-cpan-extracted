use strict;
use warnings;

use inc::Module::Install;

# Define metadata
name 'CatalystX-CRUD-YUI';
perl_version '5.008003';

all_from 'lib/CatalystX/CRUD/YUI.pm';

requires 'Test::More'                            => 0;
requires 'Path::Class'                           => 0;
requires 'Template'                              => 0;
requires 'Text::Autoformat'                      => 0;
requires 'Catalyst::View::TT'                    => 0;
requires 'Catalyst::Plugin::Static::Simple'      => 0;
requires 'Catalyst::Plugin::ConfigLoader'        => 0;
requires 'Config::General'                       => 0;
requires 'Catalyst::Action::RenderView'          => 0;
requires 'CatalystX::CRUD'                       => 0.53;
recommends 'CatalystX::CRUD::Model::RDBO'        => 0.23;
recommends 'CatalystX::CRUD::ModelAdapter::DBIC' => 0.08;
recommends 'Rose::DBx::Object::MoreHelpers'      => 0.06;
recommends 'DBIx::Class::RDBOHelpers'            => 0.08;
requires 'Rose::HTMLx::Form::Related'            => 0.17;
requires 'CatalystX::CRUD::Controller::RHTMLO'   => 0.19;
requires 'CatalystX::CRUD::View::Excel'          => 0.06;
requires 'Scalar::Util'                          => 0;
requires 'MRO::Compat'                           => 0;
requires 'JSON::XS'                              => 2.23;
requires 'Template::Plugin::Handy'               => 0.002;
requires 'Template::Plugin::Autoformat'          => '2.75';
requires 'Class::Inspector'                      => 0;
requires 'Search::Tools'                         => '1.000';

license 'perl';
homepage 'https://github.com/karpet/catalystx-crud-yui';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD-YUI';
repository 'https://github.com/karpet/catalystx-crud-yui';

WriteAll;

