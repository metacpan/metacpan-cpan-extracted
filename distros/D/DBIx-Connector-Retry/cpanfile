requires 'DBIx::Connector';
requires 'Moo';
requires 'Scalar::Util';
requires 'Types::Common::Numeric';
requires 'Types::Standard';
requires 'namespace::clean';
requires 'strict';
requires 'warnings';

on test => sub {
    requires 'DBI';
    requires 'DBD::SQLite';
    requires 'Path::Class';
    requires 'Test2::Bundle::More';
    requires 'Test2::Tools::Compare';
    requires 'Test2::Tools::Exception';
    requires 'Test2::Tools::Explain';
    requires 'lib';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
    requires 'Test2::Require::AuthorTesting';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Strict';
    requires 'Test::Version';
};
