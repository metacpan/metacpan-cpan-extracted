use 5.010;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'App-AutoCRUD';
all_from 'lib/App/AutoCRUD.pm';
author   q{Laurent Dami <dami@cpan.org>};
license  'artistic2';

perl_version 5.010;

tests_recursive('t');

resources (
   homepage   => 'https://metacpan.org/author/DAMI',
   #IRC        => 'irc://irc.perl.org/#App-AutoCRUD',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git://github.com/damil/App-AutoCRUD.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-AutoCRUD',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

test_requires (
  'DBD::SQLite'                    => 1.39, # for foreign key support
);


requires (
  'Alien::GvaScript'               => 1.43,
  'Archive::Zip'                   => 0,
  'Carp'                           => 0,
  'CGI::Expand'                    => 0,
  'Clone'                          => 0,
  'Cwd'                            => 0,
  'Data::Domain'                   => 0,
  'Data::Dumper'                   => 0,
  'Data::Reach'                    => 1.00,
  'DBI'                            => 0,
  'DBIx::DataModel'                => 2.42,
  'Encode'                         => 0,
  'Excel::Writer::XLSX'            => 0,
  'HTTP::Date'                     => 0,
  'JSON::MaybeXS'                  => 0,
  'List::MoreUtils'                => 0,
  'Moose'                          => 0,
  'MooseX::NonMoose'               => 0.26,
  'MooseX::SemiAffordanceAccessor' => 0,
  'Path::Tiny'                     => 0,
  'Plack'                          => 0,
  'Scalar::Does'                   => 0,
  'Scalar::Util'                   => 0,
  'SQL::Abstract::FromQuery'       => 0.10,
  'SQL::Abstract::More'            => 1.27,
  'Template'                       => 0,
  'Time::HiRes'                    => 0,
  'Try::Tiny'                      => 0,
  'URI'                            => 0,
  'URI::Escape'                    => 0,
  'XML::Simple'                    => 0,
  'YAML::Any'                      => 0,
  'namespace::clean'               => 0,
  'parent'                         => 0,
);

install_as_cpan;
auto_install;
WriteAll;
