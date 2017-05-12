# $Id: Makefile.PL,v 1.1.1.1 1998/09/11 07:49:57 don Exp $

use ExtUtils::MakeMaker;

eval "use Image::Magick ();";
if ($@) {
    print <<"EndOfMSG";
*** Warning:
    The throttleimg script that comes with Apache::Throttle requires
    the Image::Magick module, which does not seem to be installed.
    You can get it from http://www.cpan.org if you wish to use this
    script.  (It is optional, you don't need the script to run
    Apache::Throttle, but it is recommended to have it just in case).

EndOfMSG
    sleep 3;
}

eval "use Time::HiRes ();";
if ($@) {
    print <<"EndOfMSG";
*** Warning:
    The Time::HiRes module is not installed.  Without it,
    Apache::Throttle::Log will still function, but will only be able
    to record the time of a request to the nearest whole second.
    It is recommended that you install Time::HiRes if you plan to use
    Apache::Throttle::Log.

EndOfMSG
    sleep 3;
}

WriteMakefile(
    'NAME'	=> 'Apache::Throttle',
    'VERSION_FROM' => 'Throttle.pm',
    'EXE_FILES' => ["throttleimg"],
    'PREREQ_PM' => { 'Apache' => '0',
                     'IPC::Shareable' => '0',
                   },
    'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
);
