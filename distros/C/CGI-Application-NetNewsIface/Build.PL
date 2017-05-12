use strict;
use warnings;
use Module::Build;

sub tt_inc
{
    return "/usr/share/perl5/data/modules/CGI-Application-NetNewsIface/";
}

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::NetNewsIface',
    license             => 'bsd',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/CGI/Application/NetNewsIface.pm',
    configure_requires => {
        'Module::Build' => '0.37',
    },
    requires => {
        'CGI::Application' => 0,
        'CGI::Application::Plugin::TT' => 0,
        'Class::Accessor' => 0,
        'DBD::SQLite' => 0,
        'DBI' => 0,
        'Net::NNTP' => 0,
        'Test::More' => 0,
        'XML::RSS' => 0,
        perl => '5.008',
        strict => 0,
        warnings => 0,
    },
    add_to_cleanup      => [ 'CGI-Application-NetNewsIface-*' ],
    install_path =>
    {
        templates => tt_inc(),
    },
    templates_files => {
        map { $_ => $_ } glob("templates/*.tt"),
    },
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-cgi-application-netnewsiface/",
        },
    },
);

$builder->add_build_element('templates');
$builder->config_data('templates_install_path' => [tt_inc()]);

$builder->create_build_script();


