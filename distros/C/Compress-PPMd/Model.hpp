
#include "Constants.h"
#include "Coder.hpp"
#include "SubAlloc.hpp"

class PPMD_Stream;
class PPMD_Encoder;
class PPMD_Decoder;

#pragma pack(1)
class SEE2_CONTEXT { // SEE-contexts for PPM-contexts with masked symbols
public:
    WORD Summ;
    BYTE Shift, Count;
    inline void init(UINT InitVal);
    inline UINT getMean();
    inline void update();
} _PACK_ATTR;

class PPM_CONTEXT {                         // Notes:
public:
    BYTE NumStats, Flags;                   // 1. NumStats & NumMasked contain
    WORD SummFreq;                          //  number of symbols minus 1
    struct STATE {                          // 2. sizeof(WORD) > sizeof(BYTE)
        BYTE Symbol, Freq;                  // 3. contexts example:
        PPM_CONTEXT* Successor;             // MaxOrder:
    } _PACK_ATTR * Stats;                   //  ABCD    context
    PPM_CONTEXT* Suffix;                    //   BCD    suffix
    inline void encodeBinSymbol( int symbol,
				 PPMD_Encoder &stream);//   BCDE   successor
    inline void encodeSymbol1(int symbol, PPMD_Encoder &stream);// other orders:
    inline void encodeSymbol2(int symbol, PPMD_Encoder &stream);//   BCD    context
    inline void decodeBinSymbol(PPMD_Decoder &stream);//    CD    suffix
    inline void decodeSymbol1(PPMD_Decoder &stream);//   BCDE   successor
    inline void decodeSymbol2(PPMD_Decoder &stream);
    inline void update1(STATE* p, PPMD_Stream &stream);
    inline void update2(STATE* p, PPMD_Stream &stream);
    inline SEE2_CONTEXT* makeEscFreq2(PPMD_Stream &stream);
    void rescale(PPMD_Stream &stream);
    void refresh(int OldNU,BOOL Scale, PPMD_Stream &stream);
    PPM_CONTEXT* cutOff(int Order, PPMD_Stream &stream);
    PPM_CONTEXT* removeBinConts(int Order, PPMD_Stream &stream);
    STATE& oneState() const { return (STATE&) SummFreq; }
} _PACK_ATTR;
#pragma pack()

class PPMD_Stream {
    friend class PPM_CONTEXT;
public:
    inline PPMD_Stream();
    inline ~PPMD_Stream();

    BOOL StartSubAllocator(UINT SASize);
    void StopSubAllocator();

private:
    SEE2_CONTEXT SEE2Cont[24][32], DummySEE2Cont;
    int  InitEsc, RunLength, InitRL, MaxOrder;
    BYTE CharMask[256], PrevSuccess; //, PrintCount;
    WORD BinSumm[25][64]; // binary SEE-contexts
    MR_METHOD MRMethod;

protected:
    void StartModelRare(int MaxOrder,MR_METHOD MRMethod);
    PPM_CONTEXT* ReduceOrder(PPM_CONTEXT::STATE* p,PPM_CONTEXT* pc);
    void RestoreModelRare(PPM_CONTEXT* pc1,
			  PPM_CONTEXT* MinContext,
			  PPM_CONTEXT* FSuccessor);
    PPM_CONTEXT *CreateSuccessors(BOOL Skip,
				  PPM_CONTEXT::STATE* p,
				  PPM_CONTEXT* pc);
    inline void UpdateModel(PPM_CONTEXT* MinContext);
    inline void ClearMask();

    PPM_CONTEXT::STATE* FoundState;      // found next state transition
    struct PPM_CONTEXT* MaxContext;
    int OrderFall;
    BYTE NumMasked, EscCount;
    SubAlloc Memory;
    Ari ari;
};


class PPMD_Encoder : public PPMD_Stream {
public:
    void EncodeFile(PPMD_Out* EncodedFile,PPMD_In* DecodedFile,
		    int MaxOrder,MR_METHOD MRMethod);
};

class PPMD_Decoder : public PPMD_Stream {
public:
    void DecodeFile(PPMD_Out* DecodedFile,PPMD_In* EncodedFile,
		    int MaxOrder,MR_METHOD MRMethod);
};

inline PPMD_Stream::PPMD_Stream() {
    (DWORD&) DummySEE2Cont=PPMdSignature;
}

inline PPMD_Stream::~PPMD_Stream() {
    StopSubAllocator();
}

