use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass( code => <<'EOF');
        eval { require Locale::Msgfmt; Locale::Msgfmt->import(); };
        sub process_mo_files {
                die("requires Locale::Msgfmt") if(! $INC{'Locale/Msgfmt.pm'});
                msgfmt({
                        in => "share/locale/",
                        out => "blib/share/locale/"});
        }
EOF
my $builder = $class->new(
    module_name         => 'Acme::Padre::PlayCode',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Acme/Padre/PlayCode.pm',
    build_requires => {
        'Test::More' => 0,
        'Locale::Msgfmt'   => '0.14',
    },
    requires => {
        'Acme::PlayCode' => 0,
        'Padre'          => '0.43',
    },
    add_to_cleanup      => [ 'Acme-Padre-PlayCode-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Acme-Padre-PlayCode/',
        }
    },
);

$builder->add_build_element('mo');
$builder->create_build_script();
