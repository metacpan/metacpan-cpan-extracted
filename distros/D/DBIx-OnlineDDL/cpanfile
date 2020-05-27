requires 'Class::Load';
requires 'DBI::Const::GetInfoType';
requires 'DBIx::BatchChunker';
requires 'Eval::Reversible';
requires 'List::Util', '1.44';
requires 'Moo';
requires 'MooX::StrictConstructor';
requires 'Sub::Util';
requires 'Term::ProgressBar';
requires 'Types::Common::Numeric';
requires 'Types::Standard';
requires 'namespace::clean';
requires 'warnings';

on test => sub {
    requires 'base';
    requires 'parent';
    requires 'lib';
    requires 'strict';
    requires 'utf8';

    requires 'DBI';
    requires 'DBIx::Class::Core';
    requires 'DBIx::Class::Schema';
    requires 'Env';
    requires 'Exporter';
    requires 'Import::Into';
    requires 'Path::Class';
    requires 'Path::Class::File';
    requires 'Test2::Bundle::More';
    requires 'Test2::Tools::Compare';
    requires 'Test2::Tools::Exception';
    requires 'Test2::Tools::Explain';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
    requires 'File::Find';
    requires 'Test2::Require::AuthorTesting';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Strict';
    requires 'Test::Version';
};
