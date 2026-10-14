#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Spec;
use FindBin ();

# A perl built with PERL_IMPLICIT_SYS - which every Strawberry is - has XSUB.h
# redefine a list of CRT names as function-like macros: `close` becomes
# PerlLIO_close, `open` becomes PerlLIO_open, and so on for read, write, link,
# select, socket, free and forty more. A table member called `open` or
# `close` breaks there, because `A->close(c)` puts the member name immediately
# in front of `(`, which is where a function-like macro fires. The
# declaration is safe because the name is followed by `)`, so the header
# compiles everywhere and only the CALL SITES break.
#
# This perl is almost certainly not an IMPLICIT_SYS one, so the test creates
# the condition rather than waiting for a smoker to: it leaves the two names
# defined as function-like macros exactly where XSUB.h leaves them, then
# includes the real headers in Vars.xs's order. Nothing here is a copy of the
# dist's code, so a new member or call site with a colliding name is caught
# the same way. That covers this dist's calls into HAMT's table as well as
# its own.

plan skip_all => 'no compiler recorded in Config' unless $Config{cc};

# Named, and resolved from where this file is, not from wherever the test was
# started or by counting directories up.
my $xt_dir    = abs_path($FindBin::Bin);
my $dist_root = abs_path(File::Spec->catdir($xt_dir, File::Spec->updir));
my $inc       = File::Spec->catdir($dist_root, 'include');
plan skip_all => "no include directory at $inc" unless -d $inc;

my $core = File::Spec->catdir($Config{archlibexp}, 'CORE');
plan skip_all => "no perl headers at $core" unless -f File::Spec->catfile($core, 'perl.h');

# HAMT's header: the sibling checkout first, then the installed copy, as
# Makefile.PL looks for it.
my $hamt_inc;
{
    my $sibling = File::Spec->catdir($dist_root, File::Spec->updir, 'HAMT', 'include');
    my @try = ($sibling);
    if (eval { require HAMT::Install::Files; 1 }) {
        no warnings 'once';
        push @try, $HAMT::Install::Files::CORE if defined $HAMT::Install::Files::CORE;
    }
    for my $d (@try) {
        next unless -f File::Spec->catfile($d, 'hamt_abi.h');
        $hamt_inc = $d;
        last;
    }
}
plan skip_all => 'no hamt_abi.h in the sibling HAMT or an installed one' unless $hamt_inc;

my $dir = tempdir(CLEANUP => 1);
my $c   = File::Spec->catfile($dir, 'implicit.c');
my $o   = File::Spec->catfile($dir, 'implicit' . ($Config{obj_ext} || '.o'));

open my $fh, '>', $c or plan skip_all => "cannot write $c: $!";
print {$fh} <<'C';
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* What XSUB.h leaves live under PERL_IMPLICIT_SYS. Stubs rather than the real
 * PerlLIO_* so this compiles on a perl that has no implicit-sys layer at all;
 * the SHAPE is what matters, because the shape is what fires. */
static int context_vars_probe_lio_close(int fd) { return fd; }
static int context_vars_probe_lio_open(const char *f, int fl) { (void)f; return fl; }
#undef close
#undef open
#define close(fd)   context_vars_probe_lio_close(fd)
#define open(f, fl) context_vars_probe_lio_open((f), (fl))

#include "hamt_abi.h"
#define MY_CXT_KEY "Context::Vars::_guts"
#include "context_vars/context_vars_hamt.h"
#include "context_vars/context_vars_ctx.h"
#include "context_vars/context_vars_ctx_selftest.h"
#include "context_vars/context_vars_var.h"
#include "context_vars/context_vars_scope.h"
#include "context_vars/context_vars_faa.h"
#include "context_vars/context_vars_obj.h"
#include "context_vars_abi.h"
#include "context_vars/context_vars_abi_impl.h"

int main(void) { return (int)CONTEXT_VARS_ABI.abi_version - CONTEXT_VARS_ABI_VERSION; }
C
close $fh;

my $cmd = join ' ', $Config{cc}, $Config{ccflags} || (), '-c',
          "-I\"$inc\"", "-I\"$hamt_inc\"", "-I\"$core\"", "-o", "\"$o\"", "\"$c\"";
my $log = `$cmd 2>&1`;
my $rc  = $?;

ok($rc == 0, 'the headers compile with open and close live as function-like macros')
    or diag("a member or call site collides with a name XSUB.h redefines under\n"
          . "PERL_IMPLICIT_SYS. Parenthesise the call - (T->close)(...) - so the\n"
          . "name is followed by ')' where a function-like macro cannot fire.\n\n"
          . "$cmd\n\n$log");

done_testing;
