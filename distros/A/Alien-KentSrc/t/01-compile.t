use strict;
use warnings;
use Test::More;
use Test::Alien qw{alien_ok with_subtest xs_ok};
use Alien::KentSrc;

alien_ok 'Alien::KentSrc';

my $xs = do { local $/ = undef; <DATA> };
xs_ok { xs => $xs, verbose => $ENV{TEST_VERBOSE} }, with_subtest {
  is CompileTest->check(), 'CompileTest',
    'CompileTest::check() returns CompileTest';
};

done_testing;

__DATA__
/* From: https://metacpan.org/source/LDS/Bio-BigFile-1.07/lib/Bio/DB/BigFile.xs */
#include <common.h>
#include <linefile.h>
#include <hash.h>
#include <options.h>
#include <sqlNum.h>
#include <udc.h>
#include <localmem.h>
#include <bigWig.h>
#include <bigBed.h>
#include <udc.h>
#include <asParse.h>

/* Let Perl redefine these */
#undef TRUE
#undef FALSE
#undef warn

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct bbiFile     *Bio__DB__bbiFile;

MODULE = CompileTest PACKAGE = CompileTest

char *check(class)
  char *class;
  CODE:
    RETVAL = class;
  OUTPUT:
    RETVAL

void
bf_bigWigFileCreate(package="Bio::DB::BigFile",inName,chromSizes,blockSize=1024,itemsPerSlot=512,clipDontDie=TRUE,compress=TRUE,outName)
  char *package
  char *inName
  char *chromSizes
  int  blockSize
  int  itemsPerSlot
  int  clipDontDie
  int  compress
  char *outName
  CODE:
    /* for linking test */
    bigWigFileCreate(inName,chromSizes,blockSize,itemsPerSlot,clipDontDie,compress,outName);
