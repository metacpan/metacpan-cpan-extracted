use strict;
use XS::Install;

write_makefile(
    NAME      => 'Catalyst::Plugin::Config::Perl',
    PREREQ_PM => {
        'Panda::Config::Perl'            => 0,
        'Class::Accessor::Inherited::XS' => '0.07',
        'Catalyst::Runtime'              => 0,
    },
);
