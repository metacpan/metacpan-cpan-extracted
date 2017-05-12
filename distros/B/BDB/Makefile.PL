use ExtUtils::MakeMaker;

use 5.008008;
use Config;

if ($^O =~ /win32/i or $^O =~ /mswin/) {

   # configuration on windows is hardcoded - as always

   warn "your platform is not standards-compliant, you have to port this module first\n";
   warn "using some hardcoded config that will not work on your system\n";
   warn "hint: edit the Makefile.PL\n\n";

   $INC  = "-I/Perl/lib/CORE -I/sdk/include -I/vc98/include -I/gtk/include -I/gtk/include/pango-1.0 -I/gtk/include/glib-2.0 -I/gtk/lib/glib-2.0/include/ -I/gtk/include/freetype2";
   $LIBS = ["-L/gtk/lib -ldb45 -lpthreadVC2"];
} else {
   $INC = "";
   $LIBS = ['-lpthread -ldb'],
}

if ($^O =~ /linux/ && $Config{usemymalloc} eq "y") {
   print <<EOF;

***
*** WARNING:
***
*** Your perl uses it's own memory allocator (-Dusemymalloc=y),
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

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text BDB.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "BDB",
    VERSION_FROM => "BDB.pm",
    INC          => $INC,
    LIBS         => $LIBS,
    PREREQ_PM    => {
       common::sense => 0,
    },
    PM           => {
    		    'BDB.pm'		=> '$(INST_LIB)/BDB.pm',
                    },
});

$mm->flush;

