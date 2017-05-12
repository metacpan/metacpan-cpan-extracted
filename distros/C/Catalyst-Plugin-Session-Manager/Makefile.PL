use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Catalyst::Plugin::Session::Manager',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Session/Manager.pm', # finds $VERSION
    PREREQ_PM         => {
        Storable                 => 0,
        Class::Accessor          => 0,
        Class::Data::Inheritable => 0.04,
        Catalyst                 => 5.3,
        Cache::FastMmap          => 0,
        IO::File                 => 0,
        URI                      => 0,
        URI::Find                => 0,
        NEXT                     => 0,
        UNIVERSAL::require       => 0,
        MIME::Base64             => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Plugin/Session/Manager.pm', # retrieve abstract from module
       AUTHOR         => 'Lyo Kato <lyo.kato@gmail.com>') : ()),
);
