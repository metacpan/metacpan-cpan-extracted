use Test2::V0 -no_srand => 1;
use Test::Alien;
use Config;
use Alien::Libxml2;

alien_ok 'Alien::Libxml2';

if($^O eq 'MSWin32' && $Config{ccname} eq 'cl')
{
  eval q{
    package Alien::Libxml2;
    sub libs_static
    {
      my($self) = @_;
      my $str = $self->SUPER::libs_static;
      $str =~ s/-L/-LIBPATH:/;
      $str;
    }
  };
  die $@ if $@;
}

my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  ok(Libxml2::mytest());
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libxml/parser.h>
#include <libxml/tree.h>

MODULE = Libxml2 PACKAGE = Libxml2

int
mytest()
  INIT:
    xmlDoc *doc = NULL;
    xmlNode *root_element = NULL;
    const char *filename = "corpus/basic.xml";
  CODE:
    doc = xmlReadFile(filename, NULL, 0);
    if(doc == NULL)
    {
      printf("error reading %s\n", filename);
      RETVAL = 0;
    }
    else
    {
      xmlFreeDoc(doc);
      xmlCleanupParser();
      RETVAL = 1;
    }
  OUTPUT:
    RETVAL
