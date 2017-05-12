#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

# if (defined(_WIN32))

#include "windll/structs.h"
#include "windll/decs.h"

LPUSERFUNCTIONS lpUserFunctions;
HANDLE hUF = (HANDLE)NULL;
LPDCL lpDCL = NULL;
HANDLE hDCL = (HANDLE)NULL;
HANDLE hZCL = (HANDLE)NULL;
DWORD dwPlatformId = 0xFFFFFFFF;
int WINAPI DisplayBuf(LPSTR, unsigned long);
int WINAPI GetReplaceDlgRetVal(LPSTR, unsigned);
int WINAPI password(LPSTR, int, LPCSTR, LPCSTR);
void WINAPI ReceiveDllMessage(z_uint8, z_uint8, unsigned,
    unsigned, unsigned, unsigned, unsigned, unsigned,
    char, LPCSTR, LPCSTR, unsigned long, char);

static void FreeUpMemory(void);

int
UzpMain(int argc, char **argv)
{
    int r;
    int exfc, infc;
    char **exfv, **infv;

    hDCL = GlobalAlloc( GPTR, (DWORD)sizeof(DCL));
    if (!hDCL)
       {
       return 0;
       }
    lpDCL = (LPDCL)GlobalLock(hDCL);
    if (!lpDCL)
       {
       GlobalFree(hDCL);
       return 0;
       }

    hUF = GlobalAlloc( GPTR, (DWORD)sizeof(USERFUNCTIONS));
    if (!hUF)
       {
       GlobalUnlock(hDCL);
       GlobalFree(hDCL);
       return 0;
       }
    lpUserFunctions = (LPUSERFUNCTIONS)GlobalLock(hUF);

    if (!lpUserFunctions)
       {
       GlobalUnlock(hDCL);
       GlobalFree(hDCL);
       GlobalFree(hUF);
       return 0;
       }

    lpUserFunctions->password = password;
    lpUserFunctions->print = DisplayBuf;
    lpUserFunctions->sound = NULL;
    lpUserFunctions->replace = GetReplaceDlgRetVal;
    lpUserFunctions->SendApplicationMessage = ReceiveDllMessage;

    lpDCL->StructVersID = UZ_DCL_STRUCTVER; /* version of this structure */
    lpDCL->ncflag = 0; /* Write to stdout if true */
    lpDCL->fQuiet = 2; /* 0 = We want all messages.
                  1 = fewer messages,
                  2 = no messages */
    lpDCL->ntflag = 0; /* test zip file if true */
    lpDCL->nvflag = 0; /* give a verbose listing if true */
    lpDCL->nzflag = 0; /* display a zip file comment if true */
    lpDCL->ndflag = 1; /* Recreate directories != 0, skip "../" if < 2 */
    lpDCL->naflag = 0; /* Do not convert CR to CRLF */
    lpDCL->nfflag = 0; /* Do not freshen existing files only */
    lpDCL->noflag = 1; /* Over-write all files if true */
    lpDCL->ExtractOnlyNewer = 0; /* Do not extract only newer */
    lpDCL->PromptToOverwrite = 0; /* "Overwrite all" selected -> no query mode */
    lpDCL->lpszZipFN = argv[3]; /* The archive name */
    lpDCL->lpszExtractDir = NULL; /* The directory to extract to. This is set
                                     to NULL if you are extracting to the
                                     current directory.
                                   */

    infc = exfc = 0;
    infv = exfv = NULL;

    r = Wiz_SingleEntryUnzip(infc, infv, exfc, exfv, lpDCL, lpUserFunctions);
    FreeUpMemory();
    return r;
}

int WINAPI GetReplaceDlgRetVal(LPSTR filename, unsigned efbufsiz)
{
    /* This is where you will decide if you want to replace, rename etc existing
       files.
     */
    return 1;
}

static void FreeUpMemory(void)
{
    if (hDCL)
       {
       GlobalUnlock(hDCL);
       GlobalFree(hDCL);
       }
    if (hUF)
       {
       GlobalUnlock(hUF);
       GlobalFree(hUF);
       }
}

/* This is a very stripped down version of what is done in Wiz. Essentially
   what this function is for is to do a listing of an archive contents. It
   is actually never called in this example, but a dummy procedure had to
   be put in, so this was used.
 */
void WINAPI ReceiveDllMessage(z_uint8 ucsize, z_uint8 csize,
    unsigned cfactor,
    unsigned mo, unsigned dy, unsigned yr, unsigned hh, unsigned mm,
    char c, LPCSTR filename, LPCSTR methbuf, unsigned long crc, char fCrypt)
{
    char psLBEntry[_MAX_PATH];
    char LongHdrStats[] =
              "%7lu  %7lu %4s  %02u-%02u-%02u  %02u:%02u  %c%s";
    char CompFactorStr[] = "%c%d%%";
    char CompFactor100[] = "100%%";
    char szCompFactor[10];
    char sgn;

    if (csize > ucsize)
       sgn = '-';
    else
       sgn = ' ';
    if (cfactor == 100)
       lstrcpy(szCompFactor, CompFactor100);
    else
       sprintf(szCompFactor, CompFactorStr, sgn, cfactor);
       wsprintf(psLBEntry, LongHdrStats,
          ucsize, csize, szCompFactor, mo, dy, yr, hh, mm, c, filename);

    printf("%s\n", psLBEntry);
}

/* Password entry routine - see password.c in the wiz directory for how
   this is actually implemented in WiZ. If you have an encrypted file,
   this will probably give you great pain.
 */
int WINAPI password(LPSTR p, int n, LPCSTR m, LPCSTR name)
{
    return 1;
}

/* Dummy "print" routine that simply outputs what is sent from the dll */
int WINAPI DisplayBuf(LPSTR buf, unsigned long size)
{
    printf("%s", (char *)buf);
    return (int)(unsigned int) size;
}

#else

int UzpMain(int, char**);

#endif

MODULE = Archive::Unzip::Burst		PACKAGE = Archive::Unzip::Burst	

int
_unzip(filename)
        char * filename
    INIT:
        int r;
    CODE:
        int argno = 4;
        char* args[4];
        args[0] = "unzip";
        args[1] = "-qq";
        args[2] = "-o";
        args[3] = filename;
        r = UzpMain(argno, args);
        RETVAL = r;
    OUTPUT:
        RETVAL
