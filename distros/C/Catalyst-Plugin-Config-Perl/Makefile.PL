use strict;
use Panda::Install;

write_makefile(
    NAME          => 'Catalyst::Plugin::Config::Perl',
    VERSION_FROM  => 'lib/Catalyst/Plugin/Config/Perl.pm',
    ABSTRACT_FROM => 'lib/Catalyst/Plugin/Config/Perl.pod',
    PREREQ_PM     => {
        'Panda::Lib'                     => 0,
        'Panda::Config::Perl'            => 0,
        'Class::Accessor::Inherited::XS' => '0.07',
        'Catalyst::Runtime'              => 0,
    },
);
