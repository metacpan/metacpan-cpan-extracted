#include "file.h"
#include <stdlib.h>
#include <string.h>

void freeFile(File *aFile)
{
  if (aFile->name != NULL)
    free(aFile->name);
  if (aFile->data != NULL)
    free(aFile->data);
}

_bool readFile(File *aFile, const char *fileName)
{
  FILE *fp = NULL;
  struct stat fileStatus;

  aFile->name = (char *)strdup(fileName);

  if(stat(aFile->name, &fileStatus) == -1) {
    return _false;
  }
  aFile->size = fileStatus.st_size;

  fp = fopen(aFile->name, "rb");
  if(fp == NULL) {
    return _false;
  }

  aFile->data = (byte *)malloc(aFile->size);
  if(aFile->data == NULL) {
    fclose(fp);
    return _false;
  }

  if(fread(aFile->data, 1, aFile->size, fp) != aFile->size) {
    fclose(fp);
    free(aFile->data);
    return _false;
  }

  fclose(fp);
  return _true;
}

_bool writeFile(File *aFile, const char *fileName)
{
  FILE *fp = NULL;
  size_t length;
  struct stat st;

  length = strlen(fileName);
  aFile->name = (char *)malloc(length + 4);

  if(aFile->name == NULL){
    return _false;
  }

  strncpy(aFile->name, fileName, length);
  strncpy(aFile->name + length, ".b2\0", 4);

  if (stat(aFile->name, &st) == 0) {
    return _false;
  }

  fp = fopen(aFile->name, "wb");
  if(fp == NULL) {
    return _false;
  }

  if(fwrite(aFile->data, 1, aFile->size, fp) != aFile->size) {
    fclose(fp);
    return _false;
  }

  fclose(fp);
  return _true;
}