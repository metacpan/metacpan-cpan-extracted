package Coro::MakeMaker;

use common::sense;

use Config;
use base 'Exporter';

our $installsitearch;

our $VERSION = 6.514;
our @EXPORT_OK = qw(&coro_args $installsitearch);

my %opt;

for my $opt (split /:+/, $ENV{PERL_MM_OPT}) {
   my ($k,$v) = split /=/, $opt;
   $opt{$k} = $v;
}

my $extra = $Config{sitearch};

$extra =~ s/$Config{prefix}/$opt{PREFIX}/ if
    exists $opt{PREFIX};

for my $d ($extra, @INC) {
   if (-e "$d/Coro/CoroAPI.h") {
      $installsitearch = $d;
      last;
   }
}

sub coro_args {
   my %arg = @_;
   $arg{INC} .= " -I$installsitearch/Coro";
   %arg;
}

1;
__END__

=head1 NAME

Coro::MakeMaker - MakeMaker glue for the XS-level Coro API

=head1 SYNOPSIS

This allows you to control coroutines from C/XS.

=head1 DESCRIPTION

For optimal performance, hook into Coro at the C-level. You'll need to
make changes to your C<Makefile.PL> and add code to your C<xs> / C<c>
file(s).

=head1 WARNING

When you hook in at the C-level you can get a I<huge> performance gain,
but you also reduce the chances that your code will work unmodified with
newer versions of C<perl> or C<Coro>. This may or may not be a problem.
Just be aware, and set your expectations accordingly.

=head1 HOW TO

=head2 Makefile.PL

  use Coro::MakeMaker qw(coro_args);

  # ... set up %args ...

  WriteMakefile (coro_args (%args));

=head2 XS

  #include "CoroAPI.h"

  BOOT:
    I_CORO_API ("YourModule");

=head2 API

This is just a small overview - read the Coro/CoroAPI.h header file in
the distribution, and check the examples in F<EV/> and F<Event/*>, or
as a more real-world example, the Deliantra game server (which uses
Coro::MakeMaker).

You can also drop me a mail if you run into any trouble.

 #define CORO_TRANSFER(prev,next) /* transfer from prev to next */
 #define CORO_SCHEDULE            /* like Coro::schedule */
 #define CORO_CEDE                /* like Coro::cede */
 #define CORO_CEDE_NOTSELF        /* like Coro::cede_notself */
 #define CORO_READY(coro)         /* like $coro->ready */
 #define CORO_IS_READY(coro)      /* like $coro->is_ready */
 #define CORO_NREADY              /* # of procs in ready queue */
 #define CORO_CURRENT             /* returns $Coro::current */
 #define CORO_THROW               /* exception pending? */
 #define CORO_READYHOOK           /* hook for event libs, see Coro::EV */

 /* C-level coroutine struct, opaque, not used much */
 struct coro;

 /* used for schedule-like-function prepares */
 struct coro_transfer_args
 {
   struct coro *prev, *next;
 };

 /* this is the per-perl-coro slf frame info */
 struct CoroSLF
 {
   void (*prepare) (pTHX_ struct coro_transfer_args *ta); /* 0 means not yet initialised */
   int (*check) (pTHX_ struct CoroSLF *frame);
   void *data; /* for use by prepare/check/destroy */
   void (*destroy) (pTHX_ struct CoroSLF *frame);
 };

 /* needs to fill in the *frame */
 typedef void (*coro_slf_cb) (pTHX_ struct CoroSLF *frame, CV *cv, SV **arg, int items);

 #define CORO_SV_STATE(coro)      /* returns the internal struct coro * */
 #define CORO_EXECUTE_SLF(cv,init,ax) /* execute a schedule-like function */
 #define CORO_EXECUTE_SLF_XS(init) /* SLF in XS, see e.g. Coro::EV */

 /* called on enter/leave */
 typedef void (*coro_enterleave_hook) (pTHX_ void *arg);

 #define CORO_ENTERLEAVE_HOOK(coro,enter,enter_arg,leave,leave_arg)   /* install an XS-level enter/leave hook */
 #define CORO_ENTERLEAVE_UNHOOK(coro,enter,leave)                     /* remove an XS-level enter/leave hook */
 #define CORO_ENTERLEAVE_SCOPE_HOOK(enter,enter_arg,leave,leave_arg)  /* install an XS-level enter/leave hook for the corrent scope */

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut
