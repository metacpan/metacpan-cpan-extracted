# Add your requirements here
requires 'perl', 'v5.10.0'; # for kwalitee

# Direct requirements
requires 'Context::Preserve';
requires 'Algorithm::Backoff::RetryTimeouts';
requires 'DBIx::ParseError::MySQL';
requires 'namespace::clean';

# Indirect (or bundled) requirements
requires 'DBI', '1.630';
requires 'DBD::mysql';
requires 'DBIx::Class';

# Test requirements
on test => sub {
    requires 'Class::Load';
    requires 'Path::Class';
    requires 'Test2::Suite';
    requires 'Test2::Tools::Explain';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
