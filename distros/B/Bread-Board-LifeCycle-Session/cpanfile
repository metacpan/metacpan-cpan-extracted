requires 'Module::Runtime';
requires 'Moose::Role';
requires 'namespace::autoclean';

requires 'List::Util', '1.33';

requires 'Bread::Board::LifeCycle::Singleton';
requires 'Bread::Board::LifeCycle::Singleton::WithParameters';

on test => sub {
    requires 'Bread::Board';
    requires 'Moose';
    requires 'Test::Fatal';
};

on develop => sub {
    requires 'Test::Pod';
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
