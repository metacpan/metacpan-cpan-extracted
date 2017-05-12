#
# $Id: Build.PL 52 2009-01-06 03:22:31Z jaldhar $
#
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => '<tmpl_var main_module>',
    license             => '<tmpl_var license>',
    dist_author         => '<tmpl_var author> <<tmpl_var email>>',
    dist_version_from   => '<tmpl_var main_pm_file>',
    tmpl_files          => eval {
        my %tmpls; File::Find::find(
            {
                wanted => sub {
                    if ( -f $_ ) {
                        $tmpls{$File::Find::name} = $File::Find::name;
                    }
                },
            },
            '<tmpl_var templatedir>',
        );
        return \%tmpls;
    },
    build_requires => {
        'CGI::Application'              => 4.04,
        'File::Find'                    => 0,      
        'HTML::Template'                => 0,
        'Pod::Coverage'                 => 0.18,
        'Pod::Usage'                    => 0,
        'Test::More'                    => 0,
        'Test::Pod'                     => 1.22,
        'Test::Pod::Coverage'           => 1.08,
        'Test::WWW::Mechanize::CGIApp'  => 0,
    },
    requires => {
        'CGI::Application'              => 4.04,
        'File::Find'                    => 0,      
        'HTML::Template'                => 0,
    },
    add_to_cleanup      => [ '<tmpl_var distro>-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
);

$builder->add_build_element('tmpl');
$builder->create_build_script();

