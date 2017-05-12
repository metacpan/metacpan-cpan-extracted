#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "LzmaDecode.c"

#include "ppport.h"

typedef struct Content_s
{
	char *content;
	unsigned long size;
} Content;

/* 
Converted from LzmaTest.c to .xs by Fabien POTENCIER
LZMA SDK 4.01 Copyright (c) 1999-2004 Igor Pavlov (2004-02-15)
*/

size_t MyReadFile(FILE *file, void *data, size_t size)
{
  return ((size_t)fread(data, 1, size, file) == (size_t)size);
}

#ifdef _LZMA_IN_CB
typedef struct _CBuffer
{
  ILzmaInCallback InCallback;
  unsigned char *Buffer;
  unsigned int Size;
} CBuffer;

int LzmaReadCompressed(void *object, unsigned char **buffer, unsigned int *size)
{
  CBuffer *bo = (CBuffer *)object;
  *size = bo->Size; /* You can specify any available size here */
  *buffer = bo->Buffer;
  bo->Buffer += *size; 
  bo->Size -= *size;
  return LZMA_RESULT_OK;
}
#endif

int LzmaUncompressData(Content *pIn, Content *pOut, unsigned char properties[5], char *rs)
{
  unsigned int outSizeProcessed, lzmaInternalSize;
  void *lzmaInternalData;
  int lc, lp, pb;
  int res;
  #ifdef _LZMA_IN_CB
  CBuffer bo;
  #endif

  for (pb = 0; properties[0] >= (9 * 5); 
    pb++, properties[0] -= (9 * 5));
  for (lp = 0; properties[0] >= 9; 
    lp++, properties[0] -= 9);
  lc = properties[0];

  lzmaInternalSize = (LZMA_BASE_SIZE + (LZMA_LIT_SIZE << (lc + lp)))* sizeof(CProb);

  #ifdef _LZMA_OUT_READ
  lzmaInternalSize += sizeof(LzmaVarState);
  #endif

  New(0, pOut->content, pOut->size, char);
  if (pOut->content == 0)
  {
    sprintf(rs + strlen(rs), "can't allocate");
    return 1;
  }

  New(0, lzmaInternalData, lzmaInternalSize, char);
  if (lzmaInternalData == 0)
  {
    sprintf(rs + strlen(rs), "can't allocate");
    return 1;
  }

  #ifdef _LZMA_IN_CB
  bo.InCallback.Read = LzmaReadCompressed;
  bo.Buffer = (unsigned char *)pIn->content;
  bo.Size = pIn->size;
  #endif

  #ifdef _LZMA_OUT_READ
  {
    UInt32 nowPos;
    unsigned char *dictionary;
    UInt32 dictionarySize = 0;
    int i;
    for (i = 0; i < 4; i++)
      dictionarySize += (UInt32)(properties[1 + i]) << (i * 8);
    New(0, dictionary, dictionarySize, char);
    if (dictionary == 0)
    {
      sprintf(rs + strlen(rs), "can't allocate");
      Safefree(lzmaInternalData);
      return 1;
    }
    LzmaDecoderInit((unsigned char *)lzmaInternalData, lzmaInternalSize,
        lc, lp, pb,
        dictionary, dictionarySize,
        #ifdef _LZMA_IN_CB
        &bo.InCallback
        #else
        (unsigned char *)pIn->content, pIn->size
        #endif
        );
    for (nowPos = 0; nowPos < pOut->size;)
    {
      UInt32 blockSize = pOut->size - nowPos;
      UInt32 kBlockSize = 0x10000;
      if (blockSize > kBlockSize)
        blockSize = kBlockSize;
      res = LzmaDecode((unsigned char *)lzmaInternalData, 
      ((unsigned char *)pOut->content) + nowPos, blockSize, &outSizeProcessed);
      if (res != 0)
      {
        sprintf(rs + strlen(rs), "error = %d\n", res);
	Safefree(lzmaInternalData);
        return 1;
      }
      if (outSizeProcessed == 0)
      {
        pOut->size = nowPos;
        break;
      }
      nowPos += outSizeProcessed;
    }
    Safefree(dictionary);
  }

  #else
  res = LzmaDecode((unsigned char *)lzmaInternalData, lzmaInternalSize,
      lc, lp, pb,
      #ifdef _LZMA_IN_CB
      &bo.InCallback,
      #else
      (unsigned char *)pIn->content, pIn->size,
      #endif
      (unsigned char *)pOut->content, pOut->size, &outSizeProcessed);
  pOut->size = outSizeProcessed;
  #endif

  if (res != 0)
  {
    sprintf(rs + strlen(rs), "error = %d\n", res);
    Safefree(lzmaInternalData);
    return 1;
  }

    Safefree(lzmaInternalData);

  return 0;
}

int LzmaUncompressFile(char *filename, Content *pOut, char *rs)
{
  FILE *inputHandle;
  unsigned int length;
  Content *pIn;
  unsigned char properties[5];
  int ii, ret;

  inputHandle = fopen(filename, "rb");
  if (inputHandle == 0)
  {
    sprintf(rs + strlen(rs), "open input file error");
    return 1;
  }

  fseek(inputHandle, 0, SEEK_END);
  length = (unsigned int)ftell(inputHandle);
  fseek(inputHandle, 0, SEEK_SET);

  if (!MyReadFile(inputHandle, properties, sizeof(properties)))
  {
    fclose(inputHandle);
    return 1;
  }

  pOut->size = 0;
  for (ii = 0; ii < 4; ii++)
  {
    unsigned char b;
    if (!MyReadFile(inputHandle, &b, sizeof(b)))
    {
      fclose(inputHandle);
      return 1;
    }
    pOut->size += (b) << (ii * 8);
  }

  if (pOut->size == 0xFFFFFFFF)
  {
    sprintf(rs + strlen(rs), "stream version is not supported");
    fclose(inputHandle);
    return 1;
  }

  for (ii = 0; ii < 4; ii++)
  {
    unsigned char b;
    if (!MyReadFile(inputHandle, &b, sizeof(b)))
      return 1;
    if (b != 0)
    {
      sprintf(rs + strlen(rs), "too long file");
      fclose(inputHandle);
      return 1;
    }
  }

    New(0, pIn, 1, Content);

  pIn->size = length - 13;
    New(0, pIn->content, pIn->size, char);
  if (pIn->content == 0)
  {
    sprintf(rs + strlen(rs), "can't allocate");
    Safefree(pIn);
    fclose(inputHandle);
    return 1;
  }
  if (!MyReadFile(inputHandle, pIn->content, pIn->size))
  {
    sprintf(rs + strlen(rs), "can't read");
    Safefree(pIn->content);
    Safefree(pIn);
    fclose(inputHandle);
    return 1;
  }

  fclose(inputHandle);

  if (properties[0] >= (9*5*5))
  {
    sprintf(rs + strlen(rs), "Properties error");
    Safefree(pIn->content);
    Safefree(pIn);
    return 1;
  }

  /* empty file: no need to uncompress data */
  if (pOut->size == (unsigned long)0)
  {
    Safefree(pIn->content);
    Safefree(pIn);
    return 0;
  }

  ret = LzmaUncompressData(pIn, pOut, properties, rs);

    Safefree(pIn->content);
    Safefree(pIn);

  return ret;
}

MODULE = Compress::unLZMA		PACKAGE = Compress::unLZMA		

PROTOTYPES: DISABLE

void
uncompressdata(content, size, sizeout, properties)
	char *content
	unsigned int size
	unsigned int sizeout
	unsigned char *properties
PPCODE:
	char sz[800] = { 0 };
	Content *pIn, *pOut;
	int code = 0;
	SV *errsv;

        New(0, pIn, 1, Content);
	pIn->content = content;
	pIn->size = size;

        New(0, pOut, 1, Content);
	pOut->content = NULL;
	pOut->size = sizeout;

	code = LzmaUncompressData(pIn, pOut, properties, sz);

	errsv = get_sv("@", TRUE);

	/* Error */
	if (code)
	{
		sv_setpv(errsv, sz);
		Safefree(pIn->content);
		Safefree(pIn);
		Safefree(pOut->content);
		Safefree(pOut);
		XSRETURN_UNDEF;
	}

	sv_setpv(errsv, "");
	XPUSHs(sv_2mortal(newSVpvn(pOut->content, pOut->size)));
	Safefree(pIn);
	Safefree(pOut->content);
	Safefree(pOut);
	XSRETURN(1);

void
uncompressfile(filename)
	char *filename
PPCODE:
	char sz[800] = { 0 };
	int code = 0;
	unsigned int size = 0;
	Content *pContent;
	SV *errsv;

        New(0, pContent, 1, Content);
	pContent->content = NULL;
	pContent->size = 0;

	code = LzmaUncompressFile(filename, pContent, sz);

	errsv = get_sv("@", TRUE);

	/* Error */
	if (code)
	{
		sv_setpv(errsv, sz);
		Safefree(pContent->content);
		Safefree(pContent);
		XSRETURN_UNDEF;
	}

	sv_setpv(errsv, "");
        if (pContent->size) {
 		XPUSHs(sv_2mortal(newSVpvn(pContent->content, pContent->size)));
	} else {
		XPUSHs(sv_2mortal(newSVpvn("", pContent->size))); /* the empty string */
        }
	Safefree(pContent->content);
	Safefree(pContent);
	XSRETURN(1);
