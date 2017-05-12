/****************************************************************************
 *  This file is part of PPMd project                                       *
 *  Written and distributed to public domain by Dmitry Shkarin 1997,        *
 *  1999-2001                                                               *
 *  Contents: memory allocation routines                                    *
 ****************************************************************************/

//enum { UNIT_SIZE=12, N1=4, N2=4, N3=4, N4=(128+3-1*N1-2*N2-3*N3)/4,
//        N_INDEXES=N1+N2+N3+N4 };

#if defined(link)
#undef link
#endif

#if defined(unlink)
#undef unlink
#endif

#pragma pack(1)
struct BLK_NODE {
    DWORD Stamp;
    BLK_NODE* next;
    BOOL   avail()      const { return (next != NULL); }
    void    link(BLK_NODE* p) { p->next=next; next=p; }
    void  unlink()            { next=next->next; }
    void* remove()            {
        BLK_NODE* p=next;                   unlink();
        Stamp--;                            return p;
    }
    inline void insert(void* pv,int NU);
}; // BList[N_INDEXES];
struct MEM_BLK: public BLK_NODE { DWORD NU; } _PACK_ATTR;
#pragma pack()

class SubAlloc {
    friend class PPMD_Stream;
    friend class PPMD_Encoder;
    friend class PPMD_Decoder;
    friend class PPM_CONTEXT;
public:
    SubAlloc() : SubAllocatorSize(0) {};

    inline void SplitBlock(void* pv,UINT OldIndx,UINT NewIndx);
    inline DWORD GetUsedMemory();
    inline void* AllocUnitsRare(UINT indx);
    inline void StopSubAllocator();
    inline BOOL StartSubAllocator(UINT SASize);
    inline void InitSubAllocator();
    inline void GlueFreeBlocks();
    inline void* AllocUnits(UINT NU);
    inline void* AllocContext();
    inline void* ExpandUnits(void* OldPtr,UINT OldNU);
    inline void* ShrinkUnits(void* OldPtr,UINT OldNU,UINT NewNU);
    inline void FreeUnits(void* ptr,UINT NU);
    inline void SpecialFreeUnit(void* ptr);
    inline void* MoveUnitsUp(void* OldPtr,UINT NU);
    inline void ExpandTextArea();
    
private:
    struct BLK_NODE BList[N_INDEXES];
    DWORD GlueCount, SubAllocatorSize;
    BYTE* HeapStart, * pText, * UnitsStart, * LoUnit, * HiUnit;
};

//static BYTE Indx2Units[N_INDEXES], Units2Indx[128]; // constants
//static DWORD GlueCount, SubAllocatorSize=0;
//static BYTE* HeapStart, * pText, * UnitsStart, * LoUnit, * HiUnit;

