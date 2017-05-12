#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Devices.h>

#if PRAGMA_STRUCT_ALIGN
         #pragma options align=mac68k
#endif
#if PRAGMA_STRUCT_ALIGN
         #pragma options align=reset
#endif

void FillCntrlParamBlock
    (CntrlParam *myPB, short drvRefNum, short csCode) {
	int 		    i, l;
	short		    *clearPtr;

	clearPtr = (short *) myPB;
	l = sizeof(CntrlParam)/sizeof(short);
	for (i=0; i < l; i++)
		*clearPtr++ = 0;

    myPB->ioCompletion = 0;
    myPB->ioVRefNum = 1;
    myPB->ioCRefNum = drvRefNum;
    myPB->csCode = csCode;
}


MODULE = AudioCD::Mac		PACKAGE = AudioCD::Mac

short
_GetDrive()
    CODE:
    short           drvRefNum;

    /* Multiple CD drives ... ? */
    if (gLastMacOSErr = OpenDriver("\p.AppleCD", &drvRefNum))
        XSRETURN_UNDEF;

    RETVAL = drvRefNum;
    
    OUTPUT:
    RETVAL

char *
_GetToc(drvRefNum)
    short           drvRefNum;

    CODE:
    CntrlParam      myPB;
    char            myToc[512];
    char            retToc[2048];
    int             cToc;

    FillCntrlParamBlock(&myPB, drvRefNum, 100);

    myPB.csParam[0] = 4;
    *(Ptr *)&myPB.csParam[1] = myToc;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    for (cToc = 1; cToc<511; cToc+=5) {
        if (myToc[cToc] == 0) {
            sprintf(retToc, "%s%d\t%d\t%d\t%d\n", retToc,
                myToc[cToc+1], myToc[cToc+2], myToc[cToc+3], myToc[cToc+4]);
        } else {
            cToc = 512;
        }
    }

    RETVAL = retToc;

    OUTPUT:
    RETVAL

short
_Status(drvRefNum)
    short           drvRefNum;

    CODE:
    CntrlParam      myPB;
    short           status;

    FillCntrlParamBlock(&myPB, drvRefNum, 107);

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    status = ((myPB.csParam[0] >> 8) & 255);

    RETVAL = status;

    OUTPUT:
    RETVAL

short
_Pause(drvRefNum, status)
    short           drvRefNum;
    short           status;

    CODE:
    CntrlParam      myPB;

    FillCntrlParamBlock(&myPB, drvRefNum, 105);
    if (status == 1) {
        myPB.csParam[0] = 0;
        myPB.csParam[1] = 0;
    } else if (status == 0) {
        myPB.csParam[0] = 1;
        myPB.csParam[1] = 1;    
    } else {
        XSRETURN_UNDEF;
    }

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

short
_Continue(drvRefNum, status)
    short           drvRefNum;
    short           status;

    CODE:
    CntrlParam      myPB;

    FillCntrlParamBlock(&myPB, drvRefNum, 105);
    if (status == 1) {
        myPB.csParam[0] = 0;
        myPB.csParam[1] = 0;
    } else {
        XSRETURN_UNDEF;
    }

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

short
_Stop(drvRefNum, end1, end2)
    short           drvRefNum;
    short           end1;
    short           end2;

    CODE:
    CntrlParam      myPB;

    FillCntrlParamBlock(&myPB, drvRefNum, 106);
    if (end1 == 0 && end2 == 0) {
        myPB.csParam[0] = 0;
        myPB.csParam[1] = 0;
        myPB.csParam[2] = 0;
    } else {
        myPB.csParam[0] = 2;
        myPB.csParam[1] = end1;
        myPB.csParam[2] = end2;
    }

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

short
_Play(drvRefNum, start1, start2)
    short           drvRefNum;
    short           start1;
    short           start2;

    CODE:
    CntrlParam      myPB;

    FillCntrlParamBlock(&myPB, drvRefNum, 104);

    myPB.csParam[0] = 2;
    myPB.csParam[1] = start1;
    myPB.csParam[2] = start2;
    myPB.csParam[3] = 0;
    myPB.csParam[4] = 9;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

short
_SetVolume(drvRefNum, vol_l, vol_r)
    short           drvRefNum;
    short           vol_l;
    short           vol_r;

    CODE:
    CntrlParam      myPB;

    FillCntrlParamBlock(&myPB, drvRefNum, 109);
    myPB.csParam[0] = (vol_l << 8) | vol_r;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

char *
_GetVolume(drvRefNum)
    short           drvRefNum;

    CODE:
    CntrlParam      myPB;
    char            vol[8];

    FillCntrlParamBlock(&myPB, drvRefNum, 112);

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    sprintf(vol, "%u\t%u", (myPB.csParam[0] >> 8) & 255,
        myPB.csParam[0] & 255);

    RETVAL = vol;

    OUTPUT:
    RETVAL

char *
_Info(drvRefNum)
    short           drvRefNum;

    CODE:
    CntrlParam      myPB;
    char            info[30];

    FillCntrlParamBlock(&myPB, drvRefNum, 101);

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    sprintf(info, "%d\t%d\t%d\t%d\t%d\t%d\t%d\t",
        myPB.csParam[0] & 255,
        myPB.csParam[1] & 255,
        (myPB.csParam[2] >> 8) & 255,
        myPB.csParam[2] & 255,
        (myPB.csParam[3] >> 8) & 255,
        myPB.csParam[3] & 255,
        (myPB.csParam[4] >> 8) & 255
    );

    RETVAL = info;

    OUTPUT:
    RETVAL

short
_Eject(drvRefNum)
    short drvRefNum;

    CODE:
    OSErr           myErr;
    Str63           volName;
    HParamBlockRec  myVol;
    const short     kMaxRefNums = 8;
    short           vRefNums[kMaxRefNums+1];
    short           numVolumes = 0;
    int             i;

    myVol.volumeParam.ioNamePtr = (StringPtr)&volName;
    myVol.volumeParam.ioCompletion = 0L;
    myVol.volumeParam.ioVolIndex = 0;

    do {
        myVol.volumeParam.ioVolIndex++;
        myErr = PBHGetVInfoSync(&myVol);
        if (!myErr && myVol.volumeParam.ioVDRefNum == drvRefNum) {
            vRefNums[numVolumes] = myVol.volumeParam.ioVRefNum;
            numVolumes++;
        }
    } while (!myErr && numVolumes < kMaxRefNums);

    if (numVolumes == 0) {
        CntrlParam      myPB;

        FillCntrlParamBlock(&myPB, drvRefNum, 7);

        if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
            XSRETURN_UNDEF;

    } else {
        if (gLastMacOSErr = Eject(nil, vRefNums[0]))
            XSRETURN_UNDEF;

        for (i = 0; i < numVolumes; i++) {
            if (gLastMacOSErr = UnmountVol(nil,vRefNums[i]))
                XSRETURN_UNDEF;
        }
    }

    RETVAL = 1;

    OUTPUT:
    RETVAL

