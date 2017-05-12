use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Helper::Graphics',
    AUTHOR    => 'J. Shirley <jshirley@gmail.com>',
    PREREQ_PM => {
        'Catalyst'            => '5.00',
        'File::Spec'          => 0,
    },
    dist => {
        PREOP => 'script/pack_images.pl',
    },
    VERSION_FROM => 'lib/Catalyst/Helper/Graphics.pm'
);

