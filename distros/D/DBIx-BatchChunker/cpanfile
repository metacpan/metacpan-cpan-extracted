requires 'CLDR::Number';
requires 'DBIx::Connector::Retry';
requires 'List::Util', '1.33';          # has any/all/etc.
requires 'Moo', '2.00';                 # sane minimum baseline
requires 'MooX::StrictConstructor';
requires 'POSIX';
requires 'Scalar::Util';
requires 'Term::ProgressBar', '2.14';   # with silent option
requires 'Time::HiRes';
requires 'Type::Utils';
requires 'Types::Numbers', 'v1.0.0';    # has T:C:N aliases
requires 'Types::Standard', '1.00';     # sane minimum baseline
requires 'namespace::clean';

on test => sub {
    requires 'Class::Load';
    requires 'DBIx::Class', '0.07000';  # sane minimum baseline
    requires 'Env';
    requires 'Path::Class';
    requires 'Path::Class::File';
    requires 'Test2::Bundle::More';
    requires 'Test2::Tools::Compare';
    requires 'Test2::Tools::Exception';
    requires 'Test2::Tools::Explain';
    requires 'base';
    requires 'lib';
    requires 'strict';
    requires 'utf8';
    requires 'warnings';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
    requires 'Test2::Require::AuthorTesting';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Strict';
    requires 'Test::Version';
};
