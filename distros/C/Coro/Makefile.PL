use ExtUtils::MakeMaker;

use Canary::Stability Coro => 1, 5.010;

unless (-e "Coro/libcoro/coro.c") {
   print <<EOF;

***
*** ERROR: Coro/libcoro is missing or damaged. If you used a CVS check-out
*** of Coro, you also have to check-out the "libcoro" module from the same CVS
*** repository in the Coro subdirectory (i.e. Coro/Coro/libcoro from outside).
***

EOF
   exit 1;
}

print "*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***\n\n";

if (eval { require Event }) {
   if ($Event::VERSION < 0.86 or $Event::VERSION == 0.88) {
      print <<EOF

***
*** WARNING: Event version $Event::VERSION found, NOT building Event support.
***
*** This version of Event is broken. The only currently known non-broken
*** versions of Event are 0.87 and 0.89+. Please install one of those
*** versions.
***

EOF
   } else {
      $EVENT = 1;
      $DEFINE .= " -DHAVE_EVENT=1";
      print "\nEvent version $Event::VERSION found, building Event support.\n\n";
   }
} else {
   print "\n*** Event not found, not building Event support.\n\n";
}

if (eval { require EV }) {
   if ($EV::VERSION < 4.0) {
      print <<EOF

***
*** WARNING: EV version $EV::VERSION found, NOT building EV support.
***
*** This version is ABI-incompatible with Coro, please upgrade to at least 4.0.
***

EOF
   } else {
      $EV = 1;
      $DEFINE .= " -DHAVE_EV=1";
      print "\nEV version $EV::VERSION found, building EV support.\n\n";
   }
} else {
   print "\n*** EV not found, not building EV support.\n\n";
}

WriteMakefile(
    dist         => {
       PREOP	=> 'pod2text Coro.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "Coro",
    VERSION_FROM => "Coro.pm",
    DIR          => ['Coro', ($EVENT ? 'Event' : ()), ($EV ? "EV" : ())],
    PREREQ_PM    => {
       common::sense    => 0,
       Scalar::Util	=> 0.00,
       AnyEvent         => 5.0,
       Storable		=> 2.15,
       Guard            => 0.5,

       # for Coro::Event
       #Event		=> 1.06,

       # for Coro::EV
       #EV               => 4.0,

       # for Coro::AIO
       #IO::AIO          => 2.3,
       #AnyEvent::AIO    => 1.1,

       # for Coro::BDB
       #BDB              => 1.5,
       #AnyEvent::BDB    => 1.0,
    },
    CONFIGURE_REQUIRES => { ExtUtils::MakeMaker => 6.52, Canary::Stability => 0 },
    # neither configure_requires nor recommends can be used
    # for optional dependencies. whoever decided that a module needs
    # to build properly without its dependencies installed
    # needs his brain rearranged dramatically.
    META_MERGE => {
        recommends => {
           Event         => 1.08,
           EV            => 4.0,
           IO::AIO       => 3.1,
           BDB           => 0,
           AnyEvent      => 7.0,
           AnyEvent::AIO => 1.0,
           AnyEvent::BDB => 1.0,
        }
    },
    PM           => {
		    'Coro.pm'		=> '$(INST_LIB)/Coro.pm',

		    'Coro/State.pm'	=> '$(INST_LIB)/Coro/State.pm',
		    'Coro/jit-amd64-unix.pl' => '$(INST_LIB)/Coro/jit-amd64-unix.pl',
		    'Coro/jit-x86-unix.pl'   => '$(INST_LIB)/Coro/jit-x86-unix.pl',

		    'Coro/MakeMaker.pm'	=> '$(INST_LIB)/Coro/MakeMaker.pm',
		    'Coro/CoroAPI.h'	=> '$(INST_LIB)/Coro/CoroAPI.h',

#		    'Coro/Cont.pm'	=> '$(INST_LIB)/Coro/Cont.pm',

		    'Coro/Specific.pm'	=> '$(INST_LIB)/Coro/Specific.pm',

		    'Coro/Timer.pm'	=> '$(INST_LIB)/Coro/Timer.pm',
		    'Coro/Signal.pm'	=> '$(INST_LIB)/Coro/Signal.pm',
		    'Coro/Channel.pm'	=> '$(INST_LIB)/Coro/Channel.pm',
		    'Coro/Semaphore.pm'	=> '$(INST_LIB)/Coro/Semaphore.pm',
		    'Coro/SemaphoreSet.pm'=> '$(INST_LIB)/Coro/SemaphoreSet.pm',
		    'Coro/RWLock.pm'	=> '$(INST_LIB)/Coro/RWLock.pm',

		    'Coro/Debug.pm'	=> '$(INST_LIB)/Coro/Debug.pm',
		    'Coro/Util.pm'	=> '$(INST_LIB)/Coro/Util.pm',
		    'Coro/Select.pm'	=> '$(INST_LIB)/Coro/Select.pm',
		    'Coro/Handle.pm'	=> '$(INST_LIB)/Coro/Handle.pm',
		    'Coro/Socket.pm'	=> '$(INST_LIB)/Coro/Socket.pm',

		    'Coro/AIO.pm'	=> '$(INST_LIB)/Coro/AIO.pm',
		    'Coro/BDB.pm'	=> '$(INST_LIB)/Coro/BDB.pm',
		    'Coro/LWP.pm'	=> '$(INST_LIB)/Coro/LWP.pm',
		    'Coro/Storable.pm'	=> '$(INST_LIB)/Coro/Storable.pm',
		    'Coro/AnyEvent.pm'	=> '$(INST_LIB)/Coro/AnyEvent.pm',
                    },
);

sub MY::postamble {
   <<EOF;

# set \$VERSION in all modules
setver:
	\$(PERL) -pi -e 's/^(\\s*(our\\s*)?\\\$\$VERSION\\s*=\\s*).*\$\$/\$\${1}\$(VERSION);/' *.pm Coro/*.pm EV/*.pm Event/*.pm

EOF
}


