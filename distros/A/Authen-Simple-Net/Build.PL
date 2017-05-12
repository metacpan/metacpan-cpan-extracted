use strict;
use Module::Build;

my $build = Module::Build->new(
    license            => 'perl',
    module_name        => 'Authen::Simple::Net',
    dist_name          => 'Authen-Simple-Net',
    dist_version       => 0.2,    
    dist_author        => 'Christian Hansen <ch@ngmedia.com>',
    dist_abstract      => 'libnet Authen::Simple adapters',
    requires           => {
        'Authen::Simple' => 0,
        'Net::FTP'       => 0,
        'Net::POP3'      => 0,
        'Net::SMTP'      => 0
    },
    create_makefile_pl => 'traditional',
    create_readme      => 1
);

$build->create_build_script;
