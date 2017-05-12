use inc::Module::Install;

name 'Bundle-RBO';
perl_version '5.006';
all_from 'lib/Bundle/RBO.pm';
author q{Robert Bohne <rbo@cpan.org>};
license 'perl';
resources(
    repository => {
        url  => 'https://github.com/rbo/Bundle-RBO.git',
        web  => 'https://github.com/rbo/Bundle-RBO',
        type => 'git',
    },
);


requires 'App::Ack'                            => 0;
requires 'App::cpanminus'                      => 0;
requires 'DBI'                                 => 0;
requires 'DBIx::Class'                         => 0;
requires 'DBIx::Class::Schema::Loader'         => 0;
requires 'DBIx::Class::ResultSet::HashRef'     => 0;
requires 'Dist::Zilla::PluginBundle::RBO'      => 0;
requires 'JSON'                                => 0;
requires 'DateTime'                            => 0;
requires 'IO::All'                             => 0;
requires 'JSON'                                => 0;
requires 'Module::Build'                       => 0;
requires 'Module::Install'                     => 0;
requires 'Moose'                               => 0;
requires 'Template'                            => 0;
requires 'Template::Provider::FromDATA'        => 0;
requires 'Term::ReadLine::Gnu'                 => 0;
requires 'local::lib'                          => 0;
requires 'YAML'                                => 0;
requires 'LWP'                                 => 0;


auto_install;

WriteAll;