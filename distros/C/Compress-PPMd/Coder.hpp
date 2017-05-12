/****************************************************************************
 *  This file is part of PPMd project                                       *
 *  Contents: 'Carryless rangecoder' by Dmitry Subbotin                     *
 *  Comments: this implementation is claimed to be a public domain          *
 ****************************************************************************/
/**********************  Original text  *************************************
////////   Carryless rangecoder (c) 1999 by Dmitry Subbotin   ////////

typedef unsigned int  uint;
typedef unsigned char uc;

#define  DO(n)     for (int _=0; _<n; _++)
#define  TOP       (1<<24)
#define  BOT       (1<<16)


class RangeCoder
{
 uint  low, code, range, passed;
 FILE  *f;

 void OutByte (uc c)           { passed++; fputc(c,f); }
 uc   InByte ()                { passed++; return fgetc(f); }

public:

 uint GetPassed ()             { return passed; }
 void StartEncode (FILE *F)    { f=F; passed=low=0;  range= (uint) -1; }
 void FinishEncode ()          { DO(4)  OutByte(low>>24), low<<=8; }
 void StartDecode (FILE *F)    { passed=low=code=0;  range= (uint) -1;
                                 f=F; DO(4) code= code<<8 | InByte();
                               }

 void Encode (uint cumFreq, uint freq, uint totFreq) {
    assert(cumFreq+freq<totFreq && freq && totFreq<=BOT);
    low  += cumFreq * (range/= totFreq);
    range*= freq;
    while ((low ^ low+range)<TOP || range<BOT && ((range= -low & BOT-1),1))
       OutByte(low>>24), range<<=8, low<<=8;
 }

 uint GetFreq (uint totFreq) {
   uint tmp= (code-low) / (range/= totFreq);
   if (tmp >= totFreq)  throw ("Input data corrupt"); // or force it to return
   return tmp;                                         // a valid value :)
 }

 void Decode (uint cumFreq, uint freq, uint totFreq) {
    assert(cumFreq+freq<totFreq && freq && totFreq<=BOT);
    low  += cumFreq*range;
    range*= freq;
    while ((low ^ low+range)<TOP || range<BOT && ((range= -low & BOT-1),1))
       code= code<<8 | InByte(), range<<=8, low<<=8;
 }
};
*****************************************************************************/

struct SUBRANGE {
    DWORD LowCount, HighCount, scale;
};
enum { TOP=1 << 24, BOT=1 << 15 };

class Ari {
public:
    inline UINT GetCurrentCount();
    inline UINT GetCurrentShiftCount(UINT SHIFT);
    inline void RemoveSubrange();

    inline void EncoderInit();
    inline void EncodeSymbol();
    inline void ShiftEncodeSymbol(UINT SHIFT);
    inline void EncoderNormalize(PPMD_Out *stream);
    inline void EncoderFlush(PPMD_Out *stream);


    inline void DecoderInit(PPMD_In *stream);
    inline void DecoderNormalize(PPMD_In *stream);

    SUBRANGE SubRange;

protected:
    DWORD low, code, range;
};


inline UINT Ari::GetCurrentCount() {
    return (code-low)/(range /= SubRange.scale);
}
inline UINT Ari::GetCurrentShiftCount(UINT SHIFT) {
    return (code-low)/(range >>= SHIFT);
}
inline void Ari::RemoveSubrange()
{
    low += range*SubRange.LowCount;
    range *= SubRange.HighCount-SubRange.LowCount;
}

inline void Ari::EncoderInit() {
    low=0;
    range=DWORD(-1);
}

inline void Ari::EncoderNormalize(PPMD_Out *stream) {
    while ((low ^ (low+range)) < TOP || range < BOT &&
	   ((range= -low & (BOT-1)),1)) {
        _PPMD_E_PUTC((unsigned char)(low >> 24),stream);
        range <<= 8;
	low <<= 8;
    }
}

inline void Ari::EncodeSymbol()
{
    low += SubRange.LowCount*(range /= SubRange.scale);
    range *= SubRange.HighCount-SubRange.LowCount;
}
inline void Ari::ShiftEncodeSymbol(UINT SHIFT)
{
    low += SubRange.LowCount*(range >>= SHIFT);
    range *= SubRange.HighCount-SubRange.LowCount;
}

inline void Ari::EncoderFlush(PPMD_Out *stream) {
    for (UINT i=0;i < 4;i++) {
        _PPMD_E_PUTC(low >> 24,stream);
	low <<= 8;
    }
}

inline void Ari::DecoderInit(PPMD_In *stream) {
    low=code=0;
    range=DWORD(-1);
    for (UINT i=0;i < 4;i++)
	code=(code << 8) | _PPMD_D_GETC(stream);
}

inline void Ari::DecoderNormalize(PPMD_In *stream) {
    while ((low ^ (low+range)) < TOP || range < BOT &&
	   ((range= -low & (BOT-1)),1)) {
        code=(code << 8) | _PPMD_D_GETC(stream);
        range <<= 8;
	low <<= 8;
    }
}
