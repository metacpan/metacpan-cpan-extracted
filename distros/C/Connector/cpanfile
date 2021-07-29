requires 'Log::Log4perl';
requires 'Moose';
requires 'perl', '5.010001';
recommends 'Config::Std';
recommends 'Config::Versioned', '0.5';
recommends 'DBI';
recommends 'IO::Socket::SSL';
recommends 'JSON';
recommends 'LWP::Protocol::https';
recommends 'LWP::UserAgent';
recommends 'Net::LDAP';
recommends 'Proc::SafeExec';
recommends 'Template';
recommends 'Text::CSV_XS';
recommends 'YAML';

on build => sub {
    requires 'Config::Merge';
    requires 'Config::Std';
    requires 'Config::Versioned';
    requires 'DBD::SQLite';
    requires 'DBI';
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'IO::Socket::SSL';
    requires 'JSON';
    requires 'LWP::Protocol::https';
    requires 'LWP::UserAgent';
    requires 'Proc::SafeExec';
    requires 'Template';
    requires 'Test::More';
    requires 'YAML';
};

on develop => sub {
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions', '0.04';
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker', 'v0.2.7';
};
