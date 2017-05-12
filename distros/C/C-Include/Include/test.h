/********************************************************/
/* 'C' Structures of FastEcho 1.46                      */
/* Copyright (c) 1997 by Tobias Burchhardt              */
/* Last update: 01 Apr 1997                             */
/********************************************************/

#pragma pack(push, save)
#pragma pack(1)

/********************************************************/
/* FASTECHO.CFG = <CONFIG>                              */
/*                + <optional extensions>               */
/*                + <CONFIG.NodeCnt * Node>             */
/*                + <CONFIG.AreaCnt * Area>             */
/********************************************************/

#define REVISION    6       // current revision

/* Note: there is a major change in this revision - the */
/*       Node records have no longer a fixed length !   */

#define MAX_AREAS   4096    // max # of areas
#define MAX_NODES   1024    // max # of nodes
#define MAX_GROUPS  32      // max # of groups
#define MAX_AKAS    32      // max # of akas
#define MAX_ROUTE   15      // max # of 'vias'
#define MAX_ORIGINS 20      // max # of origins
#define MAX_GATES   10      // max # of Internet gates

/********************************************************************/
/* Note: The MAX_AREAS and MAX_NODES are only the absolute maximums */
/*       as the handling is flexible. To get the maximums which are */
/*       used for the config file you read, you have to examine the */
/*       CONFIG.MaxAreas and CONFIG.MaxNodes variables !            */
/*                                                                  */
/* Note: The MAX_AREAS and MAX_NODES maximums are subject to change */
/*       with any new version, therefore - if possible - make hand- */
/*       ling as flexible  possible  and  use  CONFIG.MaxAreas  and */
/*       .MaxNodes whereever possible. But be aware that you  might */
/*       (under normal DOS and depending on the way you handle  it) */
/*       hit the 64kB segment limit pretty quickly!                 */
/*                                                                  */
/*       Same goes for the # of AKAs and Groups -  use  the  values */
/*       found in CONFIG.AkaCnt and CONFIG.GroupCnt!                */
/*                                                                  */
/* Note: Define INC_FE_TYPES, INC_FE_BAMPROCS  and  INC_FE_DATETYPE */
/*       to include the typedefs if necessary.                      */
/********************************************************************/
#define INC_FE_TYPES
#define INC_FE_DATETYPE
//#define INC_FE_BAMPROCS

/********************************************************/
/* CONFIG.flags                                         */
/********************************************************/
#define RETEAR                  0x00000001l
#define AUTOCREATE              0x00000002l
#define KILLEMPTY               0x00000004l
#define KILLDUPES               0x00000008l
#define CLEANTEARLINE           0x00001000l
#define IMPORT_INCLUDEUSERSBBS  0x00002000l
#define KILLSTRAYATTACHES       0x00004000l
#define PURGE_PROCESSDATE       0x00008000l
#define MAILER_RESCAN           0x00010000l
#define EXCLUDE_USERS           0x00020000l
#define EXCLUDE_SYSOPS          0x00040000l
#define CHECK_DESTINATION       0x00080000l
#define UPDATE_BBS_CONFIG       0x00100000l
#define KILL_GRUNGED_DATE       0x00200000l
#define NOT_BUFFER_EMS          0x00400000l
#define KEEP_NETMAILS           0x00800000l
#define NOT_UPDATE_MAILER       0x01000000l
#define NOT_CHECK_SEMAPHORES    0x02000000l
#define CREATE_SEMAPHORES       0x04000000l
#define CHECK_COMPLETE          0x08000000l
#define RESPOND_TO_RRQ          0x10000000l
#define TEMP_OUTB_HARDDISK      0x20000000l
#define FORWARD_PACKETS         0x40000000l
#define UNPACK_UNPROTECTED      0x80000000l

/********************************************************/
/* CONFIG.mailer                                        */
/********************************************************/
#define FrontDoor               0x0001
#define InterMail               0x0002
#define DBridge                 0x0004
#define Binkley                 0x0010
#define PortalOfPower           0x0020
#define McMail                  0x0040

/********************************************************/
/* CONFIG.BBSSoftware                                   */
/********************************************************/
enum BBSSoft { NoBBSSoft = 0, RemoteAccess111, QuickBBS,
               SuperBBS, ProBoard122 /* Unused */, TagBBS,
               RemoteAccess200, ProBoard130 /* Unused */,
               ProBoard200, ProBoard212, Maximus202, Maximus300 };

/********************************************************/
/* CONFIG.CC.what                                       */
/********************************************************/
#define CC_FROM                 1
#define CC_TO                   2
#define CC_SUBJECT              3
#define CC_KLUDGE               4

/********************************************************/
/* CONFIG.QuietLevel                                    */
/********************************************************/
#define QUIET_PACK              0x0001
#define QUIET_UNPACK            0x0002
#define QUIET_EXTERN            0x0004

/********************************************************/
/* CONFIG.Swapping                                      */
/********************************************************/
#define SWAP_TO_XMS             0x0001
#define SWAP_TO_EMS             0x0002
#define SWAP_TO_DISK            0x0004

/********************************************************/
/* CONFIG.Buffers                                       */
/********************************************************/
#define BUF_LARGE               0x0000
#define BUF_MEDIUM              0x0001
#define BUF_SMALL               0x0002

/********************************************************/
/* CONFIG.arcext.inb/outb                               */
/********************************************************/
enum ARCmailExt { ARCDigits = 0, ARCHex, ARCAlpha };

/********************************************************/
/* CONFIG.AreaFixFlags                                  */
/********************************************************/
#define ALLOWRESCAN             0x0001
#define KEEPREQUEST             0x0002
#define KEEPRECEIPT             0x0004
#define ALLOWREMOTE             0x0008
#define DETAILEDLIST            0x0010
#define ALLOWPASSWORD           0x0020
#define ALLOWPKTPWD             0x0040
#define ALLOWCOMPRESS           0x0080
#define SCANBEFORE              0x0100
#define ADDRECEIPTLIST          0x0200
#define NOTIFYPASSWORDS         0x0400

/********************************************************/
/* Area.board (1-200 = Hudson)                          */
/********************************************************/
#define NO_BOARD        0x4000u /* JAM/Sq/Passthru etc. */
#define AREA_DELETED    0x8000u /* usually never written*/

/********************************************************/
/* Area.flags.storage                                   */
/********************************************************/
#define QBBS                    0
#define FIDO                    1
#define SQUISH                  2
#define JAM                     3
#define PASSTHRU                7

/********************************************************/
/* Area.flags.atype                                     */
/********************************************************/
#define AREA_ECHOMAIL           0
#define AREA_NETMAIL            1
#define AREA_LOCAL              2
#define AREA_BADMAILBOARD       3
#define AREA_DUPEBOARD          4

/********************************************************/
/* GateDef.flags                                        */
/********************************************************/
#define GATE_KEEPMAILS  0x0001

/********************************************************/
/* Types and other definitions                          */
/********************************************************/
#ifdef INC_FE_TYPES
  #define byte unsigned char
  #define word unsigned short  // normal int = 16 bit
  #define dword unsigned long
#endif

enum ARCers { ARC_Unknown = -1, ARC_SeaArc, ARC_PkArc, ARC_Pak,
              ARC_ArcPlus, ARC_Zoo, ARC_PkZip, ARC_Lha, ARC_Arj,
              ARC_Sqz, ARC_RAR, ARC_UC2 }; /* for Unpackers */

enum NetmailStatus { NetNormal = 0, NetHold, NetCrash /*, NetImm */ };

enum AreaFixType { NoAreaFix = 0, NormalAreaFix, FSC57AreaFix };
enum AreaFixSendTo { AreaFix = 0, AreaMgr, AreaLink, EchoMgr };

/********************************************************/
/* Structures                                           */
/********************************************************/

typedef struct
{
 word zone,net,node,point;
} Address;

#define _MAXPATH 56

typedef struct CONFIGURATION
{
 word revision;
 dword flags;
 word NodeCnt,AreaCnt,unused1;
 char NetMPath[_MAXPATH],
      MsgBase[_MAXPATH],
      InBound[_MAXPATH],
      OutBound[_MAXPATH],
      Unpacker[_MAXPATH],              /* DOS default decompression program */
      LogFile[_MAXPATH],
      unused2[336],
      Unpacker2[_MAXPATH],             /* OS/2 default decompression program */
      UnprotInBound[_MAXPATH],
      StatFile[_MAXPATH],
      SwapPath[_MAXPATH],
      SemaphorePath[_MAXPATH],
      BBSConfigPath[_MAXPATH],
      QueuePath[_MAXPATH],
      RulesPrefix[32],
      RetearTo[40],
      LocalInBound[_MAXPATH],
      ExtAfter[_MAXPATH-4],
      ExtBefore[_MAXPATH-4];
 char unused3[480];
 struct
 {
  byte what;
  char object[31];
  word conference;
 } CC[10];
 byte security,loglevel;
 word def_days,def_messages;
 char unused4[462];
 word autorenum;
 word def_recvdays;
 byte openQQQs,Swapping;
 word compressafter;
 word afixmaxmsglen;
 word compressfree;
 char TempPath[_MAXPATH];
 byte graphics,BBSSoftware;
 char AreaFixHelp[_MAXPATH];
 char unused5[504];
 word AreaFixFlags;
 byte QuietLevel,Buffers;
 byte FWACnt,GDCnt;             /* # of ForwardAreaFix records, */
                                /* # of Group Default records   */
 struct
 {
  word flags;
  word days[2];
  word msgs[2];
 } rescan_def;
 dword duperecords;
 struct
 {
  byte inb;
  byte outb;
 } arcext;
 word AFixRcptLen;
 byte AkaCnt,resv;              /* # of Aka records stored */
 word maxPKT;
 byte sharing,sorting;
 struct
 {
  char name[36];
  dword resv;
 } sysops[11];
 char AreaFixLog[_MAXPATH];
 char TempInBound[_MAXPATH];
 word maxPKTmsgs;
 word RouteCnt;                 /* # of PackRoute records */
 byte maxPACKratio;
 byte SemaphoreTimer;
 byte PackerCnt,UnpackerCnt;    /* # of Packers and Unpackers records */
 byte GroupCnt,OriginCnt;       /* # of GroupNames and Origin records */
 word mailer;
 word maxarcsize,maxarcdays;
 word minInbPKTsize;
 char reserved[804];
 word AreaRecSize,GrpDefRecSize;      /* Size  of  Area  and  GroupDefaults */
                                      /* records stored in this file        */
 word MaxAreas,MaxNodes;              /* Current max values for this config */
 word NodeRecSize;                    /* Size of each stored Node record    */
 dword offset;                        /* This is the offset from the current*/
                                      /* file-pointer to the 1st Node       */
} CONFIG;

/* To directly access the 'Nodes' and/or 'Areas' while bypassing the */
/* Extensions, perform an absolute (from beginning of file) seek to  */
/*                   sizeof(CONFIG) + CONFIG.offset                  */
/* If you want to access the 'Areas', you have to add the following  */
/* value to the above formula:  CONFIG.NodeCnt * CONFIG.NodeRecSize  */

typedef struct
{
 Address addr;                  /* Main address                          */
 Address arcdest;               /* ARCmail fileattach address            */
 byte aka,autopassive,newgroup,resv1;
 struct
 {
  byte passive          : 1;
  byte dddd             : 1;    /* Type 2+/4D                            */
  byte arcmail060       : 1;
  byte tosscan          : 1;
  byte umlautnet        : 1;
  byte exportbyname     : 1;
  byte allowareacreate  : 1;
  byte disablerescan    : 1;
  byte arc_status       : 2;    /* NetmailStatus for ARCmail attaches    */
  byte arc_direct       : 1;    /* Direct flag for ARCmail attaches      */
  byte noattach         : 1;    /* don't create a ARCmail file attach    */
  byte mgr_status       : 2;    /* NetMailStatus for AreaFix receipts    */
  byte mgr_direct       : 1;    /* Direct flag for ...                   */
  byte not_help         : 1;
  byte not_notify       : 1;
  byte packer           : 4;    /* # of Packer used, 0xf = send .PKT     */
  byte packpriority     : 2;    /* system has priority packing ARCmail   */
  byte resv             : 1;
 } flags;                       /* 24 bits total !                       */
 struct
 {
  word type             : 2;    /* Type of AreaFix: None (human),        */
                                /* Normal or Advanced (FSC-57)           */
  word noforward        : 1;    /* Don't forward AFix requests           */
  word allowremote      : 1;
  word allowdelete      : 1;    /* flags for different FSC-57 requests   */
  word allowrename      : 1;    /* all 3 reserved for future use         */
  word binarylist       : 1;
  word addplus          : 1;    /* add '+' when requesting new area      */
  word addtear          : 1;    /* add tearline to the end of requests   */
  word sendto           : 3;    /* name of this systems's AreaFix robot  */
  word resv             : 4;
 } afixflags;
 word resv2;
 char password[9];              /* .PKT password                         */
 char areafixpw[9];             /* AreaFix password                      */
 word sec_level;
 dword groups;                  /* Bit-field, Byte 0/Bit 7 = 'A' etc.    */
                                /* FALSE means group is active           */
 dword resv3;
 word resv4;
 word maxarcsize;
 char name[36];                 /* Name of sysop                         */
 byte areas[1];                 /* Bit-field with CONFIG.MaxAreas/8      */
                                /* bits, Byte 0/Bit 7 is conference #0   */
} Node;                         /* Total size of each record is stored   */
                                /* in CONFIG.NodeRecSize                 */

typedef struct
{
 char name[52];
 word board;                    /* 1-200 Hudson, others reserved/special */
 word conference;               /* 0 ... CONFIG.MaxAreas-1               */
 word read_sec,write_sec;
 struct
 {
  word aka    : 8;              /* 0 ... CONFIG.AkaCnt                   */
  word group  : 8;              /* 0 ... CONFIG.GroupCnt                 */
 } info;
 struct
 {
  word storage: 4;
  word atype  : 4;
  word origin : 5;              /* # of origin line                      */
  word resv   : 3;
 } flags;
 struct
 {
  word autoadded  : 1;
  word tinyseen   : 1;
  word cpd        : 1;
  word passive    : 1;
  word keepseen   : 1;
  word mandatory  : 1;
  word keepsysop  : 1;
  word killread   : 1;
  word disablepsv : 1;
  word keepmails  : 1;
  word hide       : 1;
  word nomanual   : 1;
  word umlaut     : 1;
  word hideseen   : 1;
  word resv       : 2;
 } advflags;
 word resv1;
 dword seenbys;                 /* LSB = Aka0, MSB = Aka31           */
 dword resv2;
 short days;
 short messages;
 short recvdays;
 char path[_MAXPATH];
 char desc[52];
} Area;

/********************************************************/
/* Optional Extensions                                  */
/********************************************************/
/* These are the variable length extensions between     */
/* CONFIG and the first Node record. Each extension has */
/* a header which contains the info about the type and  */
/* the length of the extension. You can read the fields */
/* using the following algorithm:                       */
/*                                                      */
/* offset := 0;                                         */
/* while (offset<CONFIG.offset) do                      */
/*  read_header;                                        */
/*  if(header.type==EH_abc) then                        */
/*   read_and_process_data;                             */
/*    else                                              */
/*  if(header.type==EH_xyz) then                        */
/*   read_and_process_data;                             */
/*    else                                              */
/*   [...]                                              */
/*    else  // unknown or unwanted extension found      */
/*  seek_forward(header.offset); // Seek to next header */
/*  offset = offset + header.offset + sizeof(header);   */
/* end;                                                 */
/********************************************************/

typedef struct
{
 word type;             /* EH_...                           */
 dword offset;          /* length of field excluding header */
} ExtensionHeader;


#define EH_AREAFIX      0x0001 /* CONFIG.FWACnt * <ForwardAreaFix> */

enum AreaFixAreaListFormat { Areas_BBS = 0, Area_List };

typedef struct
{
 word nodenr;
 struct
 {
  word newgroup : 8;
  word active   : 1;
  word valid    : 1;
  word uncond   : 1;
  word format   : 3;
  word resv     : 2;
 } flags;
 char file[_MAXPATH];
 word sec_level;
 word resv1;
 dword groups;
 char resv2[4];
} ForwardAreaFix;

#define EH_GROUPS       0x000C /* CONFIG.GroupCnt * <GroupNames> */

typedef struct
{
 char name[36];
} GroupNames;

#define EH_GRPDEFAULTS  0x0006  /* CONFIG.GDCnt * <GroupDefaults> */
                                /* Size of each full GroupDefault */
                                /* record is CONFIG.GrpDefResSize */
typedef struct
{
 byte group;
 char resv[15];
 Area area;
 byte nodes[1];         /* variable, c.MaxNodes/8 bytes */
} GroupDefaults;

#define EH_AKAS         0x0007  /* CONFIG.AkaCnt * <SysAddress> */

typedef struct
{
 Address main;
 char domain[28];
 word pointnet;
 dword flags;           /* unused       */
} SysAddress;

#define EH_ORIGINS      0x0008  /* CONFIG.OriginCnt * <OriginLines> */

typedef struct
{
 char line[62];
} OriginLines;

#define EH_PACKROUTE    0x0009  /* CONFIG.RouteCnt * <PackRoute> */

typedef struct
{
 Address dest;
 Address routes[MAX_ROUTE];
} PackRoute;

#define EH_PACKERS      0x000A  /* CONFIG.Packers * <Packers> (DOS)  */
#define EH_PACKERS2     0x100A  /* CONFIG.Packers * <Packers> (OS/2) */

typedef struct
{
 char tag[6];
 char command[_MAXPATH];
 char list[4];
 byte ratio;
 char resv[7];
} Packers;

#define EH_UNPACKERS    0x000B  /* CONFIG.Unpackers * <Unpackers> (DOS)  */
#define EH_UNPACKERS2   0x100B  /* CONFIG.Unpackers * <Unpackers> (OS/2) */

/* Calling convention:                    */
/* 0 = change path to inbound directory,  */
/* 1 = <path> *.PKT,                      */
/* 2 = *.PKT <path>,                      */
/* 3 = *.PKT #<path>,                     */
/* 4 = *.PKT -d <path>                    */

typedef struct
{
 char command[_MAXPATH];
 byte callingconvention;
 char resv[7];
} Unpackers;

#define EH_RA111_MSG    0x0100  /* Original records of BBS systems */
#define EH_QBBS_MSG     0x0101
#define EH_SBBS_MSG     0x0102
#define EH_TAG_MSG      0x0104
#define EH_RA200_MSG    0x0105
#define EH_PB200_MSG    0x0106
#define EH_PB211_MSG    0x0107  /* See BBS package's documentation */
#define EH_MAX202_MSG   0x0108  /* for details                     */


/********************************************************/
/* Routines to access Node.areas, Node.groups           */
/********************************************************/

#ifdef INC_FE_BAMPROCS

word AddBam(byte *bam,word nr)
{
byte c=(1<<(7-(nr&7))),d;

 d=bam[nr/8]&c;
 bam[nr/8]|=c;
 return(d);
}

void FreeBam(byte *bam,word nr)
{
 bam[nr/8]&=~(1<<(7-(nr&7)));
}

word GetBam(byte *bam,word nr)
{
 if(bam[nr/8]&(1<<(7-(nr&7)))) return(TRUE);
 return(FALSE);
}

#define IsActive(nr,area)      GetBam(Node[nr].areas,area)
#define SetActive(nr,area)     AddBam(Node[nr].areas,area)
#define SetDeActive(nr,area)   FreeBam(Node[nr].areas,area)

#endif

/********************************************************/
/* FASTECHO.DAT = <STATHEADER>                          */
/*                + <STATHEADER.NodeCnt * StatNode>     */
/*                + <STATHEADER.AreaCnt * StatArea>     */
/********************************************************/

#define STAT_REVISION       3   /* current revision     */

#ifdef INC_FE_DATETYPE
typedef struct                  /* Used in FASTECHO.DAT */
{
 word year;
 byte day;
 byte month;
} date;
#endif

typedef struct
{
 char signature[10];            /* contains 'FASTECHO\0^Z'      */
 word revision;
 struct date lastupdate;        /* last time file was updated   */
 word NodeCnt,AreaCnt;
 dword startnode,startarea;     /* unix timestamp of last reset */
 word NodeSize,AreaSize;        /* size of StatNode and StatArea records */
 char resv[32];
} STATHEADER;

typedef struct
{
 Address adr;
 dword Import,Export;
 struct date lastimport,lastexport;
 dword dupes;
 dword importbytes,exportbytes;
} StatNode;

typedef struct
{
 word conference;               /* conference # of area */
 dword tagcrc;                  /* CRC32 of area tag    */
 dword Import,Export;
 struct date lastimport,lastexport;
 dword dupes;
} StatArea;


#pragma pack(pop, save)
