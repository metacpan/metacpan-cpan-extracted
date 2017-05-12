use strict;
use warnings;
use Test::More;
use Alien::Libarchive;

BEGIN {
  plan skip_all => 'test requires Test::CChecker'
    unless eval q{ use Test::CChecker; 1 };
}

plan tests => 1;

compile_with_alien 'Alien::Libarchive';

compile_output_to_note;

compile_run_ok do { local $/; <DATA> }, "basic compile test";

__DATA__

#include <stdio.h>
#include <archive.h>
#include <archive_entry.h>

int
main(int argc, char *argv[])
{
  int r;
  struct archive *a;
  struct archive_entry *e;
  
  a = archive_read_new();
  printf("a = %p\n", a);
  if(a == NULL)
    return 2;
  
#if ARCHIVE_VERSION_NUMBER >= 3000000
  r = archive_read_free(a);
#else
  r = archive_read_finish(a);
#endif
  printf("archive_read_free = %d\n", r);
  if(r != ARCHIVE_OK)
    return 2;
  
  e = archive_entry_new();
  printf("e = %p\n", e);
  if(e == NULL)
    return 2;
  
  archive_entry_free(e);
  
  return 0;
}
