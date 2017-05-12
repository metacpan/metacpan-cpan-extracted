use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Plugin::Session::FastMmap',
    AUTHOR    => 'Sebastian Riedel (sri@oook.de)',
    PREREQ_PM => {
        Catalyst                 => '2.99',
        Cache::FastMmap          => 0,
        Class::Accessor::Fast    => 0,
        Class::Data::Inheritable => 0,
        Digest::MD5              => 0,
        URI                      => 0,
        URI::Find                => 0,
        File::Temp               => 0,
        MRO::Compat              => 0,
    },
    VERSION_FROM => 'FastMmap.pm'
);
