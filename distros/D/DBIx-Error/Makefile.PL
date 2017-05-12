use inc::Module::Install;

name "DBIx-Error";
license "perl";
all_from "lib/DBIx/Error.pm";
test_requires "Test::More";
test_requires "Test::Exception";
test_requires "Test::Moose";
test_requires "DBI";
test_requires "DBD::SQLite";
test_requires "DBIx::Class";
test_requires "DBIx::Class::Schema";
test_requires "FindBin";
test_requires "File::Spec::Functions";

requires "Moose";
requires "MooseX::StrictConstructor";
requires "namespace::autoclean";
requires "Throwable::Error";

WriteAll;
