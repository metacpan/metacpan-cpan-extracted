#ifndef _bb_h_
#define _bb_h_

#ifndef NULL
#define NULL ((void*)0)
#endif

#ifndef byte
#define byte unsigned char
#endif
#ifndef uint
#define uint unsigned int
#endif

typedef enum { _false = 0, _true = 1 } _bool;
typedef enum {
  noDecr = 0,
  cleanDecr,
  normalDecr,
  loadInitDecr
} decruncherType;

#define memSize 65536

#endif // _bb_h_
