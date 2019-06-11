requires 'DBIx::Class';

on 'test' => sub {
    requires 'DBD::SQLite';
    requires 'DBIx::Class::Core';
    requires 'DBIx::Class::Schema';

    requires 'JSON::PP';
    requires 'Test::Mock::Time';
    requires 'DateTime';
    requires 'DateTime::Format::SQLite';

    requires 'Pod::Coverage::TrustPod';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
};

on 'develop' => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};

1;
