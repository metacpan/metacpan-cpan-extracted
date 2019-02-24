#include "store.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h> /* for mlock/munlock */
#include <unistd.h>
#include <string.h>

AddressRegion *new(int nSize)
{
    AddressRegion *pAddressRegion = (AddressRegion *) malloc(sizeof (AddressRegion));
    pAddressRegion->pBytes = NULL;
    pAddressRegion->sBytes = 0;
    pAddressRegion->processLocked = 0;
    pAddressRegion->memLocked = 0;
    pAddressRegion->nPageSize = pagesize(pAddressRegion);

    if (nSize)
    {
        pAddressRegion->nSize = nSize;
        pAddressRegion->nBytes = nSize * pAddressRegion->nPageSize * sizeof(char);
	initialize(pAddressRegion);
    }
    return pAddressRegion;
}


int initialize(AddressRegion *pAddressRegion)
{
    int r;
    if (!pAddressRegion->pBytes)
    {
        pAddressRegion->pBytes = (char *) malloc(pAddressRegion->nBytes); /* Allocate it */
        r = (!mlock(pAddressRegion->pBytes, pAddressRegion->nBytes)); /* lock it to memory */
        memset(pAddressRegion->pBytes, 0, pAddressRegion->nBytes); /* clear it, this will stop copy on write as well */
        pAddressRegion->memLocked = r;
    }
    return pAddressRegion->nBytes;
}

int process_locked(AddressRegion *pAddressRegion)
{
    return pAddressRegion->processLocked;
}

int is_locked(AddressRegion *pAddressRegion)
{
    return pAddressRegion->memLocked;
}

int set_pages(AddressRegion *pAddressRegion, int pages)
{
    int ps;
    ps = pagesize(pAddressRegion);
    return set_size(pAddressRegion, (pages * ps * (int)sizeof(char)));
}

int set_size (AddressRegion *pAddressRegion, int bytes)
{
    char *t;
    int r, l, s;
    s = pAddressRegion->sBytes; /* store the original size */
    if (pAddressRegion->pBytes) /* realloc (change size) */
    {
        if (bytes <= pAddressRegion->nBytes)
            l = bytes; /* new length is shorter */
        else
            l = pAddressRegion->nBytes; /* new length is greater */

        t = (char *) malloc(bytes); /* new area as requested */
        memset(t, 0, bytes); /* clear it */
        r = (!mlock(t, bytes)); /* lock it */
        if (pAddressRegion->sBytes >= bytes) /* currently stored is greater than the new space */
		s = bytes - 1; /* set the new size to one less than the size */
        if (pAddressRegion->sBytes) /* don't bother copying if there is nothing stored */
            memcpy(t, pAddressRegion->pBytes, (size_t) s);
        memset(pAddressRegion->pBytes, 0, pAddressRegion->nBytes); /* clear the old data */
        if (pAddressRegion->memLocked)
            munlock(pAddressRegion->pBytes, pAddressRegion->nBytes); /* unlock it */
	free(pAddressRegion->pBytes); /* free it */
        /* update the stored info with the new memory info */
        pAddressRegion->pBytes = t;
        pAddressRegion->nBytes = bytes;
        pAddressRegion->sBytes = s;
        pAddressRegion->memLocked = r;
    } else {
        /* nothing stored, so just initialise */
        pAddressRegion->nBytes = bytes;
        initialize(pAddressRegion);
    }
    return pAddressRegion->nBytes;
}

int pagesize(AddressRegion *pAddressRegion)
{
    pAddressRegion->nPageSize = getpagesize();
    return pAddressRegion->nPageSize;
}

void DESTROY(AddressRegion *pAddressRegion)
{
    memset(pAddressRegion->pBytes, 0, pAddressRegion->nBytes); /* clear it before releasing it */
    pAddressRegion->sBytes = 0;
    if (pAddressRegion->memLocked)
        munlock(pAddressRegion->pBytes, pAddressRegion->nBytes); /* unlock it */
    if (pAddressRegion->processLocked)
        munlockall();
    free(pAddressRegion->pBytes); /* free it */
    free(pAddressRegion);
}

void dump(AddressRegion *pAddressRegion)
{
    int i;
    char *p;
    char *b = (char *)malloc(65);

    p=b;

    for (i=0; i<pAddressRegion->nBytes; i++)
    {
        if (!(i % 16))
        {
            if (i)
            {
                fprintf(stderr, " %s\n%2d\t", b, i);
                memset(b, 0, 65);
                p=b;
            } else {
                fprintf(stderr, "%2d\t", i);
                memset(b, 0, 65);
            }
        } else if (!(i % 8)) {
            fprintf(stderr, " ");
            *p++ = ' ';
        }
        fprintf(stderr, "%02x ", pAddressRegion->pBytes[i]);
        if ((pAddressRegion->pBytes[i]) > 31 && (pAddressRegion->pBytes[i]) < 127)
                *p++ = (pAddressRegion->pBytes[i]);
        else
                *p++ = '.';
    }
    fprintf(stderr, " %s\n", b);
    free(b);
}

char *get(AddressRegion *pAddressRegion)
{
    if (!pAddressRegion->nBytes)
	return NULL;
    return pAddressRegion->pBytes;
}

int store(AddressRegion *pAddressRegion, char *data, int len)
{
    if (len > pAddressRegion->nBytes)
        return 0;
    memcpy(pAddressRegion->pBytes, data, (size_t) len);
    pAddressRegion->sBytes = len;
    return 1;
}

int unlockall(AddressRegion *pAddressRegion)
{
    int r = -1;
    if (pAddressRegion->processLocked)
    {
        r = munlockall(); /* unlock the process */
        if (!r && pAddressRegion->memLocked)
            mlock(pAddressRegion->pBytes, pAddressRegion->nBytes); /* relock the region in memory */
        pAddressRegion->processLocked = 0;
    }
    return r;
}

int lockall(AddressRegion *pAddressRegion)
{
    int r = -1;
    if (!pAddressRegion->processLocked)
    {
        r = mlockall(MCL_CURRENT | MCL_FUTURE); /* Lock everything now and future */
        if (!r)
            pAddressRegion->processLocked = 1; /* Record that it's locked if it succeeded */
    }
    return r;
}
