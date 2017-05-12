requires 'DBI', '1.605';
requires 'DBIx::TransactionManager', '1.09';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Test::More';
    requires 'Test::Requires';
    requires 'Test::SharedFork', '0.16';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
