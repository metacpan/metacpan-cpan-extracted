requires 'perl', '5.036';
requires 'Carp';
requires 'DBI';
requires 'Data::Dumper';
requires 'Digest::SHA';
requires 'Ekorn::Pipeline', '>= v0.5.0, < v0.6.0';
requires 'Exporter';
requires 'List::Util';
requires 'Ref::Util';
requires 'Sub::Util';
requires 'experimental';
requires 'namespace::clean';

# Ekorn::Pipeline's dump_to redacts the secrets it finds when this is
# installed (Ekorn 2026-0038); installers don't follow a dependency's
# recommendations, so ours names it too.
recommends 'Text::Redact::Secrets', '>= v1.0.0, < v2.0.0';

# Ekorn::Pipeline::CSV's from_csv and to_csv, which Tooling exports in
# :csv, read and write with it, and load it only when they're called
# (roadmap 2026-0044).
recommends 'Text::CSV';

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
    requires 'Pod::Markdown::Github';
    requires 'Test2::Harness';
    requires 'Test2::Plugin::Cover';
    requires 'Test::Spellunker';
    requires 'Text::CSV';
    requires 'UUID';
};
