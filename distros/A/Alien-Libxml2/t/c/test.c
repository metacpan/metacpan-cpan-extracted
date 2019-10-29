#include <libxml/parser.h>
#include <libxml/tree.h>

/*
 * C version of the test can be used to see verify if alien is doing something wonky
 * compile and run with pkg-config:
 * cc `pkg-config --cflags libxml-2.0` t/c/test.c `pkg-config --libs libxml-2.0` && ./a.out
 * compile and run with xml2-config:
 * cc `xml2-config --cflags` t/c/test.c  `xml2-config --libs` && ./a.out
 */

int
main(int argc, char *argv[])
{
  xmlDoc *doc = NULL;
  xmlNode *root_element = NULL;
  const char *filename = "corpus/basic.xml";
  doc = xmlReadFile(filename, NULL, 0);
  if(doc == NULL)
  {
    printf("error reading %s\n", filename);
    return  2;
  }
  else
  {
    xmlFreeDoc(doc);
    xmlCleanupParser();
    printf("ok\n");
    return 0;
  }
}
