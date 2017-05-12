use ExtUtils::MakeMaker;

# AnyEvent perl event loop seems to work with 5.6, other modules not
eval 'use Canary::Stability AnyEvent => 1, 5.008001';

print <<EOF;

***
*** The EV module is recommended for even better performance, unless you
*** have to use one of the other adaptors (Event, Glib, Tk, etc.).
*** The Async::Interrupt module is highly recommended to efficiently avoid
*** race conditions in/with other event loops.
***
*** This module does not have ANY dependencies, even if it might look
*** otherwise. If you are building a distribution package or have
*** difficulties installing this package due to dependencies, report this
*** to the packager as a bug.
***
*** This module is guaranteed to stay 100% pure-perl, full-featured
*** and performant, even without any of the optional modules.
***

EOF

do "constants.pl.PL"
   or die "cannot execute constants.pl.PL: $@";

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text lib/AnyEvent.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    test         => { TESTS => "t/*.t t/handle/*.t" },
    NAME         => "AnyEvent",
    VERSION_FROM => "lib/AnyEvent.pm",
    PMLIBDIRS    => ["lib"],
#    PREREQ_PM    => {
#       Task::Weaken => 0,
#    },
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
    META_MERGE => {
        recommends => {
           "Task::Weaken"     => 0,
           "Net::SSLeay"      => 1.33,
           "JSON"             => 2.09,
           "JSON::XS"         => 2.2,
           "EV"               => 4.00,
           "Guard"            => 1.02,
           "Async::Interrupt" => 1.0,
        }
    },
    PM           => {
        'lib/AE.pm'                      => '$(INST_LIB)/AE.pm',
        'lib/AnyEvent.pm'                => '$(INST_LIB)/AnyEvent.pm',
        'lib/AnyEvent/DNS.pm'            => '$(INST_LIB)/AnyEvent/DNS.pm',
        'lib/AnyEvent/Debug.pm'          => '$(INST_LIB)/AnyEvent/Debug.pm',
        'lib/AnyEvent/FAQ.pod'           => '$(INST_LIB)/AnyEvent/FAQ.pod',
        'lib/AnyEvent/Handle.pm'         => '$(INST_LIB)/AnyEvent/Handle.pm',
        'lib/AnyEvent/Impl/Cocoa.pm'     => '$(INST_LIB)/AnyEvent/Impl/Cocoa.pm',
        'lib/AnyEvent/Impl/EV.pm'        => '$(INST_LIB)/AnyEvent/Impl/EV.pm',
        'lib/AnyEvent/Impl/Event.pm'     => '$(INST_LIB)/AnyEvent/Impl/Event.pm',
        'lib/AnyEvent/Impl/EventLib.pm'  => '$(INST_LIB)/AnyEvent/Impl/EventLib.pm',
        'lib/AnyEvent/Impl/FLTK.pm'      => '$(INST_LIB)/AnyEvent/Impl/FLTK.pm',
        'lib/AnyEvent/Impl/Glib.pm'      => '$(INST_LIB)/AnyEvent/Impl/Glib.pm',
        'lib/AnyEvent/Impl/IOAsync.pm'   => '$(INST_LIB)/AnyEvent/Impl/IOAsync.pm',
        'lib/AnyEvent/Impl/Irssi.pm'     => '$(INST_LIB)/AnyEvent/Impl/Irssi.pm',
        'lib/AnyEvent/Impl/POE.pm'       => '$(INST_LIB)/AnyEvent/Impl/POE.pm',
        'lib/AnyEvent/Impl/Perl.pm'      => '$(INST_LIB)/AnyEvent/Impl/Perl.pm',
        'lib/AnyEvent/Impl/Qt.pm'        => '$(INST_LIB)/AnyEvent/Impl/Qt.pm',
        'lib/AnyEvent/Impl/Tk.pm'        => '$(INST_LIB)/AnyEvent/Impl/Tk.pm',
        'lib/AnyEvent/Impl/UV.pm'        => '$(INST_LIB)/AnyEvent/Impl/UV.pm',
        'lib/AnyEvent/IO.pm'             => '$(INST_LIB)/AnyEvent/IO.pm',
        'lib/AnyEvent/IO/IOAIO.pm'       => '$(INST_LIB)/AnyEvent/IO/IOAIO.pm',
        'lib/AnyEvent/IO/Perl.pm'        => '$(INST_LIB)/AnyEvent/IO/Perl.pm',
        'lib/AnyEvent/Intro.pod'         => '$(INST_LIB)/AnyEvent/Intro.pod',
        'lib/AnyEvent/Log.pm'            => '$(INST_LIB)/AnyEvent/Log.pm',
        'lib/AnyEvent/Loop.pm'           => '$(INST_LIB)/AnyEvent/Loop.pm',
        'lib/AnyEvent/Socket.pm'         => '$(INST_LIB)/AnyEvent/Socket.pm',
        'lib/AnyEvent/Strict.pm'         => '$(INST_LIB)/AnyEvent/Strict.pm',
        'lib/AnyEvent/TLS.pm'            => '$(INST_LIB)/AnyEvent/TLS.pm',
        'lib/AnyEvent/Util.pm'           => '$(INST_LIB)/AnyEvent/Util.pm',
        'lib/AnyEvent/Util/idna.pl'      => '$(INST_LIB)/AnyEvent/Util/idna.pl',
        'lib/AnyEvent/Util/uts46data.pl' => '$(INST_LIB)/AnyEvent/Util/uts46data.pl',
        'lib/AnyEvent/constants.pl'      => '$(INST_ARCHLIB)/AnyEvent/constants.pl',
    },
);

