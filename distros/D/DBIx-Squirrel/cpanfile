requires 'perl', '5.036';
requires 'Carp';
requires 'DBI';
requires 'Data::Dumper';
requires 'Digest::SHA';
requires 'Ekorn::Pipeline', '>= v0.2.0, < v0.3.0';
requires 'Exporter';
requires 'List::Util';
requires 'Ref::Util';
requires 'Scalar::Util';
requires 'Sub::Util';
requires 'experimental';
requires 'namespace::clean';

on test => sub {
    requires 'DBD::SQLite';
    requires 'Test2::V0';
    requires 'Test2::Plugin::NoWarnings';
};

on develop => sub {
    requires 'CPAN::Uploader';
    requires 'Data::Dump';
    requires 'Devel::Cover';
    requires 'Devel::NYTProf';
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
    requires 'Pod::Coverage';
    requires 'Test2::Harness';
    requires 'Test2::Plugin::Cover';
    requires 'Test::Spellunker';
    requires 'UUID';
};
