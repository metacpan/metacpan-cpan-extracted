use inc::Module::Install;

name "Catalyst-View-CSV";
all_from "lib/Catalyst/View/CSV.pm";
license "perl";
build_requires "Test::More";
build_requires "Test::Exception";
build_requires "Catalyst";
build_requires "Catalyst::Controller";
build_requires "Catalyst::Action::RenderView";
build_requires "Catalyst::Test";
build_requires "CatalystX::Component::Traits"; # for Catalyst::Test
build_requires "Catalyst::Model::DBIC::Schema";
build_requires "Catalyst::Plugin::ConfigLoader";
build_requires "Config::General";
build_requires "DBIx::Class";
build_requires "DBIx::Class::Schema";
build_requires "DBD::SQLite";
build_requires "FindBin";
build_requires "Moose";

requires "Catalyst::View";
requires "Text::CSV";
recommends "Text::CSV_XS";
requires "URI";

WriteAll;
