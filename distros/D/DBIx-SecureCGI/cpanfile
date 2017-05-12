requires 'perl', '5.010001';

requires 'AnyEvent';
requires 'AnyEvent::DBI::MySQL', 'v1.0.2';
requires 'DBD::mysql';
requires 'DBI';
requires 'List::Util', '1.33';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Data::Dumper';
    requires 'Test::Database';
    requires 'Test::Exception';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
