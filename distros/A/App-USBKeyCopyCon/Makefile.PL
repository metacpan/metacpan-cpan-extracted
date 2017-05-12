use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::USBKeyCopyCon',
    AUTHOR              => 'Grant McLean <grantm@cpan.org>',
    VERSION_FROM        => 'lib/App/USBKeyCopyCon.pm',
    ABSTRACT_FROM       => 'lib/App/USBKeyCopyCon.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Moose'           => 0,
        'Gtk2'            => 0,
        'Net::DBus'       => 0,
        'Net::DBus::GLib' => 0,
        'Test::More'      => 0,
    },
    EXE_FILES           => [ qw(bin/usb-key-copy-con) ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-USBKeyCopyCon-*' },
);
