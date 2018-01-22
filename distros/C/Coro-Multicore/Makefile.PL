use ExtUtils::MakeMaker;
use Coro::MakeMaker;

use Canary::Stability Coro::Multicore => 1;

if ($^O eq "MSWin32") {
   # configuration on windows is hardcoded - as always

   print STDERR <<EOF;

***
*** Your platform is not standards compliant. To get this module working, you need to
*** download and install win32 pthread (http://sourceware.org/pthreads-win32/)
*** in /gtk/{lib,include}
*** also, the windows SDK is expected to be installed in /sdk
*** and visual C is expected to be installed in /vc98
***
*** Alternatively, set the INC and LIBS environment variables
*** accordingly before running Makefile.PL, or you can
*** pass INC and LIBS arguments to Makefile.PL itself.
***

EOF

   if ($Config{cc} =~ /(?:^|\\|\/)gcc(?:|.*\.exe)$/) {
      $INC  = "$ENV{INC} -I/gtk/include";
      $LIBS = ["$ENV{LIBS} -L/gtk/lib -lpthreadGC2"];
   } else {
      $INC  = "$ENV{INC} -I/sdk/include -I/vc98/include -I/gtk/include";
      $LIBS = ["$ENV{LIBS} -L/gtk/lib -lpthreadVC2"];
   }

} else {

   $INC  = "";
   $LIBS = ['-lpthread', '-lpthreads', ''];

   if ($^O =~ /bsd/i) {
      print <<EOF;

If you have problems with deadlocks or crashes on your system,
make sure your perl has been linked with -lpthread (you might try
LD_PRELOAD=/path/to/libpthread.so as a workaround). Also, pthread support
under many BSDs is not the best - before reporting a bug in this module,
make sure it's not an OS bug.

EOF
   }
}

if ($^O =~ /linux/ && $Config{usemymalloc} eq "y") {
   print <<EOF;

***
*** WARNING:
***
*** Your perl uses its own memory allocator (-Dusemymalloc=y),
*** which is known not to be threadsafe on GNU/Linux and probably
*** other platforms (even when not used concurrently, it trashes
*** the data structures of the system malloc running concurrently),
*** for perls up to 5.8.8 and possibly later versions.
***
*** If you are unsure wether your perl has been fixed, your system
*** is safe for other reasons, or you experience spurious segfaults,
*** please compile your perl with -Dusemymalloc=n.
***

EOF
}

WriteMakefile(Coro::MakeMaker::coro_args(
    dist	=> {
	            PREOP	=> 'pod2text Multicore.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Coro::Multicore",
    VERSION_FROM => "Multicore.pm",
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0, "Coro" => 6.44 },
    TEST_REQUIRES => { "Coro" => 6.44 },
    PREREQ_PM    => { "Coro" => 6.44, "AnyEvent" => 7 },
    INC          => $INC,
    LIBS         => $LIBS,
));

