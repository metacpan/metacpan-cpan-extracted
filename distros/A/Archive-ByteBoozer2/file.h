#ifndef _file_h_
#define _file_h_

#include "bb.h"

#include <stdio.h>
#include <sys/stat.h>

typedef struct {
  char *name;
  size_t size;
  byte *data;
} File;

void freeFile(File *aFile);
_bool readFile(File *aFile, const char *fileName);
_bool writeFile(File *aFile, const char *fileName);

#endif // _file_h_