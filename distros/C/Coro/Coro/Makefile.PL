use strict;
use ExtUtils::MakeMaker;
use Config;

$|=1;

my $DEFINE;
my @LIBS = [];

my $threads = $Config{usethreads};

sub have_inc($) {
   scalar grep -r "$_/$_[0]", $Config{usrinc}, split / /, $Config{incpth}
}

use Config;

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Coro has a number of configuration options. Due to its maturity, the
defaults that Coro chooses are usually fine, so you can decide to skip
these questions. Only if something went wrong you should select 'n'
here and manually configure Coro, and, of course, report this to the
maintainer :)

EOF

if (prompt ("Skip further questions and use defaults (y/n)?", "y") =~ /[yY]/) {
   $ENV{PERL_MM_USE_DEFAULT} = 1;
}


my $iface;

# default to assembly on x86 and x86_64 sometimes
my $iface_asm = $Config{archname} =~ /^(i[3456]86|amd64|x86_64)-/ ? "a" : undef;

# detect whether this perl is threaded, for those broken operating
# systems that need it.

my $pthread = $Config{libs} =~ /-lpthread/
           || $Config{ldflags} =~ /-pthread/
           || $Config{archname} =~ /-thread/;

if (exists $ENV{CORO_INTERFACE}) {
   $iface = $ENV{CORO_INTERFACE};

} elsif ($^O =~ /mswin32/i) {
   # nothing works, really, without deep hacks
   $iface = "f";

} elsif ($^O =~ /cygwin/) {
   # cygwin true to its form, be an order of magnitutde slower,
   # while using twice the amount of ram. but it works! yeah!
   $iface = "p";

} elsif ($^O =~ /irix/) {
   # sigaltstack works like sigstack, i.e. expects stack pointer, not stack base
   # but wikipeida lists it as 100% posix compliant. geeeee.
   $iface = "i";

} elsif ($^O =~ /linux/) {
   # everything "just works", as expected
   $iface = $iface_asm || "s";

} elsif ($^O =~ /freebsd/) {
   # FreeBSD 4.x has ucontext.h but no makecontext et al. (see BUGS section of
   # man context).
   #
   # FreeBSD 6.2 has marginally working ucontext, setjmp and asm, but
   # some 5.8.8's barf when threaded due to broken threading.

   $iface = $iface_asm || "s";

} elsif ($^O =~ /netbsd/) {
   # netbsd is totally broken (pthreads are incompatible with ucontext or
   # other stack switching mechanisms) therefore, default to pthread -
   # hey, it might actually work, with some hacks.
   $iface = "p";

   if (!$pthread) {
      # uh-oh
      print <<EOF;

***
*** WARNING: Your platform is known to have broken pthreads, which are
*** required for Coro because your platform is known to have broken
*** ucontext and setjmp/longjmp functions as well, which are broken
*** because your pthread library is broken. D'oh.
***
*** Coro will try to fight this vicious circle of breakage, but YMMV. If
*** Coro fails, try to recompile your perl with -lpthread, which will work
*** around some of the pthread bugs. (You do not have to enable ithreads).
***

EOF
      # ugh, pthreads need to be linked into the main program :/
      $iface = $iface_asm || "s";
   }

} elsif ($^O =~ /(openbsd|mirbsd)/) {
   # mirbsd seems to be bug-to-bug compatible openbsd fork,
   # with the name change being the biggest difference.
   if (!$pthread) {
      # asm seems to work, setjmp might, ucontext is missing,
      # threads lets not talk about
      # try setjmp/longjmp on 4.4, but pthread on earlier
      $iface = $iface_asm || ($Config{osvers} >= 4.4 ? "s" : "p");
   } else {
      # seems newer openbsd platforms have marginally working pthreads, but
      # their pthreads break sigaltstack - reading the sigaltstack sources
      # again shows how fundamentally clueless those people are (if no thread
      # has ever been created, then the program is bound to a kernel-scheduled
      # entity. get that? GET THAT?)
      $iface = "p";
   }

} elsif ($^O =~ /solaris/) {
   # setjmp, ucontext seem to work, as well as asm
   $iface = $iface_asm || "s";

} elsif ($^O =~ /darwin/) {
   # assembler doesn't support .type
   # ucontext is of course totally broken (it just crashes)
   # surprisingly, pthreads seem to work
   $iface = "s";

} elsif ($^O =~ /dragonfly/) {
   # ucontext is totally broken on dragonfly bsd:
   # Fatal error 'siglongjmp()ing between thread contexts is undefined by POSIX 1003.1
   $iface = "s";

} elsif (have_inc "ucontext.h") { # shame on this heuristic
   $iface = "u";

} else {
   $iface = "s";
}

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Coro can use a number of methods to implement coroutines at the C
level. The default chosen is based on your current confguration and is
correct in most cases, but you still can chose between these alternatives:

u  The unix 'ucontext.h' functions are relatively new and not implemented
   or well-tested in older unices. They allow very fast coroutine creation
   and reasonably fast switching. They are, however, usually slower than
   the other alternatives due to an extra syscall done by swapcontext. And
   while nominally most portable (it's the only POSIX-standardised
   interface for coroutines), ucontext functions are, as usual, broken on
   most/all BSDs.

s  If the ucontext functions are not working or you don't want
   to use them for other reasons you can try a workaround using
   setjmp/longjmp/sigaltstack (also standard unix functions). Coroutine
   creation is rather slow, but switching is very fast (often much faster
   than with the ucontext functions). Unfortunately, glibc-2.1 and
   below don't even feature a working sigaltstack. You cannot use this
   implementation if some other code uses SIGUSR2 or you plan to create
   coroutines from an alternative signal stack, as both are being used for
   coroutine creation.

a  Handcoded assembly. This is the fastest and most compatible method,
   with the least side effects, if it works, that is. It has been tested
   on GNU/Linux x86 and x86_64 systems and should work on all x86/x86_64
   systems using the SVR ELF ABI (it is also reported to be working on
   Strawberry Perl for Windows using MinGW). This is the recommended
   method on supported platforms. When it doesn't work, use another
   method, such as (s)etjmp/longjmp.

l  GNU/Linux. Very old GNU/Linux systems (glibc-2.1 and below) need
   this hack. Since it is very linux-specific it is also quite fast and
   recommended even for newer versions; when it works, that is (currently
   x86 and a few others only. If it compiles, it's usually ok). Newer
   glibc versions (>= 2.5) stop working with this implementation however.

i  IRIX. For some reason, SGI really does not like to follow POSIX (does
   that surprise you?), so this workaround might be needed (it's fast),
   although [s] and [u] should also work now.

w  Microsoft Windows. Try this on Microsoft Windows when using Cygwin or
   the MSVC compilers (e.g. ActiveState Perl, but see "a" for Strawberry
   Perl), although, as there is no standard on how to do this under
   windows, different environments might work differently. Doh.

f  Microsoft Windows. Try this on Microsoft Windows if w fails. It is slower
   and uses a lot more memory, but should be working all the time.

p  Use pthread API. Try to avoid this option, it was only created to
   make a point about the programming language shootout. It is unlikely
   to work with perls that have windows process emulation enabled ("perl
   threads"). It is also likely the slowest method of implementing
   coroutines. It might work fine as a last resort, however, as the
   pthread API is slightly better tested than ucontext functions for
   example. Of course, not on BSDs, who usually have very broken pthread
   implementations.

Coro tries hard to come up with a suitable default for most systems,
so pressing return at the prompt usually does the right thing. If you
experience problems (e.g. make test fails) then you should experiment with
this setting.

EOF

retry:

my $r = prompt "Use which implementation,\n" .
               "<s>etjmp, <u>ctx, <a>sm, <i>rix, <l>inux, <p>threads, <w>indows, <f>iber?",
               $iface;
$iface = lc $1 if $r =~ /(\S)/;

if ($iface eq "u") {
   $DEFINE .= " -DCORO_UCONTEXT";
   print "\nUsing ucontext implementation\n\n";
   conftest ("TEST_makecontext");
} elsif ($iface eq "s") {
   $DEFINE .= " -D_FORTIFY_SOURCE=0";
   $DEFINE .= " -DCORO_SJLJ";
   print "\nUsing setjmp/longjmp/sigaltstack implementation\n\n";
   conftest ("TEST_sigaltstack");
} elsif ($iface eq "l") {
   $DEFINE .= " -DCORO_LINUX";
   print "\nUsing linux-specific implementation\n\n";
} elsif ($iface eq "i") {
   $DEFINE .= " -DCORO_IRIX";
   print "\nUsing irix-specific implementation\n\n";
} elsif ($iface eq "w") {
   $DEFINE .= " -DCORO_LOSER";
   print "\nUsing windows-specific implementation\n\n";
} elsif ($iface eq "f") {
   $DEFINE .= " -DCORO_FIBER";
   print "\nUsing windows-specific fiber implementation\n\n";
} elsif ($iface eq "a") {
   $DEFINE .= " -DCORO_ASM";
   print "\nUsing handcoded assembler implementation\n\n";
} elsif ($iface eq "p") {
   $DEFINE .= " -DCORO_PTHREAD";
   @LIBS = ["-lpthread"];
   print "\nUsing pthread implementation\n\n";
} else {
   print "\nUnknown implementation \"$iface\"\n";
   goto retry;
}

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Per-context stack size factor: Depending on your settings, Coro tries to
share the C stacks is creates as much as possible, but sometimes it needs
to allocate a new one. This setting controls the maximum size that gets
allocated, and should not be set too high, as memory and address space
still is wasted even if it's not fully used. The value entered will be
multiplied by sizeof(void *), which is usually 4 on 32-bit systems, and 8
on 64-bit systems.

A setting of 16384 (the default) therefore corresponds to a 64k..128k
stack, which usually is ample space (you might even want to try 8192 or
lower if your program creates many coroutines).

On systems supporting mmap and dynamic memory management, the actual
memory usually gets allocated on demand, but with many large stacks you
can still run out of address space on your typical 32 bit platform (not to
forget the pagetables).

Some perls (mostly threaded ones and perl compiled under linux 2.6) and
some programs (inefficient regexes can use a lot of stack space) may
need much, much more: If Coro segfaults with weird backtraces (e.g. in a
function prologue) or in t/10_bugs.t, you might want to increase this to
65536 or more.

The default should be fine, and can be changed at runtime with
Coro::State::cctx_stacksize.

EOF

my $stacksize = $^O eq "linux" && $] < 5.008008 ? 128 * 1024 : 16384;

$stacksize = prompt ("C stack size factor?", $stacksize);
$DEFINE .= " -DCORO_STACKSIZE=$stacksize";

print "using a stacksize of $stacksize * sizeof(void*)\n";

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Coro can optionally put a guard area before each stack segment: When the
stack is too small and the access is not too far outside the stack (i.e.
within the guard area), then the program will safely segfault instead of
running into other data. The cost is some additional overhead with is
usually negligible, and extra use of address space.

The guard area size currently needs to be specified in pages (typical
pagesizes are 4k and 8k). The guard area is only enabled on a few
hardcoded architectures and is ignored on others. The actual preprocessor
expression disables this feature if:

   !__i386 && !__x86_64 && !__powerpc && !__m68k \
   && !__alpha && !__mips && !__sparc64

The default, as usual, should be just fine.

EOF

my $guardpages = prompt ("Number of guard pages (0 disables)?", "4");
$DEFINE .= " -DCORO_GUARDPAGES=$guardpages";

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Coro can tell valgrind about its stacks and so reduce spurious warnings
where valgrind would otherwise complain about possible stack switches.

Enabling this does not incur noticable runtime or memory overhead, but it
requires that you have the <valgrind/valgrind.h> header file available.

Valgrind support is completely optional, so disabling it is the safe
choice.

EOF

my $valgrind = have_inc "valgrind/valgrind.h" ?  "y" : "n";
$valgrind = $ENV{CORO_USE_VALGRIND} if exists $ENV{CORO_USE_VALGRIND};
$valgrind = prompt ("Enable valgrind support (y/n)?", $valgrind);
$DEFINE .= " -DCORO_USE_VALGRIND=1" if $valgrind =~ /[yY]/;


print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Coro can use (or even trick) some perl functions into doing what it needs
instead of relying on (some) of its own functions. This might increase
chances that it compiles and works, but it could just as well result in
memory leaks, crashes or silent data corruption. It certainly does result
in slightly slower speed and higher memory consumption, though, so YOU
SHOULD ENABLE THIS OPTION ONLY AS A LAST RESORT.

EOF

my $use_internals = prompt ("Prefer perl functions over coro functions (y/n)?", "n");
$DEFINE .= " -DCORO_PREFER_PERL_FUNCTIONS=1" if $use_internals =~ /[yY]/;

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Coro can use a simple JIT compiler to compile a part of the thread switch
function at runtime. On perls with windows process emulation (most!),
this results in a 50% speed improvement. On sane perls, the gain is much
less, usually around 5%. If you enable this option, then the JIT will
be enabled, on compatible operating systems and CPUs (currently only
x86/amd64 on certain unix clones). Otherwise, it will be disabled. It
should be safe to leave on - this setting is only here so you can switch
it off in case of problems.

Note that some broken kernels (often calling themselves "hardened") break
all JIT generation by manipulating some system calls. If you get bus
errors or segmentation faults immediately when the JIT is enabled but not
without, then note that disabling the JIT only fixes some symptoms, not
the underlying problem, and you might run into other problems later.

EOF

my $orgasm = $ENV{CORO_JIT} || "y";
$orgasm = prompt ("Try to use the JIT compiler, if available?", $orgasm);
$DEFINE .= " -DCORO_JIT=1" if $orgasm =~ /[yY]/;

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Coro has experimental support for cloning states. This can be used
to implement a scheme-like call/cc. However, this doesn't add to the
expressiveness in general, and is likely perl-version specific (and perl
5.12 deliberately removed support for it). As such, it is disabled by
default.  Enable it when you want to play around with it, but note that it
isn't supported, and unlikely ever will be. It exists mainly to prove that
it could be done - if only it were useful for something.

EOF

my $masturbate = $ENV{CORO_CLONE} || "n";
$masturbate = prompt ("Implement Coro::State->clone method (y/n)?", $masturbate);
$DEFINE .= " -DCORO_CLONE=1" if $masturbate =~ /[yY]/;

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

EOF

WriteMakefile(
  NAME         => "Coro::State",
  VERSION_FROM => "State.pm",
  DEFINE       => $DEFINE,
  LIBS         => @LIBS,
  DIR          => [],
  depend => {
     "State.c" => "state.h clone.c ecb.h libcoro/coro.h libcoro/coro.c",
  },
);

sub conftest {
   my $type = shift;

   print "\nTrying to detect stack growth direction (for $type)\n";
   print "You might see some warnings, this should not concern you.\n\n";
   system "$Config{cc} $Config{ccflags} -D$type libcoro/conftest.c";

   my $res = qx<./a.out>;
   $res =~ s/\s+$//;
   my ($sp, $ss) = split /,/, $res;

   print "\n\n*****************************************************************************\n";
   print "If the testsuite fails PLEASE provide the following information\n";
   print "to Marc Lehmann <schmorp\@schmorp.de>: operating system name, version,\n";
   print "architecture name and this string '$sp|$ss'. Thanks a lot!\n";#d#
   print "*****************************************************************************\n\n";

   unlink "a.out";
   unlink "conftestval";
}

