use strict;
use warnings;

use English qw{ −no_match_vars };

use Module::Build;


my $class = Module::Build->subclass( code => <<'SUBCLASS' );

    sub ACTION_authortest {
        my $self = shift;

        $self->depends_on('build');
        $self->depends_on('manifest');
        $self->depends_on('distmeta');
        $self->recursive_test_files(1);
        $self->depends_on('test');
    } # end ACTION_authortest()

SUBCLASS

my $builder = $class->new(
    module_name     => 'Acme::MetaSyntactic::nethack',
    license         => 'perl',
    dist_author     => 'Elliot Shank <perl@galumph.com>',
    dynamic_config  => 0,
    build_requires  => {
        'version'           => 0,
        'Test::More'        => 0,
        'File::Find::Rule'  => 0,
    },
    requires => {
        'version'               => 0,
        'Acme::MetaSyntactic'   => 0.99,
    },
    recommends      => {
        'File::Slurp'                   => 0,
        'Perl::Critic'                  => 0,
        'Pod::Coverage::CountParents'   => 0,
        'Test::Differences'             => 0,
        'Test::Distribution'            => 0,
        'Test::Perl::Critic'            => 0,
        'Test::Pod'                     => 0,
        'Test::Pod::Coverage'           => 0,
        'Test::Spelling'                => 0,
    },
    script_files       => [ glob('script/*') ],
    create_packlist    => 1,
    sign               => 0,
    create_makefile_pl => 'passthrough',
    add_to_cleanup      => [
        qw{
            MANIFEST
            MANIFEST.bak
            META.yml
            Makefile
            Makefile.PL
            *.nethack_backup
            pod2htm?.tmp
            Acme-MetaSyntactic-nethack-*
        }
    ],
);

$builder->create_build_script();

# setup nethack: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup nethack: shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup nethack: set foldmethod=indent foldlevel=0 :
