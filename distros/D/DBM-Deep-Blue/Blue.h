





/*
------------------------------------------------------------------------
DBM_Deep_Blue
Philip R Brenan, 2010
------------------------------------------------------------------------
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <windows.h>

/*
------------------------------------------------------------------------
Memory model
------------------------------------------------------------------------
*/

#define MUNIT    long                            // The memory models are selected with char, short, long, quad
#define PAGESIZE 4096                            // Byte size of a page on this system

typedef unsigned char  UCHAR;                    // Byte 
typedef unsigned MUNIT MU;                       // Offset in memory model
typedef unsigned long  UL;                       // All memory calculations are done as this

#define BMU   sizeof(MUNIT)                      // Bytes in memory unit
#define bMU   BMU*8                              // Bits in memory unit
#define MMU   ((unsigned MUNIT)0xffffffff)       // Value used as a null pointer in memory model as it is impossible to reach it with the given minimum memory size

#define systemBitsWidth sizeof(long)*8           // Maximum bit width of an address on this system 
#define MemoryMinimumSize 2                      // Minimum log2 size of a memory block 

/*
------------------------------------------------------------------------
Objects in memory
------------------------------------------------------------------------
*/

enum
 {ObjectTypeAny,   ObjectTypeString, ObjectTypeHashKey,
  ObjectTypeArray, ObjectTypeHash, ObjectTypeSpona};

/*
------------------------------------------------------------------------
Logging mode
------------------------------------------------------------------------
*/

enum {LogNormal, LogSave, LogRollBack, LogCommit } logMode;

/*
------------------------------------------------------------------------
Memory Structure

Functions that cannot change the size of the memory structure, get M*,
functions that can change its size, get M**.
------------------------------------------------------------------------
*/

typedef struct M
 {char   signature[64];      // Signature            
  MU     free[bMU+1];        // Free address chains
  MU     objectNumber;       // Next object number
  MU     centralVector;      // Central vector
  MU     centralVectorX;     // Number of objects that can be stored in CVT at the moment
  MU     spona;              // Spare object number array
  MU     hashST;             // String Hash Table
  MU     hashSTX;            // Number of buckets in the hash string table at the moment
  MU     GAH;                // Global Hash or Array
  MU     length;             // Log2 length of memory structure
  MU     lastArrayElement;   // Last Array element got, simplifies testing 
  MU     lastFoundHashElement; // Last Hash element got,  simplifies testing
  MU     lastObjectFreed;    // Last object freed, - allows objects with zero reference count to survive movement from one array/hash to another
  MU     logMode;            // Logging mode
  MU     log;                // Array used to log units of work              
  MU     DD;                 // Array used to hold delayed deletes while in logSave mode
  MU     transaction;        // Transaction number
  HANDLE fileHandle;         // Handle to backing file
  HANDLE mapHandle;          // Handle to mapping
  MU     allocatedBytes;     // Bytes allocated for this structure
  MU     fileBacked;         // 0 - not file backed, 1 - file backed         
  MU     spare[100];         // Spare fields
  char   file[PAGESIZE - 64 - 118*sizeof(MU) - 2 * sizeof(HANDLE)];  // File name which pads us out to one page
  UCHAR array[0];            // Memory structure
 } M;

/*
------------------------------------------------------------------------
Object 
------------------------------------------------------------------------
*/

typedef struct O
 {UCHAR MAC;                 // Log2(memory block size)
  UCHAR type;                // Object type
  MU    referenceCount;      // Reference count
  MU    number;              // Object number
  UCHAR array[0];            // Object data
 } O; 

/*
------------------------------------------------------------------------
Central vector table 
------------------------------------------------------------------------
*/

typedef struct CVT
 {O  o;                      // Object
  MU array[0];               // Object offsets for even entries, 2*index+1 = odd for spona entries 
 } CVT; 

/*
------------------------------------------------------------------------
Spare Object Number Array - the spona
------------------------------------------------------------------------
*/

typedef struct SP
 {UCHAR MAC;                 // Allocation size
  MU    count;               // Number of objects on Spona
  MU    extent;              // Number of objects Spona can hold
  MU    array[0];            // Object numbers
 } SP; 

/*
------------------------------------------------------------------------
String
------------------------------------------------------------------------
*/

typedef struct String
 {O    o;                    // Object
  MU   length;               // Length of string 
  char array[0];             // String contents
 } String;

/*
------------------------------------------------------------------------
Array
------------------------------------------------------------------------
*/

typedef struct Array
 {O  o;                      // Object
  MU blessed;                // Blessing string number
  MU l;                      // Low bound of array
  MU h;                      // High bound of array
  MU array[0];               // Array elements
 } Array; 

/*
------------------------------------------------------------------------
Hash

The Hash String table uses the data field of struct HashElement to save
the hash value of the string. Normally this field is used to hold the
object number of the object stored in the hash at this key.

The current offset and extents of the HashST are stored in the memory
structure header.
------------------------------------------------------------------------
*/

typedef struct HashKey
 {O    o;                    // Object
  MU   length;               // Length of string
  char array[0];             // String
 } HashKey;

typedef struct HashElement
 {MU key;                    // Hash key pointer 
  MU data;                   // Hash data pointer
  MU path;                   // hash path length
  } HashElement;

typedef struct Hash
 {O  o;                      // Object
  MU blessed;                // Blessing string number
  MU count;                  // Elements active in hash
  MU maxPath;                // Maximum path length in hash
  MU iterator;               // Iterator for this hash
  HashElement array[0];      // Hash elements
 } Hash;

/*
-----------------------------------------------------------------------
Prototypes
-----------------------------------------------------------------------
*/

Array   *addressArray           (M **m, UL o);
Hash    *addressHash            (M **m, UL o);
HashKey *addressHashKey         (M **m, UL o);
String  *addressString          (M **m, UL o);
UL       allocArray             (M **m);
M      **allocMemoryArea        (UL  l);
M       *allocMemoryAreaBase    (UL l);
M **     allocPagedMemoryArea   (char *f);
long     arrayMax               (M **m, UL o);
void     cleanUp                (M **m);
void     clearArray             (M **m, UL a);
void     dcv                    (M **m, FILE *f);
void     decReferenceCount      (M **m, UL n);
UL       deleteHashKeyByIndex   (M **m, UL H, UL k);
void     dumpArea               (M **m, char *F);
void     freeArray              (M **m, UL a);
void     freeArrayObject        (M **m, UL o);
void     freeHashObject         (M **m, UL o);
void     freeHashSTKey          (M **m, UL o);
void     freeMemoryArea         (M **m);
void     freeNothing            (M **m, UL o);
void     freeObject             (M **m, UL o);
UL       getArray               (M **m, UL a, long i);
UL       getArraySize           (M **m, UL o);
UL       getArraySizeFromAddress(Array *a);
UL       getHashBuckets         (M **m, UL H);
UL       getHashBucketsObject   (M **m, UL H);
UL       getObject              (M **m, UL o);
UL       getObjectNumber        (M  *m, UL p);
UL       getObjectOffset        (M **m, UL o);
UL       getObjectType          (M **m, UL n);
UL       getObjectReferenceCount(M **m, UL n);
void     getStringContents      (M **m, UL n, char *b, UL l);
void     incReferenceCount      (M **m, UL n);
UL       popSP                  (M **m);
void     pushArray              (M **m, UL a, UL o);
void     putHashByIndex         (M **m, UL H, UL k, UL D);
void     putSP                  (M **m, UL o);
void     putArray               (M **m, UL a, long i, UL v);
void     putArrayNanO           (M **m, UL a, long i, UL v);
void     rollback               (M **m);
void     saveArrayBless         (M **m, UL o, UL b);
void     saveHashBless          (M **m, UL o, UL b);
void     setArraySize           (M **m, UL a, long i);
void     setObjectPointer       (M **m, UL o, UL p);
void     setUpHashST            (M **m);
UL       shiftArray             (M **m, UL a);
void     shrinkHash             (M **m, UL H);
void     shrinkHashST           (M **m);
UL       sizeOfBackingFile      (UL l);
void     unshiftArray           (M **m, UL a, UL v);
void     zeroReferenceCount     (M **m, UL o);

/*
######################################################################
# Debugging
######################################################################
*/

#define debug                  0       // Tracing:  -1 calls, 1 returns, 2 all 
#define debugMemory            1       // 0 - no fill memory, 1 - fill memory with special values   
#define collectInstrumentation 1       // 0 - none, 1 - collect

long debugLine   = 0;                  // Debug output line
long debugIndent = 0;                  // Indentation for output

void dd(long line)                     // Indent debugging info
 {long i, n = debugIndent * 2;
  ++debugLine;
  fprintf(stderr, "%5u ", line);
  for(i = 0; i < n; ++i)
   {fprintf(stderr, "  ");
   }
  fprintf(stderr, "%u ", line);
 }

void ds()                              // Start block
 {++debugIndent;
 }

void dr()                              // Return from block
 {--debugIndent;
 }

long lines[10000];

void instrumentation(long line)       // Collect instrumentation
 {if (collectInstrumentation) {++lines[line];}
 } 

void instrumentationDump()            // Dump instrumentation   
 {if (collectInstrumentation == 0) {return;}
  FILE *f = fopen("instrumentation/run.data", "w");
  UL i;
  for(i = 0; i < sizeof(lines)/sizeof(long); ++i)
   {if (lines[i] == 0) {continue;}
    fprintf(f, "%5d %6d\n", i, lines[i]);
   }
  fclose(f); 
 } 
  
/*
######################################################################
# Virtual Memory management for Windows
######################################################################
*/

/*
------------------------------------------------------------------------
Error messages
------------------------------------------------------------------------
*/

void windowsError(char *title)
 {
  DWORD  e  = GetLastError();                    // Get error
  SetLastError(0);                               // Clear error
  if (e == 0) {return;}                          // Return if clear 

  char   b[1024];                                // Message buffer
  size_t sb = sizeof(b);                         // Size of message buffer

  DWORD format_flags = FORMAT_MESSAGE_FROM_SYSTEM;
  int length = FormatMessage(format_flags, NULL, e, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), b, sb, NULL);
  fprintf(stderr, "Windows reports error: %s %d %s\n", title, e, b);
//croak("Windows reports error: %s %d %s\n", title, e, b);
  
 }

/*
------------------------------------------------------------------------
Page size
------------------------------------------------------------------------
*/

long pageSize(void)
 {SYSTEM_INFO info;
  GetSystemInfo(&info);
  windowsError("PageSize");
  DWORD pageSize = info.dwPageSize;
  printf("pageSize=%d\n", pageSize);
  pageSize;
 }

/*
------------------------------------------------------------------------
Open file
------------------------------------------------------------------------
*/

HANDLE createFile(char *f, UL *x)
 {
  HANDLE fh = CreateFile(f, 3, 0, 0, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

  long e = GetLastError();
  if (e == 3)                                    // Cannot create file 
   {croak("Cannot create file %s, do you need to create the path?", f);
   }
  if (e == 183) {*x = 1; SetLastError(0);}       // File exists    
  else {windowsError("CreateFile");}
  
  return fh;
 } 

/*
------------------------------------------------------------------------
File size
------------------------------------------------------------------------
*/

long fileSize(HANDLE fh)
 {DWORD size = 0;
  DWORD rc   = GetFileSize(fh, &size);
  windowsError("fileSize"); 
  printf("rc=%d size=%d\n", rc, size);
  return size;
 }

/*
------------------------------------------------------------------------
Read file
------------------------------------------------------------------------
*/

void readFile(HANDLE fh)
 {char a[1000];
  DWORD read;
  DWORD rc = ReadFile(fh, a, sizeof(a), &read, NULL);
  windowsError("readFile"); 
  printf("rc=%d read=%d a=%s\n", rc, read, a);
 }

/*
------------------------------------------------------------------------
Create File Mapping
------------------------------------------------------------------------
*/

HANDLE createFileMapping(HANDLE fh, long s)
 {
  HANDLE m = CreateFileMapping(fh, NULL, PAGE_READWRITE, 0, s, NULL);
  if (m == 0) {windowsError("CreateFileMapping");}
  
  return m;
 }

/*
------------------------------------------------------------------------
Map view of file
------------------------------------------------------------------------
*/

void *mapViewOfFile(HANDLE fh, long s)
 {
  void *m = MapViewOfFile(fh, FILE_MAP_WRITE, 0, 0, s);
  if (m == 0) {windowsError("mapViewOfFile");}
  
  return m;
 }

/*
------------------------------------------------------------------------
Unmap view of file
------------------------------------------------------------------------
*/

void unmapViewOfFile(void *a)
 {
  UL e = UnmapViewOfFile(a);
  if (e == 0) {windowsError("unmapViewOfFile");;}
  
 }

/*
------------------------------------------------------------------------
Flush view of file
------------------------------------------------------------------------
*/

void flushViewOfFile(void *a)
 {
  UL e = FlushViewOfFile(a, 0);            
  if (e == 0) {windowsError("flushViewOfFile");}
  
 }

/*
------------------------------------------------------------------------
Close file mapping handle
------------------------------------------------------------------------
*/

void closeFileMappingHandle(HANDLE h)
 {
  long e = CloseHandle(h);
  if (e == 0) {windowsError("closeFileMappingHandle");}
  
 }

/*
------------------------------------------------------------------------
Close file handle
------------------------------------------------------------------------
*/

void closeFileHandle(HANDLE h)
 {
  long e = CloseHandle(h);
  if (e == 0) {windowsError("closeFileHandle");}
  
 }

/*
######################################################################
# Memory management
######################################################################
*/

/*
------------------------------------------------------------------------
Check memory area size
------------------------------------------------------------------------
*/

void checkAllocSize(UL l)
 {
  if (l > bMU)
   {croak("Log2(requested memory block size %u) larger than upper limit of %u", l, bMU);
   }
  if (l < MemoryMinimumSize)
   {croak("Log2(requested memory block size %u) less than minimum block size %u", l, MemoryMinimumSize);
   }
  
 }

/*
-----------------------------------------------------------------------
Get actual address in memory of offset in memory structure
-----------------------------------------------------------------------
*/

void *am(M *m, UL a)
 {if (a >= (1<<m->length))
   {croak("Offset %u is outside memory structure with current length %u", a, m->length);
   }

  return (void *)&(m->array[a]);
 }

/*---------------------------------------------------------------------
Set memory at offset a in memory structure
-----------------------------------------------------------------------
*/

void setMemory(M *m, UL a, int v, long l)
 {
  memset(am(m, a), v, l);
  
 }

/*
-----------------------------------------------------------------------
Clear memory at offset a in memory structure m for length l
-----------------------------------------------------------------------
*/

void clearMemory(M *m, UL a, long l)
 {
  memset(am(m,a), 0, l);
  
 }

/*
-----------------------------------------------------------------------
Get the log2(length of an allocation)
-----------------------------------------------------------------------
*/

UL getAllocLength(M *m, UL a)
 {
  O *o = am(m, a);
  UL l = o->MAC;
  checkAllocSize(l);                   
  
  return o->MAC;
 }  

/*
-----------------------------------------------------------------------
Set the log2(length of an allocation)
-----------------------------------------------------------------------
*/

void setAllocLength(M *m, UL a, UL l)
 {
  O *o = am(m, a);
  o->MAC = l;
  
 }  

/*
-----------------------------------------------------------------------
Set free address. If debugging, the memory is set to an unlikely value
to assist dump reading.
-----------------------------------------------------------------------
*/

void setFreeAddress (M *m, UL a, UL l)
 {
  m->free[l] = a;

  if (debugMemory)
   {long L = 1; L = L<<l;
    if (l < 16) {setMemory(m, a, (int)(240+l), L);} 
    else        {setMemory(m, a, (int)(224+l), L);}
   } 
  
 }

/*
-----------------------------------------------------------------------
Set free address - but without clearing the memory area
-----------------------------------------------------------------------
*/

void setFreeAddress2(M *m, UL a, UL l)
 {
  m->free[l] = a;
  
 }

/*
-----------------------------------------------------------------------
Clear free address
-----------------------------------------------------------------------
*/

void clearFreeAddress(M *m, UL l)
 {
  m->free[l] = MMU;
  
 }

/*
-----------------------------------------------------------------------
Get free address
-----------------------------------------------------------------------
*/

UL getFreeAddress(M *m, UL l)
 {
  UL a = m->free[l];
  
  return a;
 }

/*
-----------------------------------------------------------------------
Get Log2(largest free block) of memory still free, or return 0
-----------------------------------------------------------------------
*/

UL getLargestFree(M *m)
 {

  UL i;
  for(i = bMU; i >= MemoryMinimumSize; --i)
   {UL a = m->free[i];
    if (a < MMU)
     {
      return i;
     }
   }
  
  return 0;
 }

/*
-----------------------------------------------------------------------
Number of bits required to hold a number
-----------------------------------------------------------------------
*/

UL bits(UL n)
 {
  UL i, j = 1;
  for(i = 0; j < n && i < sizeof(n)*8; ++i, j *= 2) {}
  
  return i;
 }

/*
-----------------------------------------------------------------------
Grow memory
-----------------------------------------------------------------------
*/

void growMemory(M **m, UL l)
 {

  if ((*m)->fileBacked > 0)                                // Backed with a file 
   {
    char f[1024];
    strcpy(f, (*m)->file);                                 // Save file name
    freeMemoryArea(m);                                     // Writes out backing file

    HANDLE fh, vh; M *n; UL e = 0; 
    UL s = sizeOfBackingFile(l);                           // Size of file
      fh = createFile(f, &e);                              // Open backing file
      vh = createFileMapping(fh, s);                       // Reopen with new size
      n  = mapViewOfFile(vh, s);                           // View file
      n->length         = l;                               // Update length
      n->allocatedBytes = s;                               // Update allocated bytes

    *m = n;
   }

// Not backed with a file

  else
   {
    M *n = allocMemoryAreaBase(l);                         // Alloc new area or die

    long L  = 1<<((*m)->length < l ? (*m)->length : l);    // Minimum size

    memcpy(n, *m, sizeof(struct M) + L);                   // Copy old area 
    n->length = l;                                         // Set new length                                       

    free(*m);                                              // Free old area
    *m = n;                                                // Address new area
   }

  
 }

/*
------------------------------------------------------------------------
Initialize Memory Area
------------------------------------------------------------------------
*/

void initializeMemoryArea(M *m, UL l)
 {

  strcpy(m->signature, "DBMDeepBlue32 Copyright: PhilipRBrenan at gmail dot com, 2010"); // Set signature                                    

  m->length  = l;                                          // Set free block offsets
   {long i;
    for(i = 0; i <= bMU; ++i) 
     {m->free[i] =  MMU;
     }
   }

  m->free[l] = 0;                                          // Initial free space

  m->objectNumber   = m->lastObjectFreed = m->GAH = 0;     // Offsets to sub structures
  m->centralVector  = m->hashST  = m->spona = MMU;
  m->lastArrayElement = m->lastFoundHashElement = 0;       // Simplifies testing
  m->centralVectorX = m->hashSTX = 0;
  m->logMode        = LogNormal;                           // Logging 
  m->DD             = m->log     = 0;
  m->fileBacked     = 0;                                   // Not file backed
  m->transaction    = 0;                                   // TRansaction should always be zero in a non file backed mode

  
 }

/*
------------------------------------------------------------------------
Allocate Memory Area Base - this gets the memory area but does no
initialization.
------------------------------------------------------------------------
*/

M *allocMemoryAreaBase(UL l)
 {
  if (l > bMU)
   {croak("Cannot allocate more memory in this memory model to satisfy request for 2**%u bytes", l);
   }

  UL mL = sizeof(struct M) + (1<<l);                       // Size of memory

  M *m  = malloc(mL);                                      // Allocate memory
  if (m == 0)
   {croak("Malloc failed to allocate 2**%u bytes", l);
   }

  memset(m, 0, sizeof(struct M));                          // Clear memory
  if (debugMemory) {memset(&(m->array), 240+l, 1<<l);}     // Mark free area to simplify debugging
  m->allocatedBytes = mL;                                  // Save allocation size

  
  return m;
 }

/*
------------------------------------------------------------------------
Allocate Memory Area - users should call this function to allocate a
memory area not backed by a file.
------------------------------------------------------------------------
*/

M **allocMemoryArea(UL l)
 {
  M *m = allocMemoryAreaBase(l);

  initializeMemoryArea(m, l);                              // Initialize the memory area

  M **mm = malloc(sizeof(struct M *));                     // Indirection to allow area to grow/shrink
  *mm = m;

  
  return mm;
 }

/*
------------------------------------------------------------------------
Compute size of backing file
------------------------------------------------------------------------
*/

UL sizeOfBackingFile(UL l)
 {
  UL s = (1<<l)+sizeof(struct M)+PAGESIZE;                 // Size of allocation
  
  return s;
 }

/*
------------------------------------------------------------------------
Allocate file backed memory area - users should call this function
to allocate a memory area backed by a file.

If we the user is opening the file, l will be 0, else if growMemory()
is the caller, l will have the log2(size) required.
------------------------------------------------------------------------
*/

M **allocPagedMemoryArea(char *f)
 {

  UL e = 0;                                                // Backing file existance
  HANDLE fh = createFile(f, &e);                           // Open backing file
  HANDLE vh;                                               // File mapping handle
  M     *m;                                                // Memory structure

  if (e)                                                   // File exists, user is opening it 
   {
    UL s = PAGESIZE;                                       // Minimum size 
      vh = createFileMapping(fh, s);                       // Map file 
       m = mapViewOfFile(vh, s);                           // View file
    UL S = m->allocatedBytes;                              // size of file
    unmapViewOfFile(m);                                    // Unmap file
    closeFileMappingHandle(vh);                            // Close file mapping

      vh = createFileMapping(fh, S);                       // Reopen at full size
      m  = mapViewOfFile(vh, S);                           // View file full size
    if (m->logMode == LogSave) {rollback(&m);}             // Rollback any uncommited changes
    m->transaction++;                                      // Transaction number
   }
  else
   {
    UL l = 10;                                             // Default size of allocation - it can grow
    UL s = sizeOfBackingFile(l);                           // Bytes in default allocation
      vh = createFileMapping(fh, s);                       // Map file 
       m = mapViewOfFile(vh, s);                           // View file
    m->allocatedBytes = s;                                 // Allocated bytes
    m->transaction    = 0;                                 // Count transactions
    strcpy(m->file, f);                                    // Copy in file name
    initializeMemoryArea(m, l);                            // Initialize memory
   }
 
  m->fileBacked = 1;                                       // File backed
  m->fileHandle = fh;                                      // File handle
  m->mapHandle  = vh;                                      // map handle

  M **mm = malloc(sizeof(struct M *));                     // Indirection pointer
  *mm = m;                                                 // Set indirection  
  
  return mm;                                                // One level of indirection
 }

/*
------------------------------------------------------------------------
Free Memory Area
------------------------------------------------------------------------
*/

void freeMemoryArea(M **mm)
 {

  M *m = *mm;
// free(mm);                                               // Free indirection pointer - this needs to be checked as it causes a SEGV, however like this the memory leak is small.

  if (m->fileBacked == 0)                                  // Non file backed
   {
    free(m);                                               // Free pointer to memory structure
   }

  else                                                     // File backed
   {
    HANDLE fh = m->fileHandle;                             // File handle of backing file
    HANDLE vh = m->mapHandle;                              // Handle for mapping
    flushViewOfFile(m);                                    // Write pages to file
    unmapViewOfFile(m);                                    // Unmap file
    closeFileMappingHandle(vh);                            // Close file mapping
    closeFileHandle(fh);                                   // Close file
   }

  
 }

/*
------------------------------------------------------------------------
Allocate a block of memory, size is specified as log2
------------------------------------------------------------------------
*/

UL allocMemory(M **m, UL l)
 {
  UL a;

// Die if request is too big

  if (l > bMU || l >= systemBitsWidth)
   {croak("Allocation request %u too big for memory model 2", l);
   }

// Find a suitable block

   {UL L = 0;
    UL i;
    for(i = l; i <= bMU; ++i)
     {a = getFreeAddress(*m, i);
      
      if (a < MMU)
       {L = i;
        clearFreeAddress(*m, L);
        break;
       }
     }

    
    
// Die if we are too close to the end of memory

    if (L &&  a > 0xffffffff - sizeof(**m))
     {croak("Out of memory");
     }

// Allocate more memory if necessary and retry allocation

    
    if (L == 0)
     {UL b = (*m)->length; 
      
 
      if (!(b < sizeof(l)*8 && l < sizeof(l)*8)) 
       {croak("Out of memory in memory model 2");
       }
   
      if (l <=  b)                               // Double block      
       {long L  = 1<<b;                          // Size of current memory  
        long L1 = L<<1;                          // Double size of current memory
        

        growMemory(m, b+1);                      // Allocate and copy

        if (getFreeAddress(*m, b) == 0)          // All of memory is free
         {  setFreeAddress(*m, 0, b+1);         
          clearFreeAddress(*m, b);              
         }
        else
         {  setFreeAddress(*m, L, b);            // Allocated memory is free
          clearFreeAddress(*m, b+1);             // rest remains as it was
         }
        
        return allocMemory(m, l);                // Retry allocation
       }

      else                                       // More than double block 
       {

        growMemory(m, l+1);                      // Allocate and copy
   
        if (getFreeAddress(*m, b) == 0)          // All of memory is free
         {  setFreeAddress(*m, 0, l+1);         
          clearFreeAddress(*m, b);              
         }
        else
         {UL i;
          for(i = b; i <= l; ++i)                // Split new down to old
           {setFreeAddress(*m, 1<<i, i);
           }
          clearFreeAddress(*m, l+1);             // Some memory was in use              
         }
        
        return allocMemory(m, l);
       }
     }
   
// Split intermediate blocks of located block

    else if (L > l) 
     {UL i;
      
      for(i = l; i < L; ++i)
       {
        setFreeAddress(*m, a + (1<<i), i);
       }
     }
   }

// Format memory allocation control byte and clear memoru block ready for use

  

  clearMemory(*m, a, 1<<l);
  setAllocLength(*m, a, l);

// Return result

  
  return a;
 }

/*
------------------------------------------------------------------------
Block position: returns 0 for a lower block and 1 for an upper block
------------------------------------------------------------------------
*/

long getAllocPosition(UL a, UL l)
 {
  long b = a % (1<<(l+1));

  if (b >= 1<<l)
   {
    return 1;
   }
  
  return 0;
 }
/*
------------------------------------------------------------------------
Check whether an offset is a free block, return its log2(size) if it is.
------------------------------------------------------------------------
*/

UL findFree(M *m, UL p, UL l)
 {
  UL i;
  for(i = 1; i <= l; ++i)                        // Search free areas
   {if (getFreeAddress(m, i) == p)
     {
      return i;
     }
   }

  
  return 0;
 } 

/*
------------------------------------------------------------------------
Copy memory area from a to b
------------------------------------------------------------------------
*/

void allocCopy(M **m, UL a, UL b, UL l)
 {
  UL  L = 1<<l;                                  // Length of object to copy
  UL  V = (*m)->centralVector;                   // Central Vector
  UL  S = (*m)->spona;                           // Spona         
  UL nV = V;                                     // In case Central Vector is relocated
  UL nS = S;                                     // In case Spona is relocated

  
// Relocate allocated areas contained in this block

  if (V != MMU)
   {UL p = a;
    for(; p < a+L;) 
     {UL fb = findFree(*m, p, l);                // Is this a free area 

      if (fb > 0)
       {setFreeAddress2(*m, p + b - a, fb);      // Update position of free area
        p += 1<<fb;                              // Skip over free area 
        continue;
       }

// Block size of allocated area

      UL B = getAllocLength(*m, p);

// Skip Central Vector as it is immediately relocatable

      if (p == V)
       {nV = p + b - a;                          // New position for CV
        p += 1<<B;                               // Skip CV
        continue;  
       }

// Skip Spona as it is immediately relocatable

      if (p == S)
       {nS = p + b - a;                          // New position for spona
        p += 1<<B;                               // Skip spona
        continue;  
       }

// Allocated block - relocate any contained object

      if (B >= MemoryMinimumSize)
       {UL o = getObjectNumber(*m, p);           // Get object number

// Objects with object number of zero or > MMU/2 do not not need relocation

        if (o > 0 && o < MMU/2)
         {UL Q = getObject(m, o);                // Check CV integrity

          if (p == Q)                            // Check CV integrity
           {setObjectPointer(m, o, p + b - a);   // Update CV
           }
          else                                   // CV integrity has failed
           {croak("Non object o=%u a=%u b=%u B=%u p=%u Q=%u", o, a, b, B, p, Q);
           }
         }

// Reposition HashST if necessary

        if (p == (*m)->hashST)
         {(*m)->hashST =  p + b - a;
         }

// Move up to next block

        p += 1<<B;
        continue;
       }

// Bad block

      croak("Too small memory block p=%u B=%u", p, B);
     }

    if (nV != V) {((*m)->centralVector = nV);}   // Update CV address
    if (nS != S) {((*m)->spona = nS);}           // Update address
   }

  memcpy(am(*m, b), am(*m, a), L);               // Copy data
  
 }

/*
------------------------------------------------------------------------
Shrink memory area if possible
------------------------------------------------------------------------
*/

void shrinkMemory(M **m)
 {

  UL B  = (*m)->length;                          // Current length
  UL B1 = B - 1;                                 // Half current length

// Shrink from top

  if      (B1 > MemoryMinimumSize && getFreeAddress(*m, B1) == 1<<(B1))
   {
    clearFreeAddress(*m, B1);
    UL B2 = B1 - 1;
    for(;B2 > MemoryMinimumSize && getFreeAddress(*m, B2) == 1<<(B2);)
     {clearFreeAddress(*m, B2);
      --B2;
     }
    ++B2;
    growMemory(m, B2);
   }

// Shrink from bottom

  else if (B > MemoryMinimumSize && getFreeAddress(*m, B1) == 0)
   {
    clearFreeAddress(*m,  B1);
    allocCopy(m, 1<<(B1), 0, B1);
    growMemory(m, B1);
   }

// Shrink empty memory

  else if (B > MemoryMinimumSize && getFreeAddress(*m, B) == 0)
   {
    clearFreeAddress(*m, B);
    setFreeAddress(*m, 0, MemoryMinimumSize);
    growMemory(m, MemoryMinimumSize);
   }

// Failed to shrink

  else
   {
   }

  
 }

/*
------------------------------------------------------------------------
Free memory area
------------------------------------------------------------------------
*/

void freeMemory2(M **m, UL a, UL l)
 {

  if (l == 0) {l = getAllocLength(*m, a);}

// Other free block of same size

  UL b = getFreeAddress(*m, l);

// Check alignment as a way of stopping bad free attempts

  if (a % (1<<l) != 0)
   {croak("Misaligned memory free address=%u, size=%u", a, l);
   }

// Free directly if no other block waiting

  if (b == MMU)
   {setFreeAddress(*m, a, l);
    shrinkMemory(m);
    
    return;
   }

// Fuse b to make a bigger block

  clearFreeAddress(*m, l);
 
// Fuse with already freed paired block above

  UL ap = getAllocPosition(a, l);
  UL bp = getAllocPosition(b, l);
  

  if (ap == 0 && bp == 1 && b == a + (1<<l))
   {
    freeMemory2(m, a, l+1);
    
    return;
   } 
 
// Fuse with already freed paired block below

  if (ap == 1 && bp == 0 && a == b + (1<<l))
   {
    freeMemory2(m, b, l+1);
    
    return;
   }

// Relocate the twin of a to b to liberate higher memory

  if (b < a) 
   {UL f = a;
    if (getAllocPosition(a, l))
     {
      f -= 1<<l;
      allocCopy(m, f, b, l);        // f is now free and below a
      freeMemory2(m, f, l+1);         
     }
    else
     {
      f += 1<<l;
      allocCopy(m, f, b, l);        // f is now free and above a
      freeMemory2(m, a, l+1);         
     }
    
    return;
   }

// Relocate b's twin to a to liberate higher memory

   {UL f = b;
    if (getAllocPosition(b, l))
     {
      f -= 1<<l;
      allocCopy(m, f, a, l);        // f is now free and below b
      freeMemory2(m, f, l+1);         
     }
    else
     {
      f += 1<<l;
      allocCopy(m, f, a, l);        // f is now free and above b
      freeMemory2(m, b, l+1);         
     }
    
    return;
   }
 }

void freeMemory(M **m, UL a)
 {freeMemory2(m, a, 0);
 }

/*
------------------------------------------------------------------------
Maps the value of MMU to -1 for printing as it makes dumps more readable
------------------------------------------------------------------------
*/

long nmi(UL a)
 {if (a == MMU) {return -1;}
  return a;
 }

/*
------------------------------------------------------------------------
Dump memory area
------------------------------------------------------------------------
*/

void dumpArea(M **mm, char *F)
 {

  M *m = *mm;

  FILE *f;
   {char b[1024]; memset(b, 0, sizeof(b));
    mkdir("out", 0);
    sprintf(b, "out\\%d", sizeof(MU));
    mkdir(b, 0);
    sprintf(b, "out\\%d\\%s.data", sizeof(MU), F);
    f = fopen(b, "w");
   }

  fprintf(f, "Memory:\n");
  fprintf(f, "  ObjectNumber=%u  centralVector=%d  centralVectorX=%u  hashST=%d  hashSTX=%u  spona=%d  GAH=%d  transaction=%u Log2(memory length)=%u\n  lastArrayElement=%u lastFoundHashElement=%u lastObjectFreed=%u\n",
    m->objectNumber,
    nmi(m->centralVector), m->centralVectorX,
    nmi(m->hashST), m->hashSTX,
    nmi(m->spona), nmi(m->GAH), m->transaction,
    m->length, m->lastArrayElement, m->lastFoundHashElement, m->lastObjectFreed);

  if (m->fileBacked) 
   {fprintf(f, "  Backing file: %s\n", m->file);
   }

// Free areas

   {UL i, L = bMU;
    for(i = 0; i <= L; ++i)
     {fprintf(f, "  f%u=%d", i, nmi(m->free[i]));
     }
    fprintf(f, "\n");
   }

// Memory contents

   {UL l = m->length;
    if (l > bMU) 
     {croak("Memory block %u too big", l);
     } 

    long i;
    long L = 1<<l;
    for(i = 0; i < L; ++i)
     {if (i % 4  == 0) {fprintf(f, " ");}
      if (i % 8  == 0) {fprintf(f, " ");}
      fprintf(f, "%02x", m->array[i]);
      if (i % 64 == 63) {fprintf(f, "\n");}
     }
    fprintf(f, "\n\n");
   }

// Spona

   {if (m->spona < MMU)
     {SP *S = am(m, m->spona);
      fprintf(f, "Spona offset=%u  count=%u extent=%u\n", (*mm)->spona, S->count, S->extent);
      long i;
      for(i = 0; i < S->count; ++i)
       {fprintf(f, "%d  ", S->array[i]);
       }
     }
    fprintf(f, "\n\n");
   }

// CVT

   fflush(f);
   if (m->centralVector != MMU) {dcv(mm, f);}
 
  fclose(f);
 
  
 }

void ddd(M **m)
 {dumpArea(m, "zz");
 }

/*
#######################################################################
# Logging
#######################################################################
*/

enum 
 {ActionSetGAH,
  ActionPutArray, 
  ActionSetArraySize, 
  ActionExtendArray, 
  ActionClearArray,
  ActionPopArray,
  ActionShiftArray, 
  ActionUnshiftArray,

  ActionPutIHash,  
  ActionPutRUHash,   ActionPutRDHash,
  ActionDeleteDHash, ActionDeleteUHash,

  ActionSaveArrayRBless, ActionSaveArrayFBless, 
  ActionSaveHashRBless,  ActionSaveHashFBless, 

 } saveActions;

/*
-----------------------------------------------------------------------
Get object number of log array - create if not present

The log is used to record user requests that change the relationships
between the objects stored in the memory structure that occur between
begin_work() and rollback(I) or commit().

If the actions are committed via commit(), the log is deleted. If the
actions are rolled back via rollback(), the information in this array is
used to undo the changes made by the user since begin_work() was called.
-----------------------------------------------------------------------
*/

UL getLog(M **m)
 {

  if ((*m)->log > 0)                             // Return log if it exists
   {
    return (*m)->log;  
   }

  UL l = allocArray(m);                          // Allocate log if it does not exist 
  (*m)->log = l;                                 // Save log

  
  return l;
 }

/*
-----------------------------------------------------------------------
Get object number of delayed delete array - create if not present

The delayed delete array is used to record user requests for the
deletion of objects stored in the memory structure that occur between
begin_work() and rollback(I) or commit().

If the actions are committed via commit(), the deletes areprocessed. If
the actions are rolled back via rollback(), these objects are not
deleted.
-----------------------------------------------------------------------
*/

UL getDD(M **m)
 {

  if ((*m)->DD > 0)                              // Return DD if it exists
   {
    return (*m)->DD;  
   }

  UL d = allocArray(m);                         // Allocate DD if it does not exist 
  (*m)->DD = d;                                 // Save DD                        

  
  return d;
 }

/*
-----------------------------------------------------------------------
Start work
-----------------------------------------------------------------------
*/

void begin_work(M **m)
 {
  getLog(m);                           // Create log
  getDD(m);                            // Create delayed deletes
  (*m)->logMode = LogSave;             // Start saving user actions
  
 }

/*
-----------------------------------------------------------------------
Nullify array

The arrays log and DD used for logging contain un refernce counted
refernces to objects in the memory structure. To free these arrays, each
element is set to zero, and then the array can be freed as normal.

-----------------------------------------------------------------------
*/

void nullifyArray(M **m, UL a)
 {

  long i, j = getArraySize(m, a);
  for(i = 0; i < j; ++i)
   {putArrayNanO(m, a, i, 0);          // Nullify element
   }
  clearArray(m, a);
  freeArray (m, a);                    // Free array now that it contains no references
 }

/*
-----------------------------------------------------------------------
Rollback setGAH
-----------------------------------------------------------------------
*/

void rbSetGAH(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL g = A->array[--A->h];             // Previous value         
  (*m)->GAH = g;                       // Reset GAH
  
 }

/*
-----------------------------------------------------------------------
Rollback setArraySize
-----------------------------------------------------------------------
*/

void rbSetArraySize(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL a = A->array[--A->h];             // Array
  UL s = A->array[--A->h];             // Previous value
  setArraySize(m, a, s);               // Reset array size
  
 }

/*
-----------------------------------------------------------------------
Rollback extendArray
-----------------------------------------------------------------------
*/

void rbExtendArray(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL a = A->array[--A->h];             // Array
  UL n = A->array[--A->h];             // Previous maximum size
//shrinkArray(m, a);
  
 }

/*
-----------------------------------------------------------------------
Rollback clearArray
-----------------------------------------------------------------------
*/

void rbClearArray(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL a = A->array[--A->h];             // Array
  UL s = A->array[--A->h];             // Previous value
  setArraySize(m, a, s);               // Reset array size
  
 }

/*
-----------------------------------------------------------------------
Rollback putArray
-----------------------------------------------------------------------
*/

void rbPutArray(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL a = A->array[--A->h];             // Array
  UL i = A->array[--A->h];             // Index
  UL e = A->array[--A->h];             // Old value
  putArray(m, a, i, e);                // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Rollback popArray
-----------------------------------------------------------------------
*/

void rbPopArray(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL a = A->array[--A->h];             // Array
  UL v = A->array[--A->h];             // Value popped
  pushArray(m, a, v);                  // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Rollback shiftArray
-----------------------------------------------------------------------
*/

void rbShiftArray(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL a = A->array[--A->h];             // Array
  UL v = A->array[--A->h];             // Value shifted
  unshiftArray(m, a, v);               // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Rollback unshiftArray
-----------------------------------------------------------------------
*/

void rbUnshiftArray(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL a = A->array[--A->h];             // Array
  shiftArray(m, a);                    // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Rollback insert new value
-----------------------------------------------------------------------
*/

void rbPutIHash(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL h = A->array[--A->h];             // Hash
  UL k = A->array[--A->h];             // Key 
  deleteHashKeyByIndex(m, h, k);       // Delete inserted value
  
 }

/*
-----------------------------------------------------------------------
Rollback replace undefined value
-----------------------------------------------------------------------
*/

void rbPutRUHash(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL h = A->array[--A->h];             // Hash
  UL k = A->array[--A->h];             // Key 
  putHashByIndex(m, h, k, 0);          // Undefine data
  
 }

/*
-----------------------------------------------------------------------
Rollback replace defined value
-----------------------------------------------------------------------
*/

void rbPutRDHash(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL h = A->array[--A->h];             // Hash
  UL k = A->array[--A->h];             // Key 
  UL d = A->array[--A->h];             // Data replaced 
  putHashByIndex(m, h, k, d);          // Reset data to previous value      
  
 }

/*
-----------------------------------------------------------------------
Rollback delete of key with undefined data
-----------------------------------------------------------------------
*/

void rbDeleteUHash(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL h = A->array[--A->h];             // Hash
  UL k = A->array[--A->h];             // Key 
  putHashByIndex(m, h, k, 0);          // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Rollback delete of key with defined data
-----------------------------------------------------------------------
*/

void rbDeleteDHash(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL h = A->array[--A->h];             // Hash
  UL k = A->array[--A->h];             // Key 
  UL d = A->array[--A->h];             // Data
  putHashByIndex(m, h, k, d);          // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Rollback bless of array that was already blessed
-----------------------------------------------------------------------
*/

void rbSaveArrayRBless(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL a = A->array[--A->h];             // Array  
  UL o = A->array[--A->h];             // Old blessing hash key 
  saveArrayBless(m, a, o);             // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Rollback bless of array that was not already blessed
-----------------------------------------------------------------------
*/

void rbSaveArrayFBless(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL a = A->array[--A->h];             // Array  
  saveArrayBless(m, a, 0);             // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Rollback bless of hash that was already blessed
-----------------------------------------------------------------------
*/

void rbSaveHashRBless(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL h = A->array[--A->h];             // Hash
  UL o = A->array[--A->h];             // Old blessing hash key 
  saveHashBless(m, h, o);              // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Rollback bless of hash that was not already blessed
-----------------------------------------------------------------------
*/

void rbSaveHashFBless(M **m)
 {
  UL l = getLog(m);                    // Address log

  Array *A = addressArray(m, l);       // Address log array
  UL h = A->array[--A->h];             // Hash   
  saveHashBless(m, h, 0);              // Restore old value
  
 }

/*
-----------------------------------------------------------------------
Roll Back one action
-----------------------------------------------------------------------
*/

void rollback1(M **m)
 {
  UL l = getLog(m);                    // Addresse log
  UL s = (*m)->logMode;                // Save logging mode
  (*m)->logMode = LogRollBack;         // Stop saving user actions

  Array *A = addressArray(m, l);
  UL a = A->array[--A->h];             // Action to roll back
  void (*f[])(M **m) =
   {&rbSetGAH, &rbPutArray, &rbSetArraySize, &rbExtendArray, &rbClearArray, &rbPopArray, &rbShiftArray, &rbUnshiftArray,
    &rbPutIHash, &rbPutRUHash, &rbPutRDHash, &rbDeleteDHash, &rbDeleteUHash,
    &rbSaveArrayRBless, &rbSaveArrayFBless, 
    &rbSaveHashRBless,  &rbSaveHashFBless, 
   };
  f[a](m);

  (*m)->logMode = s;                   // Restore saved logging mode
  
 }

/*
-----------------------------------------------------------------------
Roll Back

The delayed deletes array is nullified, while the log array is processed
in reverse order to undo the users actions.
-----------------------------------------------------------------------
*/

void rollback(M **m)
 {
  UL l = getLog(m);                    // Create log
  UL d = getDD(m);                     // Create delayed deletes
  (*m)->logMode = LogRollBack;         // Stop saving user actions

  nullifyArray(m, d);                  // Nullify deletes

  long i;                              // Undo user actions
  for(;getArraySize(m, l) > 0;)
   {rollback1(m);
   }

  nullifyArray(m, l);                  // Nullify log

  (*m)->logMode = LogNormal;           // Resume normal logging
  
 }

/*
-----------------------------------------------------------------------
Commit

The log array is nullified and the pending deletes in the delayed
deletes array is are executed.
-----------------------------------------------------------------------
*/

void commit(M **m)
 {
  UL l = getLog(m);                    // Create log
  UL d = getDD(m);                     // Create delayed deletes
  (*m)->logMode = LogRollBack;         // Stop saving user actions

  nullifyArray(m, l);                  // Nullify log

   {long i;                            // Execute deletes
    long j = getArraySize(m, d);       // Number of deletes 
    for(i = 0; i < j; ++i)             // Each delete 
     {UL o = getArray(m, d, i);        // Get delete
      freeObject(m, o);                // Execute delete
     }
    nullifyArray(m, d);                // Nullify deletes
   }

  (*m)->logMode = LogNormal;           // Resume normal logging
 
  
 }

/*
-----------------------------------------------------------------------
Delete Log entry
-----------------------------------------------------------------------
*/

void saveDelete(M **m, UL o)
 {
  if ((*m)->logMode == LogSave)
   {UL d = getDD(m);
    UL s = getArraySize(m, d);
    putArrayNanO(m, d, s, o);          // Save delete request in log
   } 
  
  return;
 }

/*
-----------------------------------------------------------------------
Log entry
-----------------------------------------------------------------------
*/

//void saveLog1(UL a, M **m)
// {sTART saveLog1 "action=%u", a
//  if ((*m)->logMode == LogSave)
//   {UL l = getLog(m);
//    UL s = getArraySize(m, l);
//    putArrayNanO(m, l, s,   a);        // Save action in log   
//   } 
//  rETURN
//  return;
// }

void saveLog2(UL a, M **m, UL o)
 {
  if ((*m)->logMode == LogSave)
   {UL l = getLog(m);
    UL s = getArraySize(m, l);
    putArrayNanO(m, l, s,   o);        // Save object in log   
    putArrayNanO(m, l, s+1, a);        // Save action in log   
   } 
  
  return;
 }

void saveLog3(UL a, M **m, UL o, UL i)
 {
  if ((*m)->logMode == LogSave)
   {UL l = getLog(m);
    UL s = getArraySize(m, l);
    putArrayNanO(m, l, s,   i);        // Save index  in log   
    putArrayNanO(m, l, s+1, o);        // Save object in log   
    putArrayNanO(m, l, s+2, a);        // Save action in log   
   } 
  
  return;
 }

void saveLog4(UL a, M **m, UL o, UL i, UL v)
 {
  if ((*m)->logMode == LogSave)
   {UL l = getLog(m);
    UL s = getArraySize(m, l);
    putArrayNanO(m, l, s,   v);        // Save value  in log   
    putArrayNanO(m, l, s+1, i);        // Save index  in log   
    putArrayNanO(m, l, s+2, o);        // Save object in log   
    putArrayNanO(m, l, s+3, a);        // Save action in log   
   } 
  
  return;
 }

/*
#######################################################################
# Central Vector
#######################################################################
*/

/*
-----------------------------------------------------------------------
Address central vector
-----------------------------------------------------------------------
*/

CVT *getCV(M *m)
 {
  CVT *cv = am(m, m->centralVector);    // Address CV
  
  return cv;
 }

/*
-----------------------------------------------------------------------
Get central vector extent required to hold next object number
-----------------------------------------------------------------------
*/

UL getCVX(M *m)
 {
  UL n = m->objectNumber;                        // Current object number
  if (n == 0) {return 0;}                        // CVT not needed 
  UL s = sizeof(struct CVT) + n * sizeof(MU);    // Size of CVT required
  UL b = bits(s);                                // Log2(size)
  
  return b;
 }

/*
-----------------------------------------------------------------------
Set central vector extent - number of objects that the central vector
can currently store

l - log2(size of block containing CV)
-----------------------------------------------------------------------
*/

void setCVX(M *m, UL l)
 {
  checkAllocSize(l);                   // Check block size
  UL L = 1<<l;                         // Size of Central Vector memory block
  UL w = L - sizeof(struct CVT);       // Size of area available for pointers           
     w -= w % sizeof(MU);              // Round down
     w /= sizeof(MU);                  // Calculate CV extent
  m->centralVectorX = w;               // Save
  
 }

/*
-----------------------------------------------------------------------
Get next object number

Object numbers start at 1. Thus an object that does not exist has number
0.
-----------------------------------------------------------------------
*/

UL getNewObjectNumber(M **m)
 {

  UL o = popSP(m);                     // Try to recycle an object number   
  if (o > 0)                           // from the spona
   {
    return o;                         
   }

  UL n = ++((*m)->objectNumber);
  
  return n;                            // Generate a new object number  
 }

/*
-----------------------------------------------------------------------
Clear Central Vector 
-----------------------------------------------------------------------
*/

void clearCV(M *m)
 {
  UL v = m->centralVector;             // Offset of CV
  UL W = m->centralVectorX;            // Extent of CV
  CVT *cv = am(m, v);                  // Address CV
  UL i;
  for(i = 0; i < W; ++i)
   {cv->array[i] = MMU;                // Set slot to non object
   }

  
 }

/*
-----------------------------------------------------------------------
Allocate Central Vector if not yet allocated
-----------------------------------------------------------------------
*/

UL allocCV(M **m)
 {UL v = (*m)->centralVector;          // Offset of CV

  if (v == MMU)                        // Not yet allocated
   {UL l = 4;                          // Default size for CV - it grows as needed
    v = allocMemory(m, l);             // Allocate CV
    (*m)->centralVector = v;           // Save offset of CV
    setCVX(*m, l);                     // Save extent of CV
    clearCV(*m);                       // Clear CV
   }

  return v;
 }

/*
------------------------------------------------------------------------
Re-allocate and relocate Central Vector
------------------------------------------------------------------------
*/

void reallocCV(M **m)
 {
  UL V = allocCV(m);                   // Address of CV
  UL l = getAllocLength(*m, V);        // Size of block
  UL s = getCVX(*m);                   // Size needed for CV

  if (s == 0)                          // CV no longer needed
   {(*m)->centralVector  = MMU;        // Mark a not in use
    (*m)->centralVectorX = 0;          // With no extent
    freeMemory(m, V);                  // Free CV
    
    return;
   }

  if (s == l)                          // Existing CV should be fine
   {
    return;
   }

  UL p = allocMemory(m, s);            // Allocate new CV
  (*m)->centralVector = p;             // Set new CV
  setCVX(*m, s);                       // Set new CV extent
  clearCV(*m);                         // Clear CV

  if (s > l)                            
   {allocCopy(m, V, p, l);             // Copy in old CV
   }
  else                                 // Allocate smaller CV
   {allocCopy(m, V, p, s);             // Copy active part of old CV
   }

  setAllocLength(*m, p, s);            // Reset allocation length destroyed by allocCopy
  freeMemory(m, V);                    // Free old CV

  
  return;
 }

/*
------------------------------------------------------------------------
Dump Central Vector
------------------------------------------------------------------------
*/

void dcv(M **m, FILE *f)
 {UL V = allocCV(m);                   // Address CV
  UL W = (*m)->centralVectorX;         // Extent of CV

  char *lm[] = {"normal", "save", "rollback", "commit"};
  fprintf(f, "LogMode %s log=%u DD=%u transaction=%u\n\n", lm[(*m)->logMode], (*m)->log, (*m)->DD, (*m)->transaction);

  fprintf(f, "CVT at address %u extent %u\n\n", V, W);
 
  if ((*m)->fileBacked > 0)            // File backed
   {fprintf(f, "Backing File=%s, allocated bytes=%u\n", (*m)->file, (*m)->allocatedBytes);
   }

// Summary
 
   {UL i;
    for(i = 1; i <= W; ++i)
     {UL o = getObjectOffset(m, i);
      if (o % 2 == 0)
       {fprintf(f, "(%u,%d) ", i, o);
       }
     }
    fprintf(f, "\n");
   }

// Contents
 
   {UL i;
    fprintf(f, "\n\n");
    fprintf(f, "Object  bits  Refs  Offset  Type\n");

    for(i = 1; i <= W; ++i)
     {UL o = getObjectOffset(m, i);
      if (o % 2 == 0)
       {UL length = getAllocLength  (*m, o);

        UL offset  = getObjectOffset        (m, i);
        UL oType   = getObjectType          (m, i);
        UL  refs   = getObjectReferenceCount(m, i);
        char *types[] = {"Any", "String", "HashKey", "Array", "Hash", "HST"};
        char *type = types[oType];

        if (oType == ObjectTypeHash && offset == (*m)->hashST) {type = "HashST";}

        fprintf(f, "  %4d  %4d  %4d  %6d  %-16s\n", i, length, refs, offset, type);
       }
     }
   }

// Strings
 
   {UL i;
    fprintf(f, "\nStrings\n");
    fprintf(f, "Number  Length Data\n");

    for(i = 1; i <= W; ++i)
     {UL o = getObjectOffset          (m, i);
      if (o % 2 == 0)
       {UL oType = getObjectType      (m, i);

        if (oType == ObjectTypeString)  
         {char b[128];
          String *s = addressString       (m, i);
          getStringContents(m, i, b, sizeof(b));
  
          fprintf(f, "%6d   %5d %s\n", i, s->length, b);
         }
       }
     }
   }

// HashKeys
 
   {UL i;
    fprintf(f, "\nHash Keys\n");
    fprintf(f, "Number  Length Data\n");

    for(i = 1; i <= W; ++i)
     {UL o = getObjectOffset(m, i);
      if (o % 2 == 0)
       {UL oType = getObjectType(m,  i);
        if (oType == ObjectTypeHashKey)  
         {char b[128];
          HashKey *k = addressHashKey(m, i);
          UL sLength = k->length; if (sizeof(b)-1 < sLength) {sLength = sizeof(b)-1;}
          memset(b, 0, sizeof(b));
          memcpy(b, k->array, sLength);
  
          fprintf(f, "%6d   %5d %s\n", i, k->length, b);
         }
       }
     }
   }

// Arrays
 
   {UL i;
    fprintf(f, "\nArrays\n");
    fprintf(f, "Number  Offset  Bless  Low  High  Size  Nax   Contents\n");

    for(i = 1; i <= W; ++i)
     {UL o = getObjectOffset(m, i);
      if (o % 2 == 0)
       {UL oType = getObjectType    (m, i);

        if (oType == ObjectTypeArray)  
         {Array *A = addressArray       (m, i);
          UL p     = getObjectOffset(m, i);
          UL s     = getArraySize   (m, i);
  
          fprintf(f, "  %4d  %6d   %4d %4d  %4d  %4d  %4d", i, p, A->blessed, A->l, A->h, s, arrayMax(m, i));

          long j, k = 0;
          for(j = 0; j < getArraySizeFromAddress(A); ++j,++k)
           {UL e = getArray(m, i, j);
            fprintf(f, "  [%u]=%u,", k, e);
           }
          fprintf(f, "\n"); 
         }
       }
     }
   }

// Hashes
 
   {UL i;
    fprintf(f, "\nHashes\n");
    fprintf(f, "Number  Offset  Bless  Count  Buckets  maxPath  Iter  Type     Contents\n");

    for(i = 1; i <= W; ++i)
     {UL o = getObjectOffset(m, i);
      if (o % 2 == 0)
       {UL oType = getObjectType    (m, i);

        if (oType == ObjectTypeHash)  
         {Hash *h  = am(*m, getObjectOffset(m, i));
          UL p     = getObjectOffset(m, i);
          UL b     = getHashBuckets (m, p);
          UL c     = h->count;
          UL mp    = h->maxPath;
          long it  = nmi(h->iterator);

          char *t = "normal"; if (p == (*m)->hashST) {t = "HashST";}
  
          fprintf(f, "  %4u  %6u   %4u   %4u     %4u     %4u  %4d  %s ", i, p, h->blessed, c, b, mp, it, t);

          long j;
          for(j = 0; j < b; ++j)
           {UL k = h->array[j].key;
            UL p = h->array[j].path; 
            UL d = h->array[j].data;        
            if (k == 0 && p == 0) {continue;} 
            fprintf(f, "  [%u]{%u}=(%u,%u), ", j, k, d, p);
           }
          fprintf(f, "\n"); 
         }
       }
     }
   }
 }

/*
------------------------------------------------------------------------
Dump Array and Hash sizes
------------------------------------------------------------------------
*/

void dahs(M **m)
 {UL V = allocCV(m);                   // Address CV
  UL W = (*m)->centralVectorX;         // Extent of CV

// Arrays
 
   {UL i;
    fprintf(stderr, "\nArrays\n");
    fprintf(stderr, "Number  Offset  Bless  Low  High  Size  Nax\n");

    for(i = 1; i <= W; ++i)
     {UL o = getObjectOffset(m, i);
      if (o % 2 == 0)
       {UL oType = getObjectType    (m, i);

        if (oType == ObjectTypeArray)  
         {Array *A = addressArray       (m, i);
          UL p     = getObjectOffset(m, i);
          UL s     = getArraySize   (m, i);
  
          fprintf(stderr, "  %4d  %6d   %4d %4d  %4d  %4d  %4d\n", i, p, A->blessed, A->l, A->h, s, arrayMax(m, i));
         }
       }
     }
   }

// Hashes
 
   {UL i;
    fprintf(stderr, "\nHashes\n");
    fprintf(stderr, "Number  Offset  Bless  Count  Buckets  maxPath  Iter  Type\n");

    for(i = 1; i <= W; ++i)
     {UL o = getObjectOffset(m, i);
      if (o % 2 == 0)
       {UL oType = getObjectType    (m, i);

        if (oType == ObjectTypeHash)  
         {Hash *h  = am(*m, getObjectOffset(m, i));
          UL p     = getObjectOffset(m, i);
          UL b     = getHashBuckets (m, p);
          UL c     = h->count;
          UL mp    = h->maxPath;
          long it  = nmi(h->iterator);

          char *t = "normal"; if (p == (*m)->hashST) {t = "HashST";}
  
          fprintf(stderr, "  %4u  %6u   %4u   %4u     %4u     %4u  %4d  %s\n", i, p, h->blessed, c, b, mp, it, t);
         }
       }
     }
   }
 }

/*
-----------------------------------------------------------------------
Get object type
-----------------------------------------------------------------------
*/

UL getObjectType(M **m, UL n)
 {
  UL p = getObject(m, n);
  O *o = am(*m, p);
  
  return o->type;
 }

/*
-----------------------------------------------------------------------
Get address of global array or hash
-----------------------------------------------------------------------
*/

UL getGAH(M **m)
 {
  
  return (*m)->GAH;
 }

/*
-----------------------------------------------------------------------
Set address of global array or hash
-----------------------------------------------------------------------
*/

void setGAH(M **m, UL o)
 {
  UL e = (*m)->GAH;
  saveLog2(ActionSetGAH, m, e);  
  if (e > 0) {decReferenceCount(m, e);}
  (*m)->GAH = o;
  if (o > 0) {incReferenceCount(m, o);}
  
 }

/*
-----------------------------------------------------------------------
Get string contents

o - object number
b - buffer to copy string into
l - length of buffer
-----------------------------------------------------------------------
*/

void getStringContents(M **m, UL n, char *b, UL l)
 {String *s = addressString(m, n);
  UL sl = s->length; if (sl >= l) {sl = l - 1;};
  memset(b, 0, l);
  memcpy(b, s->array, sl);
 }

/*
-----------------------------------------------------------------------
Get object reference count

o - object number
-----------------------------------------------------------------------
*/

UL getObjectReferenceCount(M **m, UL n)
 {
  UL p = getObject(m, n);
  O *o = am(*m, p);
  MU r = o->referenceCount;
  
  return r;
 }

/*
------------------------------------------------------------------------
Get object number

p - offset of object in memory structure
-----------------------------------------------------------------------
*/

UL getObjectNumber(M *m, UL p)
 {O *o = am(m, p);
  return o->number;
 }

/*
------------------------------------------------------------------------
Set object number

p - offset in memory structure of object whose number is to be set
o - object number
-----------------------------------------------------------------------
*/

void setObjectNumber(M *m, UL p, UL n)
 {O *o = am(m, p);
  o->number = n;
 }

/*
------------------------------------------------------------------------
Get current offset of an object with a given number via Central Vector.

o - object number

This is the same as getObjectOffset() except that checks are made to
insure that the object exists.
-----------------------------------------------------------------------
*/

UL getObject(M **m, UL o)
 {
  UL V = allocCV(m);                   // Address CV
  UL W = (*m)->centralVectorX;         // Extent of CV

  if (o <= W)
   {CVT *c = am(*m, V);                // CVT
    UL p = c->array[o-1];              // Current offset

    if (p == MMU)
     {croak("Inactive object number %u", o);
     }

    
    return p;
   }

  croak("Object %u outside central vector at offset %u with extent %u", o, V, W);
 }

/*
------------------------------------------------------------------------
Get current offset of an object with a given number via Central Vector.

o - object number

This is the same as getObject() except that no checks are made to insure
that the object exists or is valid. This function should only be used
when it is certain that the object does in fact exist in the CV.
-----------------------------------------------------------------------
*/

UL getObjectOffset(M **m, UL o)
 {UL V = allocCV(m);                   // Address CV

  CVT *c = am(*m, V);                  // CV
  return c->array[o-1];                // Current offset
 }

/*
------------------------------------------------------------------------
Set Central Vector entry for object with this offset and number

o - number of object whose offset in the memory structure is to be
recorded ib the CVT

p - offset in memory structure of object 
-----------------------------------------------------------------------
*/

void setObjectPointer(M **m, UL o, UL p)
 {
  UL V = allocCV(m);                   // Address of CV
  UL W = (*m)->centralVectorX;         // Objects in CV

  if (o <= W)
   {CVT *c = am(*m, V);                // CV
    c->array[o-1] = p;                 // Set offset in CV
    
    return;
   }
  croak("CVT too small (%u) to contain object %u", W, o );
 }

/*
------------------------------------------------------------------------
Update the object number of an object and set its entry in the CV.

o - object number
p - offset to object in memory structure
-----------------------------------------------------------------------
*/

void putObjectInCV(M **m, UL o, UL p)
 {
  setObjectNumber ( *m, p, o);         // Set object number in object
  setObjectPointer(  m, o, p);         // Save offset of object in CV by objedct number-
  
 }

/*
------------------------------------------------------------------------
Allocate object of specified size and indeterminate type.

s - Size of storage required (does not include object prefix - it will be
added) in bytes.

Returns the number of the object created. You can convert this to the
offset of the object in the memory structure by calling getObjectOffset.
-----------------------------------------------------------------------
*/

UL allocObject(M **m, UL s)
 {
  UL S = s + sizeof(struct O);         // Size + memory allocation control byte + reference count + object number 
  UL o = getNewObjectNumber(m);        // Get a new object number 

// Place object address in Central Vector

  UL i;
  for(i = 0; i < bMU; ++i)             // Allow CV to expand if necessary
   {allocCV(m);                        // Address CV
    UL W = (*m)->centralVectorX;       // Extent of CV

    if (o <= W)
     {UL p = allocMemory(m, bits(S));  // Allocate a memory block that is big enough
      putObjectInCV     (m, o, p);     // Update CV
      zeroReferenceCount(m, o);        // Zero object reference count
      
      return o;                        // Return object number
     }
    reallocCV(m);                      // reallocate CV if too small
   }

  croak("Unable to expand Central Vector to contain new object");
 }

// Same as above except that the object prefix is assumed to be in the specified size

UL allocObject2(M **m, UL s)
 {return allocObject(m, s - sizeof(struct O));
 }

/*
------------------------------------------------------------------------
Reallocate object of specified size and indeterminate type.

o - object to be reallocated

s - Size of storage required (does not include object prefix - it will
be added) in bytes.

copy - a function to copy data from the old object to the new object
befor we free it.

Returns the number of the object created. You can convert this to the
offset of the object in the memory structure by calling
getObjectOffset().
-----------------------------------------------------------------------
*/

void reallocObject(M **m, UL o, UL s, void (*copy)(M **m, UL from, UL to, UL l))
 {

  UL l = bits(s + sizeof(struct O));   // Log2(Size of required block)
  UL p = allocMemory(m, l);            // Allocate a memory block that is big enough
  UL q = getObject  (m, o);            // Offset of existing object 

// Set object number of new allocation

  putObjectInCV  ( m, o, p);           // Update CV, its an existing object so CVT will not change
  setObjectNumber(*m, q, 0);           // Zero object number of old object so that allocCopy will not relocate it

// Copy data if copy function supplied

   if (copy)
    {(*copy)(m, q, p, l);
    }

// Copy referenceCount and type from old to new object

   {O *P = am(*m, p);
    O *Q = am(*m, q);

    P->referenceCount = Q->referenceCount; // Copy object attributes
    P->type           = Q->type;
   }

  freeMemory(m, q);                    // Free old object
  
 }

// The same as the above except that the object prefix is assumed to be contained in the size

void reallocObject2(M **m, UL o, UL s, void (*copy)(M **m, UL from, UL to, UL l))
 {reallocObject(m, o, s - sizeof(struct O), copy);
 }  

/*
------------------------------------------------------------------------
Free object by object number immediately
-----------------------------------------------------------------------
*/

void freeObjectImmediately(M **m, UL o)
 {

  UL p = getObject(m, o);              // Offset of memory block containing this object

  UL t = getObjectType(m, o);          // Free by object type
  void (*f[])(M **m, UL o) = {&freeNothing, &freeNothing, &freeHashSTKey, &freeArrayObject, &freeHashObject};
  (*(f[t]))(m, o);

  p = getObject(m, o);                 // It has probably moved by now, so readdress

  freeMemory(m, p);                    // Free memory block
  putSP(m, o);                         // Put object number on spona
  
  
 }

/*
------------------------------------------------------------------------
Clean up - removes any objects whose reference count has fallen to zero.
-----------------------------------------------------------------------
*/

void cleanUp(M **m)
 {

  for(;(*m)->lastObjectFreed > 0;)
   {MU f = (*m)->lastObjectFreed;
           (*m)->lastObjectFreed = 0;
    freeObjectImmediately(m, f);
   }
  
  
 }

/*
------------------------------------------------------------------------
Free object by object number

WARNING: This should only be performed for objects whose reference count
is zero (unless you are testing). No test is made on the reference count
to make sure it is zero.

-----------------------------------------------------------------------
*/

void freeObject(M **m, UL o)
 {

  if ((*m)->logMode == LogSave)          // Logging
   {saveDelete(m, o);                    // Save delete until commit
   }
  else                                   // Not logging
   {cleanUp(m);

    (*m)->lastObjectFreed = o;           // Free this object very soon
   }
  
  
 }

/*
------------------------------------------------------------------------
unfree object by object number

Recovers an object from pending free in the event that the object is
used again before the free was triggered by another object being freed.

-----------------------------------------------------------------------
*/

void unfreeObject(M **m, UL o)
 {

  if ((*m)->lastObjectFreed == o)
   {(*m)->lastObjectFreed = 0;
   }
  
 }

/*
------------------------------------------------------------------------
Get object reference count

n - number of object whose reference count is to be got
-----------------------------------------------------------------------
*/

UL getReferenceCount(M **m, UL n)
 {UL p = getObjectOffset(m, n);
  O *o = am(*m, p);
  return o->referenceCount;
 }

/*
------------------------------------------------------------------------
Zero object reference count

n - number of object whose reference count is to be set
-----------------------------------------------------------------------
*/

void zeroReferenceCount(M **m, UL n)
 {UL p = getObjectOffset(m, n);
  O *o = am(*m, p);
  o->referenceCount = 0;
 }

/*
------------------------------------------------------------------------
Increment object reference count if possible

n - number of object whose reference count is to be incremented
------------------------------------------------------------------------
*/

void incReferenceCount(M **m, UL n)
 {UL p = getObjectOffset(m, n);
  O *o = am(*m, p);
  if (o->referenceCount == 0)        // Stop pending free if necessary
   {unfreeObject(m, n);
   } 
  o->referenceCount++;
 }

/*
------------------------------------------------------------------------
Decrement object reference count if possible

n - number of object whose reference count is to be decremented

Objects whose reference count drops to zero are freed, one step behind,
giving the caller an opportunity to save the object elsewhere (and thus
raise its reference count).
2------------------------------------------------------------------------
*/

void decReferenceCount(M **m, UL n)
 {
  UL p = getObject(m, n);
  O *o = am(*m, p);

  if (o->referenceCount  > 0) {o->referenceCount--;}

  if (o->referenceCount == 0)          // Free object if reference count is zero)
   {freeObject(m, n);
   } 

  
 }

/*
------------------------------------------------------------------------
Free object type ANY - does nothing because this object type does not
reference any other objects

o - number of object

The free*() functions are called to decrement the reference counts of any
objects they reference.

------------------------------------------------------------------------
*/

void freeNothing(M **m, UL o)
 {
 }

/*
#######################################################################
# Spona
#######################################################################
*/

/*
-----------------------------------------------------------------------
Get Spona Extent

The spona is assumed to exist
-----------------------------------------------------------------------
*/

UL getSPX(M *m)
 {

  if (m->spona >= MMU)
   {croak("Spona does not exist");
   }   

  UL l = getAllocLength(m, m->spona);               // Size of spona memory block
  UL x = ((1<<l) - sizeof(struct SP)) / sizeof(MU); // Extent of Spona

  
  return x;
 }

/*
-----------------------------------------------------------------------
log2(Minimum spona size to hold n object numbers)
-----------------------------------------------------------------------
*/

UL minSP(UL n)
 {

  UL x = bits(sizeof(struct SP) + n * sizeof(MU));

  
  return x;
 }

/*
-----------------------------------------------------------------------
Get the Spona - allocating it if necessary
-----------------------------------------------------------------------
*/

SP *getSP(M **m)
 {

  SP *S;
  if ((*m)->spona == MMU)
   {UL p = allocMemory(m, minSP(3));             // Allocate spona
    (*m)->spona = p;                             // Allocate spona
    S         = am(*m, p);                       // Address newly allocated spona  
    S->count  = 0;                               // Empty
    S->extent = getSPX(*m);                      // Extent of Spona
   }
  else
   {S         = am(*m, (*m)->spona);             // Address old spona  
   }

  
  return S;         
 }

/*
-----------------------------------------------------------------------
Put a spare object number on the spona

If the number to be put back is equal to the next object number, then
the number is not put on the Spona, the next object number is reduced
instead as this saves spaces in the Spona and is faster. Now, either the
next lower number is in use or it is on the Spona: we can easily check
this by looking in the CVT (the spona is not ordered by object number,
the CVT is). The CVT entry for this object number will have its low
order bit on, the rest of the entry in the CVT will be the 2*(array
index) in the Spona. Thus if the next lower number indexes a CVT entry
with its high order bit on, then the Next Object Number can be reduced
forther. The CVT entry will be set to MMU, and the hole created in the
Spona by the removal of this next object number can be filled by
swapping in the object number at the top of the Spona, updating its
corresponding entry in the CVT in the process. Now the Spona can be
popped as its top element is not needed, and in the poping process, it
may be reduced in size. At the end of this process, I try to reduce the
CVT.
-----------------------------------------------------------------------
*/

void putSP(M **m, UL o)
 {

  if (o == (*m)->objectNumber)                    // Can we reduce next Object Number 
   {--((*m)->objectNumber);                       // do so
    CVT *cv = getCV(*m);                          // Readdress CV in case it moved
         cv->array[o-1] = MMU;                    // Remove object completely from CV
    UL i;
    for(i = o-1; i > 0; --i)                      // Process lower, contiguous CVT entries
     {CVT *cv = getCV(*m);                        // Readdress CV in case it moved
      if (cv->array[i-1] % 2 == 0) {break;}       // Number not in Spona
      --((*m)->objectNumber);                     // Lower next Object number

      SP *S = getSP(m);                           // Address Spona
      if (S->array[S->count-1] != i)              // Next lower object number is not conveniently on top of the spona
       {UL s = cv->array[i-1]>>1;                 // Position in Spona
        UL t = S->array[S->count-1];              // Top element from Spona
        cv->array[t-1] = (s<<1)+1;                // Show position in spona
        S->array[s] = t;                          // Fill hole
       }                                          
      cv->array[i-1] = MMU;                       // Remove object completely from CV
      popSP(m);                                   // Pop it from Spona so we get shrinkage if possible
     }                                            
        
    reallocCV(m);                                 // See if CV can be made smaller
    
    return;
   }

  SP *S = getSP(m);                               // Address spona

// Realloc Spona if needed

  if (S->count == S->extent)
   {
    UL  a = (*m)->spona;                          // Address spona
    UL  A = S->MAC;                               // Size of old Spona
    UL  b = allocMemory(m, A+1);                  // Allocate new spona
    S = getSP(m);                                 // Readdress spona
    (*m)->spona = b;                              // Set new Spona address
    SP *s = am(*m, b);                            // Address new spona 
    UL dA = (1<<A) - sizeof(struct SP);           // Size of data area in old spona
    memcpy(s->array, S->array, dA);               // Copy data from old to new spona
    s->count  = S->count;                         // Copy count
    s->extent = getSPX(*m);                       // Extent of Spona
    freeMemory(m, a);                             // Free old Spona
    S = getSP(m);                                 // Address new spona
   }

  S->array[(S->count)] = o;                       // Put object on Spona
  CVT *cv = getCV(*m);                            // Address CV
  cv->array[o-1] = (S->count<<1)+1;               // Show position in Spona  
  (S->count)++;                                   // Increment top of spona

  
 }

/*
-----------------------------------------------------------------------
Get a spare object number from the spona
-----------------------------------------------------------------------
*/

UL popSP(M **m)
 {

  if ((*m)->spona == MMU)                        // Spona not allocated ywt
   {
    return 0;
   }

  SP *S = getSP(m);                              // Address spona now it is known to exist

// Jettison Spona after extracting last object number from it

  if (S->count == 1)
   {UL n = S->array[0];                          // Get object from Spona
    UL a = (*m)->spona;                          // Address spona memory block
    (*m)->spona = MMU;                           // No spona   
    freeMemory(m, a);                            // Free Spona
    
    return n;
   } 

// Try to shrink Spona

  if (S->count > 1)
   {UL n = S->array[--(S->count)];               // Get object from Spona

     {UL a = (*m)->spona;                        // Address spona memory block   
      UL A = S->MAC;                             // Log2(current size) 
      UL B = minSP(S->count);                    // Log2(size needed for spona)
      if (B < A)
       {UL  b = allocMemory(m, B);               // Allocate new spona
        S = getSP(m);                            // Readdress 
        (*m)->spona = b;                         // Save offset
        SP *s = am(*m, b);                       // Address new spona 
        UL dA = (1<<B) - sizeof(struct SP);      // Size of data area in old spona
        memcpy(s->array, S->array, dA);          // Copy data from old to new spona
        s->count  = S->count;                    // Copy count
        s->extent = getSPX(*m);                  // Extent of new spona
        freeMemory(m, a);                        // Free old Spona
        S = getSP(m);                           
       }
     } 

// Return object number

    
    return n;
   }

// No spare object number available

  return 0;
  croak("Spona is allocated and empty which is unusual because the empty Spona is removed above");
 }

/*
#######################################################################
# String
#######################################################################
*/

/*
-----------------------------------------------------------------------
Get string from object number
-----------------------------------------------------------------------
*/

String *addressString(M **m, UL o)
 {
  if (getObjectType(m, o) != ObjectTypeString)
   {croak("Object %u is not a string", o);
   }
  String *s = am(*m, getObjectOffset(m, o));

  
  return s;
 }

/*
-----------------------------------------------------------------------
Create a string object

l - length of the string
s - contents of the string

Returns the object number of the created string.
-----------------------------------------------------------------------
*/

UL allocString(M **m, char *s, UL l)
 {

  UL o = allocObject2(m, l+sizeof(struct String));  // Allocate large enough object
  String *p = am(*m, getObjectOffset(m, o));     // Pointer to object - its not a string yet so cannot call getString   
                                                
  p->o.type = ObjectTypeString;                  // Set type = string
  p->length = l;                                 // Set length
  memcpy(&(p->array[0]), s, l);                  // Set string

  
  return o;
 }

/*
-----------------------------------------------------------------------
Recreate a string

o - object number of existing string this string will replace
l - length of the new string
s - contents of the new string

Change the string contents of a string object, either by reusing the
existing space, or by allocating new memory and fixing everything so
that the new memory replaces the old memory as the storage for this
string. The string retains its existing object number and reference
count.
-----------------------------------------------------------------------
*/

void reallocString(M **m, UL o, char *s, UL l)
 {

// Reuse old memory if the string will use the same size

  if (bits(l+sizeof(struct String)) == getAllocLength(*m, getObjectOffset(m, o)))       
   {String *S = addressString(m, o);
    memcpy(S->array, s, l);
    
    return;
   }

// Allocate new memory

  reallocObject2(m, o, l+sizeof(struct String), 0);  // Extend/Contract existing object
  String *P = addressString(m, o);                   // Pointer to object  #12 
                                               
  P->length = l;                                 // Set length
  memcpy(P->array, s, l);                        // Set string

  
 }

/*
-----------------------------------------------------------------------
Delete a string object
-----------------------------------------------------------------------
*/

void freeString(M **m, UL s)
 {

  addressString(m, s);                           // Check object is a string
  freeObject(m, s);                              // Free string

  
 }

/*
#######################################################################
# Array
#######################################################################
*/

/*
-----------------------------------------------------------------------
Get array from object number
-----------------------------------------------------------------------
*/

Array *addressArray(M **m, UL o)
 {

  if (debugMemory)
   {if (getObjectType(m, o) != ObjectTypeArray)
     {croak("Object %u is not an array", o);
     }
   }

  Array *A = am(*m, getObjectOffset(m, o));

  
  return A;
 }

/*
-----------------------------------------------------------------------
Save blessing string stored in HashST as object o in this array
-----------------------------------------------------------------------
*/

void saveArrayBless(M **m, UL o, UL b)
 {

  Array *A = addressArray(m, o);
  UL     B = A->blessed;

  if (B)                                         // Object was blessed
   {decReferenceCount(m, B);
    saveLog3(ActionSaveArrayRBless, m, o, B);
   }
  else                                           // First bless
   {saveLog2(ActionSaveArrayFBless, m, o);
   }

  if (b > 0) {incReferenceCount(m, b);}          // Reference count for blessing string 
  A->blessed = b; 

  
 }

/*
-----------------------------------------------------------------------
Get array size using known address of array
-----------------------------------------------------------------------
*/

UL getArraySizeFromAddress(Array *a)
 {return a->h - a->l;
 }

/*
-----------------------------------------------------------------------
Get array size - scalar(array)
-----------------------------------------------------------------------
*/

UL getArraySize(M **m, UL o)
 {Array *a = addressArray(m, o);
  return getArraySizeFromAddress(a);
 }

/*
-----------------------------------------------------------------------
Get minimum array size for a given array
-----------------------------------------------------------------------
*/

UL getMinimumArraySize(Array *A)
 {return sizeof(struct Array) + (A->h - A->l) * sizeof(MU);
 }

/*
-----------------------------------------------------------------------
Get minimum array size - minimum amount of storage required to hold
an array with n elements
-----------------------------------------------------------------------
*/

UL getMinimumArraySizeToHold(UL n)
 {return sizeof(struct Array) + n * sizeof(MU);
 }

/*
-----------------------------------------------------------------------
Return maximum index for an array
-----------------------------------------------------------------------
*/

long arrayMax(M **m, UL o)
 {UL l = getAllocLength(*m,  getObject(m, o));   // log2(size of allocation)    
  UL L = 1<<l;                                   // Size of allocation
     L -= sizeof(struct Array);                  // Minus header
     L /= sizeof(MU);                            // Divided by array element size
  return L-1;                                    // Minus one as we are zero based gives maximum possible index 
 }

/*
-----------------------------------------------------------------------
Return log2(Size of block needed to hold array with index i)
-----------------------------------------------------------------------
*/

UL arrayBits(UL i)
 {return bits(getMinimumArraySizeToHold(i));
 }

/*
-----------------------------------------------------------------------
Create an array object
-----------------------------------------------------------------------
*/

UL allocArray(M **m)
 {
  UL d = 3;                                      // Default size - uses 32 bytes in 32bit Memory Model    
  UL s = sizeof(struct Array) + d * sizeof(MU);  // Actual size
  UL n = allocObject2(m, s);                     // Allocate
  UL p = getObjectOffset(m, n);                  // Offset of object
  O *o = am(*m, p);                              // Address object 
  o->type = ObjectTypeArray;                     // Set type = array

  Array *A = addressArray(m, n);                 // Address array 
  A->l      = 0;                                 // Set low bound    
  A->h      = 0;                                 // Set high bound

  
  return n;
 }

/*
-----------------------------------------------------------------------
Create global array
-----------------------------------------------------------------------
*/

UL allocGlobalArray(M **m)
 {

  if ((*m)->GAH == 0)                            // Nothing global allocated already
   {UL A = allocArray(m);                        // Allocate array
    (*m)->GAH = A;                               // Save object number
    return A;                                    // Return array
   }

  UL t = getObjectType(m, (*m)->GAH);            // Type of global object
  if (getObjectType(m, (*m)->GAH) == ObjectTypeArray)
   {return (*m)->GAH;                            // Return existing array
   }

  if (t == ObjectTypeHash)
   {croak("Global object already allocated and it is a hash, not an array");
   }

  croak("Global object already allocated and it is type %u, not an array", t);
 }

/*
------------------------------------------------------------------------
Free an array object.

This routine is called by freeObject. A user should call freeArray()
because it will check that the object to be deleted is in fact an array.
------------------------------------------------------------------------
*/

void freeArrayObject(M **m, UL a)
 {

  Array *A = addressArray(m, a);                 // Address array
   {UL i;
    for(i = A->l; i < A->h; ++i)                 // Each array element 
     {UL e = A->array[i];
      if (e == 0) {continue;}                    // Ignore undefined entries
      decReferenceCount(m, e);                   // Decrement reference count on freed object
      A = addressArray(m, a);                    // Readdress array as it may have moved
     } 
   }

  
 }

/*
-----------------------------------------------------------------------
Free an array object.
-----------------------------------------------------------------------
*/

void freeArray(M **m, UL a)
 {

  if (a == (*m)->GAH)                            // Check GAH
   {croak("Cannot free array %u because it is the global array", a);
   }

  addressArray(m, a);                            // Check object is an array
  freeObject(m, a);                              // Free array

  
 }

/*
-----------------------------------------------------------------------
Check an array relative index: die if bad, otherwise return absolute
index in array
-----------------------------------------------------------------------
*/

UL checkArrayIndex(Array *A, long i)
 {

  long I;
  if (i < 0)                                     // Index from top if negative
   {I = A->h + i;
   }
  else
   {I = A->l + i;                                // Index from base if positive
   }

  if (I < A->l)                                  // Check bounds
   {croak("Index %u is before start of array", i);
   }

  
  return I;                                      // Return object number
 }

/*
-----------------------------------------------------------------------
Get an array element at index i in array a
-----------------------------------------------------------------------
*/

UL getArray(M **m, UL a, long i)
 {

  Array *A = addressArray(m, a);                  // Address array
  UL I = checkArrayIndex(A, i);

  if (I >= A->h)                                  // Undef if not defined
   {
    return 0;
   }

  UL e = A->array[I];                             // Get array element
  (*m)->lastArrayElement = e;                     // Save for testing
  
  return e;                                       // Return object number
 }

/*
-----------------------------------------------------------------------
Copy an array from a to b in a new block of size l during reallocObject.

The array low bound will be reset to zero during the process.

This function will complain if data is lost: make sure that you remove
any elements that you do not want copied before this routine gets called.
-----------------------------------------------------------------------
*/

void copyArray(M **m, UL a, UL b, UL l)
 {

  Array *A = am(*m, a);                          // Address array
  Array *B = am(*m, b);                          // Address array

  UL S = getArraySizeFromAddress(A);             // Size of array 
 
  UL L = 1<<l;                                   // Compute maximum size of new array                            
     L -= sizeof(struct Array);
     L -= L % sizeof(MU);
  UL s = L / sizeof(MU);                         // Maximum size of new array

  if (s < S)
   {croak("Target array %u is too small to receive data from %u", b, a);
   }

// Move data - memory will not be moved by this operation

  UL i; UL n = 0;

  for(i = A->l; i < A->h; ++i, ++n)
   {B->array[n] = A->array[i];
   }

// Set attributes

  B->l = 0; B->h = n;

  
 }

/*
-----------------------------------------------------------------------
Reallocate an array a to hold n elements
-----------------------------------------------------------------------
*/

void reallocArray(M **m, UL a, UL n)
 {
  UL L = getMinimumArraySizeToHold(n);           // New size
  reallocObject2(m, a, L, &copyArray);           // Copy data
  
 }
 
/*
-----------------------------------------------------------------------
Shrink an array if possible
-----------------------------------------------------------------------
*/

void shrinkArray(M **m, UL a)
 {
  Array *A = addressArray(m, a);

  UL l = arrayBits(getArraySize(m, a));          // log2(New size)
  UL k = getAllocLength(*m, getObject(m, a));    // log2(Current size)
  if (l < k)                                     // Shrinkable
   {reallocArray(m, a, getArraySize(m, a));      // Reallocate array
   }
  
 }
 
/*
-----------------------------------------------------------------------
Put an object into an array
-----------------------------------------------------------------------
*/

void putArray(M **m, UL a, long i, UL v)
 {

  Array *A = addressArray(m, a);                 // Address array
  UL I = checkArrayIndex(A, i);                  // Absolute index

//Cannot implement the following line because Perl fails to take advantage of this optimization documented in PE
//if (I >= A->h && v == 0)           {return;}   // Trying to set an undefined value to undefined
  if (I <  A->h && v == A->array[I]) {return;}   // Element is not being changed, so nothing is being done

  if (I < A->h)                                  // Remove old object
   {UL e = A->array[I];                          // Old referenced object
    if (e > 0)                                   // Remove old object if defined
     {decReferenceCount(m, e);                   // Reduce reference count for old object
     }
    saveLog4(ActionPutArray, m, a, i, e);        // Log old value
   }
  else
   {if (I > arrayMax(m, a))                      // Expand allocation if necessary
     {reallocArray(m, a, I - A->l + 1);          // Expand array to at least the size required to hold this actual index
     } 
    UL n = getArraySize(m, a);                   // Old array size
    saveLog3(ActionSetArraySize, m, a, n);       // Changing array size only
   }

  A = addressArray(m, a);                        // Address array
  I = checkArrayIndex(A, i);                     // Absolute index
  A->array[I] = v;                               // Set reference to new object
  if (I >= A->h) {A->h = I+1;}                   // Increase high bound
  if (v > 0) {incReferenceCount(m, v);}          // Increase reference count for new object
  cleanUp(m);                                    // Clean up possible because no element is returned

  
 }

/*
-----------------------------------------------------------------------
Set an array element without reference counting or logging. This allows
an array to be used to store numbers rather than strings, which is used
during log processing to keep track of the users actions.
-----------------------------------------------------------------------
*/

void putArrayNanO(M **m, UL a, long i, UL v)
 {

  Array *A = addressArray(m, a);                 // Address array
  UL I = checkArrayIndex(A, i);                  // Absolute index

  if (I >= A->h)                                 // Extend array if necessary
   {if (I > arrayMax(m, a))                      // Expand allocation if necessary
     {reallocArray(m, a, I - A->l + 1);          // Expand array to at least the size required to hold this actual index
      A = addressArray(m, a);                    // Address new array
      I = checkArrayIndex(A, i);                 // Absolute index
     }
   }

  A->array[I] = v;                               // Set reference to new object

  if (I >= A->h) {A->h = I+1;}                   // Increase high bound

  
 }

/*
-----------------------------------------------------------------------
Set array size - implements STORESIZE
-----------------------------------------------------------------------
*/

void setArraySize(M **m, UL a, long i)
 {

  Array *A = addressArray(m, a);                 // Address array
  UL I = checkArrayIndex (A, i);                 // Absolute index

  if (I < A->h)                                  // Remove elements due to truncation
   {UL j;                                        // Set excluded elements to zero
    for(j = I; j < A->h; ++j)                    // Each element
     {if (A->array[j] > 0)                       // that is defined
       {putArray(m, a, j - A->l, 0);             // Set array element to undefined
        A = addressArray(m, a);                  // Readdress array
       }
     }
    UL n = getArraySize(m, a);                   // Old array size
    saveLog3(ActionSetArraySize, m, a, n);       // Log old array size
    A = addressArray(m, a);                      // Readdress array
    A->h = I;                                    // Set new array size
    shrinkArray(m, a);                           // Shrink array if possible
   } 
  else
   {putArray(m, a, I - A->l - 1, 0);             // Expand allocation by seeting the new top element to undef
   }                                             
  cleanUp(m);                                    // Clean up possible because no element is returned

  
 }

/*
-----------------------------------------------------------------------
Extend array
-----------------------------------------------------------------------
*/

void extendArray(M **m, UL a, long i)
 {

  Array *A = addressArray(m, a);                 // Address array
  UL I = checkArrayIndex(A, i);                  // Check index

  UL j = I - A->l;                               // Actual index
  if (j > arrayMax(m, a))                        // Extend array if necessary
   {UL n = arrayMax(m, a);                       // Old array maximum size
    saveLog3(ActionExtendArray, m, a, n);        // Log old maximum size
    reallocArray(m, a, j);                       // Extend array without changing the set upper bound
   }
  cleanUp(m);                                    // Clean up possible because no element is returned

  
 }
  
/*
-----------------------------------------------------------------------
Clear an array
-----------------------------------------------------------------------
*/

void clearArray(M **m, UL a)
 {

  Array *A = addressArray(m, a);                 // Address array
   {UL i;                                        // Lower reference count for freed elements
    for(i = A->l; i < A->h; ++i)
     {UL e = A->array[i];
      if (e > 0)
       {putArray(m, a, i - A->l, 0);             // undefine defined element
        A = addressArray(m, a);                  // Readdress array
       } 
     }
   } 

  saveLog3(ActionClearArray, m, a, getArraySizeFromAddress(A));  // Log old size
  A = addressArray(m, a);                        // Address array
  A->l = A->h = 0;                               // Reset bounds
  reallocArray(m, a, 0);                         // Reallocate array as small as possible
  cleanUp(m);                                    // Clean up possible because no element is returned

  
 }

/*
-----------------------------------------------------------------------
Push object number onto an array - logging is inherent in putArray()
-----------------------------------------------------------------------
*/

void pushArray(M **m, UL a, UL o)
 {

  Array *A = addressArray(m, a);                 // Address array
  putArray(m, a, A->h - A->l, o);                // Set top element of array
  
 }

/*
-----------------------------------------------------------------------
Pop an object number from an array
-----------------------------------------------------------------------
*/

UL popArray(M **m, UL a)
 {

  Array *A = addressArray(m, a);                 // Address array
  
  UL v = 0;                                      // Popped element
  if (A->l < A->h)                               // Elements available
   {v = A->array[--A->h];                        // Pop element
        A->array[  A->h] = 0;                    // Remove old element
    decReferenceCount(m, v);                     // Decrease reference count for removed object
    saveLog3(ActionPopArray, m, a, v);           // Log pop
    shrinkArray(m, a);                           // Shrink array of possible
   }

  
  return v;
 }

/*
-----------------------------------------------------------------------
Unshift value v onto an array a
-----------------------------------------------------------------------
*/

void unshiftArray(M **m, UL a, UL v)
 {
  saveLog2(ActionUnshiftArray, m, a);

  Array *A = addressArray(m, a);                 // Address array

  if (A->l > 0)                                  // Enough space already
   {A->array[--A->l] = v;                        // Save element and reduce lower bound
    incReferenceCount(m, v);                     // Increase reference count for insert object
    
    return;
   }

  UL s = 1;                                      // Shift for unshift
  if (A->h > arrayMax(m, a))                      
   {s = 8;                                       // Boost shift
    reallocArray(m, a, A->h + s);                // Make room for more elements
    A = addressArray(m, a);                      // Address array
   }

  long i;
  for(i = A->h-1; i >= (long)A->l; --i)
   {A->array[i+s] = A->array[i];                 // Shift
   }

  A->array[A->l + s - 1] = v;                    // Save current element
  incReferenceCount(m, v);                       // Increase reference count for insert object
  A->h += s;                                     // Increase upper bound
  A->l += s - 1;                                 // Increase lower bound 
  cleanUp(m);                                    // Clean up possible because no element is returned

  
 }

/*
-----------------------------------------------------------------------
Shift from an array a 
-----------------------------------------------------------------------
*/

UL shiftArray(M **m, UL a)
 {

  Array *A = addressArray(m, a);                 // Address array

  UL v = 0;                                      // Shifted element
  if (A->l < A->h)
   {v = A->array[A->l++];
    saveLog3(ActionShiftArray, m, a, v);         // Log value shifted 
    decReferenceCount(m, v);                     // Decrease reference count for removed object
   }

  
  return v;
 }

/*
-----------------------------------------------------------------------
Splice array a as described by entries in array d.  d[1] is th offset,
d[2] the length, and d[3 ...] the data items. n is the number of items
in d.
-----------------------------------------------------------------------

UL spliceArray(M **m, UL a, long n, UL *d)
 {
  
  UL b = allocArray(m);                          // Spliced array 
  UL r = allocArray(m);                          // Splice results  array 
  Array *A = addressArray(m, a);                 // Address splice  array
  Array *B = addressArray(m, b);                 // Address spliced array
  Array *R = addressArray(m, r);                 // Address results array

  UL S = A->h - A->l;                            // Size of splice array

  UL O = 0;                                      // Offset - default
  if n > 1) 
   {O = d[1];                                    // Offset 
    if (O < 0) {O += S;}                         // Negative offset
   }
  if (O < 0) {O  = 0;}                           // Too negative   
  if (O > S) {O  = S;}                           // Too positive
           
  UL L = S;                                      // Length - default
  if n > 2) 
   {L = d[2];                                    // Length 
    if (L < 0) {L += S - O;}                     // Negative length
   }
  if (L < 0)     {L = 0;}                        // Too negative   
  if (L > S - O) {L = S - O;}                    // Too positive
           
  O += A->l;                                     // Actual offset

   {UL i, j = 0;                                 // Copy each element up to offset       
    for(i = A->l; i < O; ++i, ++j)             
     {putArrayNanO(m, b, j, A->array[i]);
      A = addressArray(m, a);                    // Readdress splice  array
     }
   } 

   {UL i, j = 0, u = O + L;                      // Copy the spliced out elements
    for(i = O; i < u; ++i, ++j)                 
     {putArrayNanO(m, r, j, A->array[i]);
      A = addressArray(m, a);                    // Readdress splice  array
     }
   }

   {UL i, j = O, u = O;                          // Copy in splicing elements
    for(i = 3; i < n; ++i, ++j)                  
     {putArrayNanO(m, b, j, d[i]);
     }
   }

  A = addressArray(m, a);                        // Readdress splice  array
  B = addressArray(m, b);                        // Readdress spliced array
   {UL i, j = B->h, u = A->h;                    // Copy remaining elements
    for(i = O + L; i < n; ++i, ++j)              
     {putArrayNanO(m, b, j, A->array[i];
      A = addressArray(m, a);                    // Readdress splice  array
     }
   } 
           
  swapObject(m, a, b);                           // Makes the spliced array the splice array
  freeArray(m, a);                               // Free old array

  
  return r;
 }

/*
#######################################################################
# Hash
#######################################################################
*/

/*
-----------------------------------------------------------------------
Get hash from object number
-----------------------------------------------------------------------
*/

Hash *addressHash(M **m, UL o)
 {

  if (debugMemory)
   {if (getObjectType(m, o) != ObjectTypeHash)
     {croak("Object %u is not a hash", o);
     }

    if ((*m)->hashST == getObjectOffset(m, o))
     {croak("Please do not try to address the HashST, it is a system object");
     }
   }

  Hash *H = am(*m, getObjectOffset(m, o));

  
  return H;
 }

/*
-----------------------------------------------------------------------
Save blessing string stored in HashST as object o in this hash
-----------------------------------------------------------------------
*/

void saveHashBless(M **m, UL o, UL b)
 {

  Hash *H = addressHash(m, o);
  UL    B = H->blessed;

  if (B)                                         // Object was blessed
   {decReferenceCount(m, B);                             
    saveLog3(ActionSaveHashRBless, m, o, B);
   }
  else                                           // First bless
   {saveLog2(ActionSaveHashFBless, m, o);
   }

  if (b > 0) {incReferenceCount(m, b);}          // Reference count for blessing string                             
  H->blessed = b; 

  
 }

/*
-----------------------------------------------------------------------
Get number of elements in a hash
-----------------------------------------------------------------------
*/

UL getHashSize(M **m, UL H)
 {
  Hash *h = addressHash(m, H);
  UL n = h->count;

  
  return n;
 }

/*
-----------------------------------------------------------------------
Address hash key from object number
-----------------------------------------------------------------------
*/

HashKey *addressHashKey(M **m, UL o)
 {
  if (getObjectType(m, o) != ObjectTypeHashKey)
   {ddd(m);
    croak("Object %u is not a hashKey", o);
   }
  HashKey *k = am(*m, getObjectOffset(m, o));

  
  return k;
 }

/*
------------------------------------------------------------------------
Number of buckets that could be placed in the block at offset a
------------------------------------------------------------------------
*/

UL getHashBuckets(M **m, UL a)
 {
  UL l = getAllocLength(*m, a);
  UL n = ((1<<l) - sizeof(struct Hash)) / sizeof(struct HashElement);

  
  return n;
 }

/*
------------------------------------------------------------------------
Number of buckets that could be placed in the hash with object number h
------------------------------------------------------------------------
*/

UL getHashBucketsObject(M **m, UL h)
 {
  UL H = getObjectOffset(m, h);
  UL n = getHashBuckets(m, H);

  
  return n;
 }

/*
------------------------------------------------------------------------
Allocate a hash key and set it to string K with length L
------------------------------------------------------------------------
*/

UL allocHashKey(M **m, char *K, UL L)
 {
  UL o = allocObject2(m, sizeof(struct HashKey)+L); // Allocate object
  HashKey *s = am(*m, getObjectOffset(m, o));    // Address hash string
  s->length = L;                                 // Save length 
  memcpy(s->array, K, L);                        // Save string

  s->o.type = ObjectTypeHashKey;                 // Set type 
  
  return o;                                      // Return object
 }

/*
------------------------------------------------------------------------
Hash a string
------------------------------------------------------------------------
*/

UL hashString(char *s, UL L, UL B)
 {
  char *p = s;
  UL    i  = 0;
  UL    v  = 1;
  UL    v1 = 0;

  v = 1;
  for(i = 0; i < L; ++i, ++p)
   {memcpy((void *)&v1, (void *)(s+i), 1);
    v *= (1 + v1) * (1+i);
    v %= MMU;
    v++;
   }

  
  return v;
 }

/*
------------------------------------------------------------------------
Find a string k with length l in the Hash String Table and return its
object number, or MMU if not found
------------------------------------------------------------------------
*/

UL getHashST(M **m, char *K, UL L)
 {
  setUpHashST(m);                                // Set up Hash ST if not already done
  UL H = (*m)->hashST;                           // Address hash 
  UL B = (*m)->hashSTX;                          // Number of buckets
  UL k = hashString(K, L, B);                    // Hash input string  
  Hash *h = am(*m, H);                           // Address hash
  UL P = h->array[k % B].path;                   // Path length for this key in HST

  UL i; UL lppp = 0; UL fh = MMU; UL fhi;        // Last positive path position, first hole, first hole path length
  for(i = 0; i <= P; ++i)                        // Search along path
   {UL p = (k + i) % B;                          // Next position
    UL f = h->array[p].key;                      // Get key
    if (f == 0 && fh == MMU) {fh = p; fhi = i;}  // First hole, first hole path
    if (f > 0)
     {HashKey *s = addressHashKey(m, f);         // Address hash string
      if (s->length != L ||                      // Check length
          memcmp(K, s->array, L) != 0)           // Check contents
       {lppp = i;                                // Record last positive position  
        continue;                                // Continue if keys do not match
       } 
      if (fh == MMU)                             // No path tightening or shortening
       {
        return f;                                // Return HashKey
       }
      else                                       // Tighten path possible because this entry hash the same hash key as the entry point
       {h->array[fh].key  = h->array[p].key;  h->array[p].key  = 0; 
        h->array[fh].data = h->array[p].data; h->array[p].data = 0;
        if (i == P)                              // Tighten and shorten oath
         {UL npl = lppp;                         // New path length
          if (fhi > lppp) {npl = fhi;}           // If we are filling a hole beyond the last positive position, path must extend to the hole
          h->array[k % B].path = npl;            // Shorten path as we are the end
          
         }
        else                                     // Tighten path
         {
         }
        
        return h->array[fh].key;                 // Return object number of matching key
       }
     }
   }

  h->array[k % B].path = lppp;                   // Update path length as we are at the end of the path
  
  
  return MMU;
 }

/*
------------------------------------------------------------------------
Find a hash string in a hash. Return the bucket number in the hash if
found, else MMU.

Path tightening moves a hash entry closer to its point of entry if
possible. We can do this with find operations because the found bucket
must match the entry point hash.
------------------------------------------------------------------------
*/

UL findHashBucket(M **m, UL H, char *K, UL L)
 {
  Hash    *h = addressHash   (m, H);             // Address hash
  UL       k = getHashST(m, K, L);               // Find bucket containing string in HashST
  if (k == MMU)                                  // Key not in HashST, so cannot be in hash
   {
    return MMU;
   }
  UL O = getObjectOffset(m, H);                  // Object offset
  UL B = getHashBuckets (m, O);                  // Number of buckets
  if (B == 0)                                    // No keys in hash so cannot be found        
   {
    return MMU;
   }
  UL P = h->array[k % B].path;                   // Path length for this key
  

  UL i; UL lppp = 0; UL fh = MMU; UL fhi;        // Last positive position, First hole, first hole path
  for(i = 0; i <= P; ++i)                        // Search along path
   {UL p = (k + i) % B;                          // Next position
    UL f = h->array[p].key;                      // Get key
    if (f == 0 && fh == MMU) {fh = p; fhi = i;}  // First hole, first hole path
    if (f == k)                                  // Key matches
     {if (fh == MMU)                             // No path tightening or shortening
       {
        return p;                                // return bucket - it was not moved 
       }
      else                                       // Tighten path possible because this entry hash the same hash key as the entry point
       {h->array[fh].key  = h->array[p].key;  h->array[p].key  = 0; 
        h->array[fh].data = h->array[p].data; h->array[p].data = 0;
        if (i == P)                              // Tighten and shorten oath
         {UL npl = lppp;                         // New path length
          if (fhi > lppp) {npl = fhi;}           // If we are filling a hole beyond the last positive position, path must extend to the hole
          h->array[k % B].path = npl;            // Shorten path as we are the end
          
         }
        else                                     // Tighten path
         {
         }
        
        return fh;                               // Return number of bucket containing key
       }
     }
    if (f > 0) {lppp = i;}                       // Record last positive path position
   }

  h->array[k % B].path = lppp;                   // Update path length as we are at the end of the path
 
  
  return MMU;
 }

/*
------------------------------------------------------------------------
Find data in hash. Return the data object associated with the key or
undefined = 0 if not found.
------------------------------------------------------------------------
*/

UL getHash(M **m, UL H, char *K, UL L)
 {

  UL b = findHashBucket(m, H, K, L);             // Find bucket
  if (b == MMU)                                  // Key not found
   {
    return (*m)->lastFoundHashElement = 0;       // Save for testing
   }
  
  Hash *h = addressHash(m, H);                   // Address hash
  UL D = h->array[b].data;                       // Get data object from bucket
  (*m)->lastFoundHashElement = D;                // Save for testing

  
  return D;
 }

/*
------------------------------------------------------------------------
See whether a key exists in hash H
------------------------------------------------------------------------
*/

UL inHash(M **m, UL H, char *K, UL L)
 {

  UL b = findHashBucket(m, H, K, L);             // Find bucket
  UL r = b != MMU;                               // Key exists if not undefined
  
  return r;
 }

/*
------------------------------------------------------------------------
Free hash key in HashST
------------------------------------------------------------------------
*/

void freeHashSTKey(M **m, UL n)
 {
  HashKey *K = addressHashKey(m, n);             // Address hash key
  UL H = (*m)->hashST;                           // Address hash 
  UL B = (*m)->hashSTX;                          // Number of buckets
  UL k = hashString(K->array, K->length, B);     // Hash String 
  Hash *h = am(*m, H);                           // Address hash
  UL P = h->array[k % B].path;                   // Path length for this key in HST

  UL i; UL lppp = 0;                             // Last positive path position  
  for(i = 0; i <= P; ++i)                        // Search along path
   {UL p = (k + i) % B;                          // Next position
    UL f = h->array[p].key;                      // Get key
    if (f > 0)
     {if (f == n)                                // Found hash key
       {h->array[p].key  = 0;                    // Zero hash key
        h->array[p].data = 0;                    // Zero hash in data field
        h->count--;                              // Reduce count
        if (i == P)
         {h->array[k % B].path = lppp;           // Update path if we are at the end of it 
          
         }
        else
         {
         }
        if (h->count < B / 4) {shrinkHashST(m);} // Shrink HashST if possible
        
        return;    
       }
      lppp = i;                                  // Record last positive position  
     }
   }

  h->array[k % B].path = lppp;                   // Update path length as we are at the end of the path
  
  croak("NOT found hashKey %u with hash %u pathLength=%u in HashST, set pathlength of %u to %u", n, k, P, k % B, lppp);
 }

/*
------------------------------------------------------------------------
Delete a hash key from a hash. Return the data field associated with the
field.

NOTE: To set an element in Hash H with key K, length L to the undefined
value:

  putHash(m, H, K, L, 0)

deleteHashKey() removes the hash key from the hash completely.
------------------------------------------------------------------------
*/

UL deleteHashKeyByIndex(M **m, UL H, UL k)
 {

  Hash *h = addressHash   (m, H);                // Address hash
  UL    B = getHashBuckets(m, getObjectOffset(m, H)); // Number of buckets
  UL    P = h->array[k % B].path;                // Path length for this key

  UL i; UL lppp = 0;                             // Last positive path position
  for(i = 0; i <= P; ++i)                        // Search along path
   {UL p = (k + i) % B;                          // Next position
    UL f = h->array[p].key;                      // Get key
    if (f == k)                                  // Key matches
     {decReferenceCount(m, f);                   // Decrement reference count of hash key                                                  
      h = addressHash(m, H);                     // Readdress hash
      h->array[p].key  = 0;                      // Zero hash key
      UL D = h->array[p].data;                   // Save data field
             h->array[p].data = 0;               // Zero data field
      if (D > 0)                                 // Decrement reference count of data
       {decReferenceCount(m, D);                                                  
        h = addressHash(m, H);                   // Readdress hash
       }
      h->count--;                                // Reduce count
      if (i == P)
       {h->array[k % B].path = lppp;             // Update path if we are at the end of it 
        
       }
      else
       {
       }
     (*m)->lastFoundHashElement = D;             // Show for testing
      if (h->count < B / 4) {shrinkHash(m, H);}  // Shrink Hash if possible
      
      return D;                                  // Return data field
     }
    if (f > 0) {lppp = i;}                       // Record last positive path position
   }

  h->array[k % B].path = lppp;                   // Update path length as we are at the end of the path
 
  
  return 0;
 }

/*
------------------------------------------------------------------------
Delete a hash key from a hash. Return the data field associated with the
field.
------------------------------------------------------------------------
*/

UL deleteHashKey(M **m, UL H, char *K, UL L)
 {
  UL       k = getHashST(m, K, L);               // Find bucket containing string in HashST
  if (k == MMU)                                  // Key not in HashST
   {return 0;                                    //   so cannot be in hash
   }
  UL d = deleteHashKeyByIndex(m, H, k);          // Delete hash key entry using index
  if (d > 0)                                     // Log delete of key with defined value
   {saveLog4(ActionDeleteDHash, m, H, k, d);     // Log action
   }
  else                                           // Log delete of key with undefined value
   {saveLog3(ActionDeleteUHash, m, H, k);        // Log action
   }
  return d;
 } 

/*
-----------------------------------------------------------------------
Copy HashST from a to b in a new block of size l during reallocObject.
We can assume that the keys to the hash are uniue as they are coming
from another hash.
-----------------------------------------------------------------------
*/

void copyHashST(M **m, UL a, UL b, UL l)
 {

  Hash *A = am(*m, a);                           // Address old HashST 
  Hash *B = am(*m, b);                           // Address new HashST
  UL   nA = getHashBuckets(m, a);                // Number of buckets
  UL   nB = getHashBuckets(m, b);                // Number of buckets
  B->maxPath = 0;                                // Clear maximum path length

// Move data - memory will not be moved by this operation because there are no decrements

  UL i; 
  for(i = 0; i < nA; ++i)
   {if (A->array[i].key == 0) {continue;}        // Skip empty buckets
    UL h = A->array[i].data;                     // Hash of string
    
// Search for first empty position

    UL j;
    for(j = 0; j < nB; ++j)                      // Search 
     {UL p = (h + j) % nB;                       // Position
      UL f = B->array[p].key;                    // Get key
      if (f == 0)                                // Found empty slot
       {B->array[p].key  = A->array[i].key;      // Save key	
        B->array[p].data = A->array[i].data;     // Save data
        UL P = B->array[h % nB].path;            // Current path length
        if (j > P)
         {UL P = B->array[h % nB].path = j;      // Update path length
          if (B->maxPath < P) {B->maxPath = P;}  // Maximum path length
         }
        break;
       }
     } 
   }

// Set attributes

  B->count = A->count;

  
 }

/*
------------------------------------------------------------------------
Allocate hash and return its object number
------------------------------------------------------------------------
*/

UL allocHash(M **m)
 {

  UL L = sizeof(struct Hash) + 3 * sizeof(struct HashElement); // Default size fills 64 bytes in 32bit memory model
  UL H = allocObject2(m, L);                     // Allocate object
  Hash *h     = am(*m, getObjectOffset(m, H));   // Address object
  h->o.type   = ObjectTypeHash;                  // Set type
  h->count    = 0;                               // Clear count
  h->maxPath  = 0;                               // Clear maximum path
  h->iterator = MMU;                             // Clear iterator 

  
  return H;
 }

/*
-----------------------------------------------------------------------
Create global hash
-----------------------------------------------------------------------
*/

UL allocGlobalHash(M **m)
 {

  if ((*m)->GAH == 0)                            // Nothing global allocated already
   {UL H = allocHash(m);                         // Allocate hash
    (*m)->GAH = H;                               // Save object number
    return H;                                    // Return hash
   }

  UL t = getObjectType(m, (*m)->GAH);            // Type of global object
  if (getObjectType(m, (*m)->GAH) == ObjectTypeHash)
   {return (*m)->GAH;                            // Return existing hash
   }

  if (t == ObjectTypeArray)
   {croak("Global object already allocated and it is an array, not a hash");
   }

  croak("Global object already allocated and it is type %u, not a hash", t);
 }

/*
-----------------------------------------------------------------------
Free a hash object

h = object number of hash to be freed

This routine will be called by freeObject to lower the reference counts
the hash elements. The actual free of memory is done in freeObject.

The HashST should not be freed in this manner.

A user should call freeHash() as it checks that the obejct to be
deleted is in fact a hash.
-----------------------------------------------------------------------
*/

void freeHashObject(M **m, UL h)
 {

  UL B = getHashBuckets(m, getObject(m, h));     // Buckets in hash

// Save Hash contents

  UL c = getAllocLength(*m, getObject(m, h));    // Log2(size of block containing array)
  Hash *s = malloc(1<<c);
  if (s == 0)
   {croak("Malloc failed to allocate 2**%u bytes", s);
   }
  memcpy(s, addressHash(m, h), 1<<c);            // Copy hash contents as hash will move as objects are freed


   {UL i;
    for(i = 0; i < B; ++i)                       // Each bucket
     {UL k = s->array[i].key;                    // Get key
      if (k == 0) {continue;}                    // Skip if zero
      decReferenceCount(m, k);                   // Otherwise decrement reference count
      UL d = s->array[i].data;                   // Get data
      if (d == 0) {continue;}                    // Skip if zero 
      decReferenceCount(m, d);                   // Otherwise decrement reference count 
     } 
   }

  
 }

/*
-----------------------------------------------------------------------
Delete a hash object
-----------------------------------------------------------------------
*/

void freeHash(M **m, UL h)
 {

  if (h == (*m)->GAH)                            // Check GAH
   {croak("Cannot free hash %u because it is the global hash", h);
   }

  addressHash(m, h);                             // Check it is a hash
  freeObject(m, h);                              // Free the hash

  
 }

/*
------------------------------------------------------------------------
Allocate hash string table.
------------------------------------------------------------------------
*/

UL allocHashST(M **m)
 {

  UL H = allocHash(m);                           // Allocate hash 

  UL h = (*m)->hashST = getObjectOffset(m, H);   // Save offset to new HashST
  (*m)->hashSTX       = getHashBuckets (m, h);   // Save extent of new HashST

  
  return H;
 }


/*
------------------------------------------------------------------------
Reallocate hash string table.
------------------------------------------------------------------------
*/

void reallocHashST(M **m)
 {

  UL P = (*m)->hashST;                           // Old HashST
  UL l = getAllocLength (*m, P);                 // Block size of OLD HashST 
  UL o = getObjectNumber(*m, P);                 // Object number of OLD HashST
  reallocObject2(m, o, 1<<(l+1), &copyHashST);   // Allocate new block of twice the size

  UL O = (*m)->hashST  = getObjectOffset(m, o);  // Save offset to new HashST
  (*m)->hashSTX = getHashBuckets (m, O);         // Save extent of new HashST

  
 }

/*
-----------------------------------------------------------------------
Copy Hash from a to b in a new block of size l during reallocObject().
-----------------------------------------------------------------------
*/

void copyHash(M **m, UL a, UL b, UL l)
 {

  Hash *A = am(*m, a);                           // Address old HashST 
  Hash *B = am(*m, b);                           // Address new HashST
  UL   nA = getHashBuckets(m, a);                // Number of buckets in a
  UL   nB = getHashBuckets(m, b);                // Number of buckets in b
  B->iterator = A->iterator;                     // Iteration state, but I think should always be -1
  B->maxPath  = 0;                               // Clear maximum path length 
  B->count    = 0;                               // Clear maximum path length 

// Move data - memory will not be moved by this operation as there are no decrements

  UL i; 
  for(i = 0; i < nA; ++i)
   {UL k = A->array[i].key;                      // Object number of hash key
    if (k == 0) {continue;}                      // Skip empty buckets 

// Search 

    UL j;
    for(j = 0; j < nB; ++j)                      // Search along path
     {UL p = (k + j) % nB;                       // Position
      UL f = B->array[p].key;                    // Get key
      if (f == 0)                                // Found empty slot
       {B->array[p].key  = A->array[i].key;      // Save key	
        B->array[p].data = A->array[i].data;     // Save data
        UL P = B->array[k % nB].path;            // Current path length
        if (j > P)
         {UL P = B->array[k % nB].path = j;      // Update path length
          if (B->maxPath < P) {B->maxPath = P;}  // Maximum path length
         }
        ++(B->count);
        break;
       }
     } 
   }

  
 }

/*
------------------------------------------------------------------------
Reallocate hash 
------------------------------------------------------------------------
*/

void expandHash(M **m, UL P)
 {

  UL l = getAllocLength(*m, getObjectOffset(m, P));  // Block size of Hash 
  reallocObject2(m, P, 1<<(l+1), &copyHash);     // Allocate new block of twice the size

  
 }

/*
------------------------------------------------------------------------
Check if hash should be expanded. The computation of the maximum
tolerable path is biased at the moment for memory model 0.
------------------------------------------------------------------------
*/

UL shouldExpandHash(M **m, UL H)
 {

  Hash *h = am(*m, H);                           // Address hash

  UL l = h->o.MAC + 1;                           // Log2(allocation size)
     l /= 2;                                     // square root rounded up due to previous line

  if (h->maxPath > (1<<l))                       // Maximum path length is too long 
   {
    return 1;
   }

  
  return 0;                                      // Does not need realloc
 }

/*
------------------------------------------------------------------------
See if a hash with offset o needs shrinking
------------------------------------------------------------------------
*/

UL shouldShrinkHash(M **m, UL o)
 {

  UL H  = getObjectNumber(*m, o);                // Get Object Number of Hash
  UL l  = getAllocLength (*m, o);                // log2(allocation size)
//if (l <= MemoryMinimumSize)
// {rETURN "Hash %u is too small to shrink", H
//  return 0;
// }
  UL l2 = l / 2;                                 // sqrt log2(allocation size)
  UL B  = getHashBuckets ( m, o);                // Buckets
  UL B2 = B  / 2;                                // Buckets / 2
  UL B4 = B2 / 2;                                // Buckets / 4
  UL B8 = B4 / 2;                                // Buckets / 8
  Hash *h = am(*m, o);                           // Address hash
  UL M  = h->maxPath;                            // Maximum path
  UL C  = h->count;                              // Count
  UL r  = 0;                                     // Result 
          
  if      (B4 > C && M < (1<<l2-1)) {r = 1;}     // Less than 1/4 full and maximum path length is short
  else if (B8 > C)                  {r = 1;}     // Less than 1/8 full
  else if (B2 > C && M > C)         {r = 1;}     // Less than 1/2 full and very long max path

  
  return r;
 }

/*
------------------------------------------------------------------------
Make HashST smaller if possible
------------------------------------------------------------------------
*/

void shrinkHashST(M **m)
 {

  UL O = (*m)->hashST;                           // HashST offset
  UL H = getObjectNumber(*m, O);                 // Get Object Number of HashST

  if (shouldShrinkHash  (m, O))                  // Needs shrinking
   {UL l = getAllocLength(*m, O);                // Block size of Hash 
    reallocObject2(m, H, 1<<(l-1), &copyHashST); // Allocate new block half the size

    UL O = (*m)->hashST = getObjectOffset(m, H); // Save offset to new HashST
    (*m)->hashSTX = getHashBuckets(m, O);        // Save extent of new HashST
    
    return;
   }

  
 }

/*
------------------------------------------------------------------------
Make a hash smaller if possible
------------------------------------------------------------------------
*/

void shrinkHash(M **m, UL H)
 {

  Hash *h = addressHash(m, H);                   // Address hash
  if (h->iterator < MMU) {return;}               // Not allowed during scan     
  UL O = getObjectOffset(m, H);                  // Hash Offset

  if (shouldShrinkHash  (m, O))                  // Needs shrinking
   {UL l = getAllocLength(*m, O);                // Block size of Hash 
    reallocObject2(m, H, 1<<(l-1), &copyHash);   // Allocate new block half the size
    
    return;
   }

  
 }

/*
------------------------------------------------------------------------
Set up Hash String table if not present
------------------------------------------------------------------------
*/

void setUpHashST(M **m)
 {if ((*m)->hashST == MMU) {allocHashST(m);}     // Allocate hash string table if not already allocated
 }

/*
------------------------------------------------------------------------
Save string K with length L in Hash String Table and return object
number of hash string object.
------------------------------------------------------------------------
*/

UL saveStringInHashST(M **m, char *K, UL L)
 {

  setUpHashST(m);

// Save string in Hash String Table

  UL i;
  for(i = 0; i < bMU; ++i)                       // Let HashST grow if necessary 
   {UL B = (*m)->hashSTX;                        // Buckets in HashST
    if (B == 0 || shouldExpandHash(m, (*m)->hashST)) // Increase size of HashST if necessary
     {reallocHashST(m);
      continue;
     }
    UL k = hashString(K, L, B);                  // Hash string
    Hash *h = am(*m, (*m)->hashST);              // Address Hash
    UL P = h->array[k % B].path;                 // Path length

// Search - in path - return index of matching entry if possible

    UL fp = MMU;                                 // First empty position              
    UL j;
    for(j = 0; j <= P; ++j)                      // Search along path
     {UL p = (k + j) % B;                        // Position
      UL f = h->array[p].key;                    // Get key
      if (f > 0)
       {HashKey *s = addressHashKey(m, f);       // Address hash string
        if (s->length != L ||                    // Check length
            memcmp(K, s->array, L) != 0)         // Check contents
         {continue;                              // Continue if keys do not match
         } 
        
        return f;                                // Return object number of matching key
       }
      else
       {if (fp == MMU) {fp = p;}                 // Save first empty position  
       }
     } 

// New entry within path

    if (fp < MMU)
     {UL s = allocHashKey(m, K, L);              // Save hash string
      Hash *h = am(*m, (*m)->hashST);            // Address Hash
      h->array[fp].key  = s;                     // Save object number of hash string
      h->array[fp].data = k;                     // Save hash of string
      h->count++;                                // Update in use count
      h->iterator = MMU;                         // Stop any further iteration
      
      return s;
     } 

// Extend path

    for(j = 0; j < B; ++j)                       // Search along path
     {UL Pj1 = P+j+1;                            // Position
      UL p = (k+Pj1) % B;                        // Position
      if (h->array[p].key > 0) {continue;};      // Find empty bucket 
      UL s = allocHashKey(m, K, L);              // Save hash string
      Hash *h = am(*m, (*m)->hashST);            // Address Hash
      h->array[p].key  = s;                      // Save object number of hash string in hash key
      h->array[p].data = k;                      // Save hash of string
      h->count++;                                // Update in use count
      h->iterator = MMU;                         // Stop any further iteration
      h->array[k % B].path = Pj1;                // Update path length
      if (h->maxPath <= Pj1) {h->maxPath = Pj1;} // Maximum path length
      
      return s;
     }

    reallocHashST(m);                            // Reallocate hash and try again 
   } 

// Failed
     
  croak("Cannot save %s in HashST", K);
 }

/*
------------------------------------------------------------------------
Save data D in hash H under key K wih length l
------------------------------------------------------------------------
*/

void putHashByIndex(M **m, UL H, UL k, UL D)
 {

  UL i;
  for(i = 0; i < bMU; ++i)                       // Let Hash grow if necessary 
   {Hash *h = addressHash(m, H);                 // Address hash
    UL o = getObjectOffset(m, H);                // Offset of hash
    UL B = getHashBuckets(m, o);                 // Buckets in Hash
    if (B == 0 || shouldExpandHash(m, o))        // Increase size of Hash if necessary
     {expandHash(m, H);             
      continue;
     }
    UL P = h->array[k % B].path;                 // Path length

// Search in path

    UL fp = MMU;                                 // First empty position              
    UL j;
    for(j = 0; j <= P; ++j)                      // Search along path
     {UL p = (k + j) % B;                        // Position
      UL f = h->array[p].key;                    // Get key
      if (f > 0)
       {if (f == k)                              // Check keys match
         {UL d = h->array[p].data;               // Old referenced object

          if (d == D) {return;}                  // Data is the same - no action required

          if (d > 0)                             // Decrement old object reference if not undefined
           {decReferenceCount(m, d);                                                       
            h = addressHash(m, H);               // Readdress hash
            saveLog4(ActionPutRDHash, m, H, k, d);  // Log action 
           }                                                                                             
          else
           {saveLog3(ActionPutRUHash, m, H, k);  // Log action
           }
          h->array[p].data = D;                  // Set new object reference
          if (D > 0) {incReferenceCount(m, D);}  // Increment reference count of saved data if not undefined

          
          return;                              
         }
       }
      else
       {if (fp == MMU) {fp = p;}                 // Save first empty position  
       }
     } 

// New entry within path

    if (fp < MMU)
     {h->array[fp].key  = k;                     // Save object number of hash string in hash key
      h->array[fp].data = D;                     // Save object number of hash string in hash key
      incReferenceCount(m, k);                   // Update reference count 
      if (D > 0) {incReferenceCount(m, D);}      // Increment reference count of saved data if not undefined
      h->count++;                                // Update in use count
      h->iterator = MMU;                         // Stop any further iteration
      saveLog3(ActionPutIHash, m, H, k);         // Log action
      
      return;     
     } 

// Extend path

    for(j = 0; j < B; ++j)                       // Search along path
     {UL Pj1 = P+j+1;                            // Position
      UL p = (k + Pj1) % B;                      // Position
      if (h->array[p].key > 0) {continue;};      // Find empty bucket 
      h->array[p].key  = k;                      // Save object number of hash string in hash key
      h->array[p].data = D;                      // Save object number of hash string in hash key
      incReferenceCount(m, k);                   // Update reference count 
      if (D > 0) {incReferenceCount(m, D);}      // Increment reference count of saved data if not undefined
      h->count++;                                // Update in use count
      h->iterator = MMU;                         // Stop any further iteration
      h->array[k % B].path = Pj1;                // Update path length
      if (h->maxPath <= Pj1) {h->maxPath = Pj1;} // Maximum path length
      saveLog3(ActionPutIHash, m, H, k);         // Log action
      
      return;   
     }

    expandHash(m, H);                            // Reallocate hash and try again 
   } 

// Failed
     
  croak("Cannot save data %u under key %u in Hash %u", D, k, H);
 }

/*
------------------------------------------------------------------------
Save data in Hash and return number of hashKey used to store data 
------------------------------------------------------------------------
*/

UL putHash(M **m, UL H, char *K, UL L, UL D)
 {

  UL k = saveStringInHashST(m, K, L);            // Save string in HashST
  putHashByIndex(m, H, k, D);                    // Put into hash
  cleanUp(m);                                    // Clean up possible because no element is returned
  
  return k;
 }  

/*
-----------------------------------------------------------------------
Get minimum hash size - mminimum amount of storage required to hold
a hashn eith number of elements n
-----------------------------------------------------------------------
*/

UL getMinimumHashSize(UL n)
 {return sizeof(struct Hash) + n * sizeof(struct HashElement) - sizeof(struct O);
 }
  
/*
-----------------------------------------------------------------------
Clear a hash
-----------------------------------------------------------------------
*/

void clearHash(M **m, UL h)
 {

  Hash *H = addressHash(m, h);                   // Address hash
  UL    B = getHashBucketsObject(m, h);          // Get buckets

   {UL i;                                        // Lower reference count for freed elements
    for(i = 0; i < B; ++i)
     {UL k = H->array[i].key;                    // Get key
             H->array[i].key = 0;                // Zero key
      UL d = H->array[i].data;                   // Get data
             H->array[i].data = 0;               // Zero data
      if (k > 0)                                 // Decerment refence count of referenced hash key
       {decReferenceCount(m, k);                 // Reduce reference count of hash key
        if (d > 0)
         {saveLog4(ActionDeleteDHash, m, h, k, d);  // Log action
         }
        else
         {saveLog3(ActionDeleteUHash, m, h, k);  // Log action
         }
       }             
      if (d > 0) {decReferenceCount(m, d);}      // Reduce reference count of data
      Hash *N = addressHash(m, h);               // Readdress hash
      if (H != N)                                // If hash has moved 
       {B = getHashBucketsObject(m, h);          // Get buckets
        i = 0;                                   // Restart scan 
        H = N;                                   // Address new position of hash
       }
     }
   } 


  reallocObject(m, h, getMinimumHashSize(0), 0); // Reallocate object

  H = addressHash(m, h);                         // Readdress hash
  H->count = 0;                                  // Reset count
  H->iterator = MMU;                             // Reset iterator
  cleanUp(m);                                    // Clean up possible because no element is returned

  
 }
  
/*
-----------------------------------------------------------------------
Get bucket number of first element from a hash at the start os a scan.

If the hash changes size during scan the elements will be rehashed and
the iterator position will become confused. So I lock the hash in place
during scan so its size cannot change. Deletes are permitted as they do
not require more space. Inserts have two problesms: the hash will
eventually need to be resized and new elements may get inserted behind
or in front of the scan pointer, and thus may or may not appear in the
scan. To avoid these problems, an insert of a new key will signal the
completion of the scan, any attempt to call getHashNext() without
calling getHashFirst() first will cause an exit.

This approach is similar to Perl's, wherein the current element may be
deleted and the action of an insert is not specified.
-----------------------------------------------------------------------
*/

UL getHashFirst(M **m, UL h)
 {

  Hash *H = addressHash(m, h);                   // Address hash
  UL    B = getHashBucketsObject(m, h);          // Get buckets

   {UL i;                            
    for(i = 0; i < B; ++i)                       // Search for first key
     {UL k = H->array[i].key;                    // Get key
      if (k > 0)                                 // First key 
       {H->iterator = i;                         // Set iterator
        
        return 1;
       }
     }
   } 

// Empty hash because it contains no keys

  clearHash(m, h);                               // Clear hash

  
  return 0;                                      // No keys 
 }
  
/*
-----------------------------------------------------------------------
Get next element from a hash
-----------------------------------------------------------------------
*/

UL getHashNext(M **m, UL h)
 {

  Hash *H = addressHash(m, h);                   // Address hash
  UL    B = getHashBucketsObject(m, h);          // Get buckets
  long  i = H->iterator;                         // Iterated element

  if (i == MMU)                                  // No iterated element
   {croak("Scan has been terminated due to insertion of a new key in hash %u", h);
   }

   {UL i;                                        
    for(i = H->iterator+1; i < B; ++i)           // Search for next key
     {UL k = H->array[i].key;                    // Get key
      if (k > 0)                                 // Next key 
       {H->iterator = i;
        
        return 1;
       }
     }
   } 

  H->iterator = MMU;                             // Clear iterator 
  
  return 0;
 }
  
/*
-----------------------------------------------------------------------
Return 1 if we are scanning a hash, else 0
-----------------------------------------------------------------------
*/

UL scanHash(M **m, UL h)
 {

  Hash *H = addressHash(m, h);                   // Address hash

  UL r = H->iterator < MMU;                      // Is an iterated element available?

  
  return r;
 }
  
/*
-----------------------------------------------------------------------
Get hash key from iterator
-----------------------------------------------------------------------
*/

UL getKey(M **m, UL h)
 {

  Hash *H = addressHash(m, h);                   // Address hash

  if (H->iterator == MMU)                        // No iterated element
   {croak("no iterated element available for hash object %u", h);
   } 
   
  UL k = H->array[H->iterator].key;
  
  return k;
 }
  
/*
-----------------------------------------------------------------------
Get hash data from iterator
-----------------------------------------------------------------------
*/

UL getData(M **m, UL h)
 {

  Hash *H = addressHash(m, h);                   // Address hash

  if (H->iterator == MMU)                        // No iterated element
   {croak("no iterated element available for hash object %u", h);
   } 
   
  UL d = H->array[H->iterator].data;
  
  return d;
 }

/*
------------------------------------------------------------------------
Test
------------------------------------------------------------------------
*/

