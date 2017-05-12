use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::DBIProfile',
    license             => 'perl',
    dist_author         => 'Joshua I Miller <unrtst@cpan.org>',
    dist_version_from   => 'lib/CGI/Application/Plugin/DBIProfile.pm',
    requires => {
        'IO::Scalar'       => 0,
        'Data::JavaScript' => 0,
        'Symbol'           => 0,
        'Test::More'       => 0,
        'CGI::Application' => 4,
        'DBI'              => 1.49,
        'Time::HiRes'      => 0,
        'HTML::Template'   => 2.6,
    },
    recommends => {
        'GD::Graph'        => 0,
        'SVG::TT::Graph'   => 0,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-DBIProfile-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
