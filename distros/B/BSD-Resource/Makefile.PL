#
# Makefile.PL
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

require 5.002;

use vars qw($PACKAGE $DEFINE $LIBS);

$PACKAGE = 'BSD::Resource';

use Config;
use ExtUtils::MakeMaker;
use File::Basename;

$| = 1;

my $CC;

sub try_compile_and_link {
    my ($c, %opt) = @_;

    my ($ok) = 0;
    my ($tmp) = "tmp$$";
    local(*TMPC);

    my $cccmd;

    unlink("$tmp.c", "$tmp.o");

    if (open(TMPC, ">$tmp.c")) {
	print TMPC $c;
	close(TMPC);
	my @cc;
	if ($CC) {
	    push @cc, $CC;
	} else {
	    if (exists $ENV{CC}) {
		push @cc, $ENV{CC};
		print STDERR "(trying first the CC from your environment)\n";
	    }
	    push @cc, $Config{'cc'};
	}
	while (my $cc = shift @cc) {
	    unless (-x $cc) {
		# They might have a different compiler
		# than what Perl was compiled with (easy
		# if using gcc), or their $cc has more
		# than just the compiler name (say, options)
		my ($b, $s, $r) = ($cc =~ /^(\S+)(\s*)(.*)/);
		$cc = basename($b) . $s . $r;
	    }
	    $cccmd =
		"$cc -c -o $tmp.o -I$Config{'archlibexp'}/CORE $Config{'ccflags'}";
	    $cccmd .= " 2>/dev/null" unless $ENV{VERBOSE};
	    print STDERR "[cccmd = $cccmd]\n" if $ENV{VERBOSE};
	    if (system("$cccmd $tmp.c") == 0) {
		$ok = -s "$tmp.o";
		$CC = $cc;
	    }
	    last if $ok;
	}
	unlink("$tmp.c", "$tmp.o");
    }
    
    return $ok;
}

sub has_resource_h () {
    print "Checking whether you have certain header files...\n";

    if (try_compile_and_link(<<EOM)) {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/resource.h>
static int foo;
EOM
        print "You do have <sys/resource.h>.  Excellent.\n";
        return 1;
    }
    
    # Solaris 1 weirdo header

    if (try_compile_and_link(<<EOM)) {
#include <sys/rusage.h>
static int foo;
EOM
        print "You have <sys/rusage.h>.  Are you an old Solaris by any chance?\n";
        return 2;
    }

    return 0;
}

sub init {
    die <<EOM unless has_resource_h();
Your operating system does not seem to have <sys/resource.h> or <sys/rusage.h>.

(Run "perl Makefile.PL" with the environment variable VERBOSE set to 1 (one)
 too see in more detail what went wrong.)

There is no way $PACKAGE is going to work.

I am awfully sorry but I cannot go further.

Aborting configuration of $PACKAGE.
EOM

    $DEFINE = '';

    # Needed for NCR MP-RAS; should be harmless for others.
    if ($Config{'osname'} eq 'svr4') {
      $DEFINE = ' -D_XOPEN_SOURCE -D_XOPEN_SOURCE_EXTENDED=1';
    }

    # old Solarises had this oddity.
    $DEFINE .= ' -DI_SYS_RUSAGE' if (-r '/usr/include/sys/rusage.h');

    # ucb is poison for Solaris, and bsd may be on IRIX.
    if ($Config{'osname'} eq 'solaris') {
      $LIBS = [''];
    } elsif (($Config{'osname'} eq 'irix') &&
	     ($Config{'ccflags'} =~ m/-D_BSD_TIME/) &&
	     ($Config{'ccflags'} =~ m/-D_BSD_TYPES/)) {
      $LIBS = [''];
    } elsif ($Config{'osname'} eq 'svr4') {
      $LIBS = ['-lc89'];
    }
}

sub find_Rlim_t {
	my $tmp      = "rlim$$";
	my $not      = 0;

        print "Checking to see whether you have rlim_t...\n";
        my $has = try_compile_and_link(<<EOM);
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef I_SYS_TYPES
#include <sys/types.h>
#endif
#ifdef I_SYS_RUSAGE
#include <sys/rusage.h>
#else
#include <sys/resource.h>
#endif
static rlim_t foo = 0;
EOM
        if ($has) {
            $DEFINE .= " -DRlim_t=rlim_t";
        } else {
	    $not = 1;
	}

	print "You seem ";
	print "not " if $not;
	print "to have rlim_t defined (";
	print $not ? "this is okay" : "which is nice";
	print ").\n";
}

sub configure {
    find_Rlim_t();
    if ($^O eq 'solaris' &&
	$Config{ccflags} =~ /-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64/ &&
	$Config{use64bitall} ne 'define') {
	if (open(PROCFS, "/usr/include/sys/procfs.h")) {
	    my $noprocfs;
	    while (<PROCFS>) {
		if (/^#error.*Cannot use.*procfs.*large file.*/) {
		    $noprocfs = 1;
		    last;
		}
	    }
	    close(PROCFS);
	    if ($noprocfs) {
		$DEFINE .= ' -DSOLARIS_NO_PROCFS';
	    }
	}
    }
}

sub doMakefile {
    print  <<EOM if ($$LIBS[0] ne '');
Looking for libraries...
Note: it is ok if none of the libraries '@$LIBS' is found.

EOM
    WriteMakefile(
    'NAME'		=> $PACKAGE,
    'VERSION_FROM'	=> 'Resource.pm',
    'LIBS'		=> $LIBS,
    'DEFINE'		=> $DEFINE,
# do not even think about 'INC' => '-I/usr/ucbinclude', Solaris will avenge.
    'dist'      	=> { 'COMPRESS' => 'gzip' },
);
}

sub main {
    print <<EOM;

Configuring $PACKAGE...

EOM

    init;
    configure;
    doMakefile;
print  <<EOM;

Done configuring $PACKAGE.

Now you may issue 'make'.  Do not forget also 'make test'.
If some tests fail, please rerun the tests (see INSTALL).

EOM
}

&main;

# EOF
