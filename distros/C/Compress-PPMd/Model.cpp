/****************************************************************************
 *  This file is part of PPMd project                                       *
 *  Written and distributed to public domain by Dmitry Shkarin 1997,        *
 *  1999-2001                                                               *
 *  Contents: PPMII model description and encoding/decoding routines        *
 ****************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>
#include "Types.hpp"
#include "Model.hpp"

#include "Constants2.h"
#include "SubAlloc_impl.hpp"

inline void SEE2_CONTEXT::init(UINT InitVal) {
    Summ=InitVal << (Shift=PERIOD_BITS-4);
    Count=7;
}

inline UINT SEE2_CONTEXT::getMean() {
    UINT RetVal=(Summ >> Shift);
    Summ -= RetVal;
    return RetVal+(RetVal == 0);
}
inline void SEE2_CONTEXT::update() {
    if (Shift < PERIOD_BITS && --Count == 0) {
	Summ += Summ;
	Count=3 << Shift++;
    }
}

inline void StateCpy(PPM_CONTEXT::STATE& s1,const PPM_CONTEXT::STATE& s2)
{
    (WORD&) s1=(WORD&) s2;                  s1.Successor=s2.Successor;
}

inline void SWAP(PPM_CONTEXT::STATE& s1,PPM_CONTEXT::STATE& s2)
{
    WORD t1=(WORD&) s1;                     PPM_CONTEXT* t2=s1.Successor;
    (WORD&) s1 = (WORD&) s2;                s1.Successor=s2.Successor;
    (WORD&) s2 = t1;                        s2.Successor=t2;
}

// Tabulated escapes for exponential symbol distribution
static const BYTE ExpEscape[16]={ 25, 14, 9, 7, 5, 5, 4, 4,
				  4, 3, 3, 3, 2, 2, 2, 2 };
#define GET_MEAN(SUMM,SHIFT,ROUND) ((SUMM+(1 << (SHIFT-ROUND))) >> (SHIFT))

inline void PPM_CONTEXT::encodeBinSymbol(int symbol, PPMD_Encoder &encoder)
{
    BYTE indx=NS2BSIndx[Suffix->NumStats]+encoder.PrevSuccess+Flags;
    STATE& rs=oneState();
    WORD& bs=encoder.BinSumm[QTable[rs.Freq-1]]
	[indx+((encoder.RunLength >> 26) & 0x20)];
    if (rs.Symbol == symbol) {
        encoder.FoundState=&rs;
	rs.Freq += (rs.Freq < 196);
        encoder.ari.SubRange.LowCount=0;
	encoder.ari.SubRange.HighCount=bs;
        bs += INTERVAL-GET_MEAN(bs,PERIOD_BITS,2);
        encoder.PrevSuccess=1;
	encoder.RunLength++;
    } else {
        encoder.ari.SubRange.LowCount=bs;
	bs -= GET_MEAN(bs,PERIOD_BITS,2);
        encoder.ari.SubRange.HighCount=BIN_SCALE;
	encoder.InitEsc=ExpEscape[bs >> 10];
        encoder.CharMask[rs.Symbol]=encoder.EscCount;
        encoder.NumMasked=encoder.PrevSuccess=0;
	encoder.FoundState=NULL;
    }
}
inline void PPM_CONTEXT::decodeBinSymbol(PPMD_Decoder &decoder)
{
    BYTE indx=NS2BSIndx[Suffix->NumStats]+decoder.PrevSuccess+Flags;
    STATE& rs=oneState();
    WORD& bs=decoder.BinSumm[QTable[rs.Freq-1]]
	[indx+((decoder.RunLength >> 26) & 0x20)];
    if (decoder.ari.GetCurrentShiftCount(TOT_BITS) < bs) {
        decoder.FoundState=&rs;
	rs.Freq += (rs.Freq < 196);
        decoder.ari.SubRange.LowCount=0;
	decoder.ari.SubRange.HighCount=bs;
        bs += INTERVAL-GET_MEAN(bs,PERIOD_BITS,2);
        decoder.PrevSuccess=1;
	decoder.RunLength++;
    } else {
        decoder.ari.SubRange.LowCount=bs;
	bs -= GET_MEAN(bs,PERIOD_BITS,2);
        decoder.ari.SubRange.HighCount=BIN_SCALE;
	decoder.InitEsc=ExpEscape[bs >> 10];
        decoder.CharMask[rs.Symbol]=decoder.EscCount;
        decoder.NumMasked=decoder.PrevSuccess=0;
	decoder.FoundState=NULL;
    }
}

inline void PPM_CONTEXT::update1(STATE* p, PPMD_Stream &stream)
{
    (stream.FoundState=p)->Freq += 4;
    SummFreq += 4;
    if (p[0].Freq > p[-1].Freq) {
        SWAP(p[0],p[-1]);
	stream.FoundState=--p;
        if (p->Freq > MAX_FREQ)
	    rescale( stream );
    }
}

inline void PPM_CONTEXT::encodeSymbol1(int symbol, PPMD_Encoder &encoder)
{
    UINT LoCnt, i=Stats->Symbol;
    STATE* p=Stats;
    encoder.ari.SubRange.scale=SummFreq;
    if (i == symbol) {
        encoder.PrevSuccess=(2*(encoder.ari.SubRange.HighCount=p->Freq)
			     >= encoder.ari.SubRange.scale);
        (encoder.FoundState=p)->Freq += 4;
	SummFreq += 4;
        encoder.RunLength += encoder.PrevSuccess;
        if (p->Freq > MAX_FREQ)
	    rescale(encoder);
        encoder.ari.SubRange.LowCount=0;
	return;
    }
    LoCnt=p->Freq;
    i=NumStats;
    encoder.PrevSuccess=0;
    while ((++p)->Symbol != symbol) {
        LoCnt += p->Freq;
        if (--i == 0) {
            if ( Suffix )
		PrefetchData(Suffix);
            encoder.ari.SubRange.LowCount=LoCnt;
	    encoder.CharMask[p->Symbol]=encoder.EscCount;
            i=encoder.NumMasked=NumStats;
	    encoder.FoundState=NULL;
            do {
		encoder.CharMask[(--p)->Symbol]=encoder.EscCount;
	    } while ( --i );
            encoder.ari.SubRange.HighCount=encoder.ari.SubRange.scale;
            return;
        }
    }
    encoder.ari.SubRange.HighCount =
	(encoder.ari.SubRange.LowCount=LoCnt)+p->Freq;
    update1(p, encoder);
}
inline void PPM_CONTEXT::decodeSymbol1(PPMD_Decoder &decoder)
{
    UINT i, count, HiCnt=Stats->Freq;
    STATE* p=Stats;
    decoder.ari.SubRange.scale=SummFreq;
    if ((count=decoder.ari.GetCurrentCount()) < HiCnt) {
        decoder.PrevSuccess=(2*(decoder.ari.SubRange.HighCount=HiCnt)
			     >= decoder.ari.SubRange.scale);
        (decoder.FoundState=p)->Freq=(HiCnt += 4);
	SummFreq += 4;
        decoder.RunLength += decoder.PrevSuccess;
        if (HiCnt > MAX_FREQ)
	    rescale(decoder);
        decoder.ari.SubRange.LowCount=0;
	return;
    }
    i=NumStats;
    decoder.PrevSuccess=0;
    while ((HiCnt += (++p)->Freq) <= count)
        if (--i == 0) {
            if ( Suffix )
		PrefetchData(Suffix);
            decoder.ari.SubRange.LowCount=HiCnt;
	    decoder.CharMask[p->Symbol]=decoder.EscCount;
            i=decoder.NumMasked=NumStats;
	    decoder.FoundState=NULL;
            do {
		decoder.CharMask[(--p)->Symbol]=decoder.EscCount;
	    } while ( --i );
            decoder.ari.SubRange.HighCount=decoder.ari.SubRange.scale;
            return;
        }
    decoder.ari.SubRange.LowCount =
	(decoder.ari.SubRange.HighCount=HiCnt)-p->Freq;
    update1(p, decoder);
}
inline void PPM_CONTEXT::update2(STATE* p, PPMD_Stream &stream)
{
    (stream.FoundState=p)->Freq += 4;
    SummFreq += 4;
    if (p->Freq > MAX_FREQ)
	rescale(stream);
    stream.EscCount++;
    stream.RunLength=stream.InitRL;
}
inline SEE2_CONTEXT* PPM_CONTEXT::makeEscFreq2(PPMD_Stream &stream)
{
    BYTE* pb=(BYTE*) Stats;
    UINT t=2*NumStats;
    PrefetchData(pb);
    PrefetchData(pb+t);
    PrefetchData(pb += 2*t);
    PrefetchData(pb+t);
    SEE2_CONTEXT* psee2c;
    if (NumStats != 0xFF) {
        t=Suffix->NumStats;
        psee2c=stream.SEE2Cont[QTable[NumStats+2]-3]+(SummFreq > 11*(NumStats+1));
        psee2c += 2*(2*NumStats < t+stream.NumMasked)+Flags;
        stream.ari.SubRange.scale=psee2c->getMean();
    } else {
        psee2c=&(stream.DummySEE2Cont);
	stream.ari.SubRange.scale=1;
    }
    return psee2c;
}
inline void PPM_CONTEXT::encodeSymbol2(int symbol, PPMD_Encoder &encoder)
{
    SEE2_CONTEXT* psee2c=makeEscFreq2(encoder);
    UINT Sym, LoCnt=0, i=NumStats-encoder.NumMasked;
    STATE* p1, * p=Stats-1;
    do {
        do {
	    Sym=(++p)->Symbol;
	} while (encoder.CharMask[Sym] == encoder.EscCount);
        encoder.CharMask[Sym]=encoder.EscCount;
        if (Sym == symbol)
	    goto SYMBOL_FOUND;
        LoCnt += p->Freq;
    } while ( --i );
    encoder.ari.SubRange.HighCount= (encoder.ari.SubRange.scale +=
				     (encoder.ari.SubRange.LowCount=LoCnt));
    psee2c->Summ += encoder.ari.SubRange.scale;
    encoder.NumMasked = NumStats;
    return;
SYMBOL_FOUND:
    encoder.ari.SubRange.LowCount=LoCnt;
    encoder.ari.SubRange.HighCount=(LoCnt+=p->Freq);
    for (p1=p; --i ; ) {
        do {
	    Sym=(++p1)->Symbol;
	} while (encoder.CharMask[Sym] == encoder.EscCount);
        LoCnt += p1->Freq;
    }
    encoder.ari.SubRange.scale += LoCnt;
    psee2c->update();
    update2(p, encoder);
}
inline void PPM_CONTEXT::decodeSymbol2(PPMD_Decoder &decoder)
{
    SEE2_CONTEXT* psee2c=makeEscFreq2(decoder);
    UINT Sym, count, HiCnt=0, i=NumStats-decoder.NumMasked;
    STATE* ps[256], ** pps=ps, * p=Stats-1;
    do {
        do {
	    Sym=(++p)->Symbol;
	} while (decoder.CharMask[Sym] == decoder.EscCount);
        HiCnt += p->Freq;
	*pps++ = p;
    } while ( --i );
    decoder.ari.SubRange.scale += HiCnt;
    count=decoder.ari.GetCurrentCount();
    p=*(pps=ps);
    if (count < HiCnt) {
        HiCnt=0;
        while ((HiCnt += p->Freq) <= count)
	    p=*++pps;
        decoder.ari.SubRange.LowCount =
	    (decoder.ari.SubRange.HighCount=HiCnt)-p->Freq;
        psee2c->update();
	update2(p, decoder);
    } else {
        decoder.ari.SubRange.LowCount=HiCnt;
	decoder.ari.SubRange.HighCount=decoder.ari.SubRange.scale;
        i=NumStats-decoder.NumMasked;
	decoder.NumMasked = NumStats;
        do {
	    decoder.CharMask[(*pps)->Symbol]=decoder.EscCount; pps++;
	} while ( --i );
        psee2c->Summ += decoder.ari.SubRange.scale;
    }
}

void PPM_CONTEXT::refresh(int OldNU,BOOL Scale, PPMD_Stream &stream)
{
    int i=NumStats, EscFreq;
    STATE* p = Stats = (STATE*) stream.Memory.ShrinkUnits(Stats,OldNU,(i+2) >> 1);
    Flags=(Flags & (0x10+0x04*Scale))+0x08*(p->Symbol >= 0x40);
    EscFreq=SummFreq-p->Freq;
    SummFreq = (p->Freq=(p->Freq+Scale) >> Scale);
    do {
        EscFreq -= (++p)->Freq;
        SummFreq += (p->Freq=(p->Freq+Scale) >> Scale);
        Flags |= 0x08*(p->Symbol >= 0x40);
    } while ( --i );
    SummFreq += (EscFreq=(EscFreq+Scale) >> Scale);
}
#define P_CALL(F) ( PrefetchData(p->Successor), \
                    p->Successor=p->Successor->F(Order+1))
#define P_CALL2(F, o2) ( PrefetchData(p->Successor), \
                         p->Successor=p->Successor->F(Order+1, o2))
PPM_CONTEXT* PPM_CONTEXT::cutOff(int Order, PPMD_Stream &stream)
{
    int i, tmp;
    STATE* p;
    if ( !NumStats ) {
        if ((BYTE*) (p=&oneState())->Successor >= stream.Memory.UnitsStart) {
            if (Order < stream.MaxOrder)
		P_CALL2(cutOff, stream);
            else
		p->Successor=NULL;
            if (!p->Successor && Order > O_BOUND)
		goto REMOVE;
            return this;
        } else {
	REMOVE:
	    stream.Memory.SpecialFreeUnit(this);
	    return NULL;
        }
    }
    PrefetchData(Stats);
    Stats = (STATE*) stream.Memory.MoveUnitsUp(Stats,tmp=(NumStats+2) >> 1);
    for (p=Stats+(i=NumStats);p >= Stats;p--)
	if ((BYTE*) p->Successor < stream.Memory.UnitsStart) {
	    p->Successor=NULL;
	    SWAP(*p,Stats[i--]);
	} else if (Order < stream.MaxOrder)
	    P_CALL2(cutOff, stream);
	else
	    p->Successor=NULL;
    if (i != NumStats && Order) {
        NumStats=i;
	p=Stats;
        if (i < 0) { stream.Memory.FreeUnits(p,tmp);
	goto REMOVE; }
        else if (i == 0) {
            Flags=(Flags & 0x10)+0x08*(p->Symbol >= 0x40);
            StateCpy(oneState(),*p);
	    stream.Memory.FreeUnits(p,tmp);
            oneState().Freq=(oneState().Freq+11) >> 3;
        } else
	    refresh(tmp,SummFreq > 16*i, stream);
    }
    return this;
}
PPM_CONTEXT* PPM_CONTEXT::removeBinConts(int Order, PPMD_Stream &stream)
{
    STATE* p;
    if ( !NumStats ) {
        p=&oneState();
        if ((BYTE*) p->Successor >= stream.Memory.UnitsStart
	    && Order < stream.MaxOrder)
                P_CALL2(removeBinConts, stream);
        else
	    p->Successor=NULL;
        if (!p->Successor && (!Suffix->NumStats || Suffix->Flags == 0xFF)) {
            stream.Memory.FreeUnits(this,1);
	    return NULL;
        } else
	    return this;
    }
    PrefetchData(Stats);
    for (p=Stats+NumStats;p >= Stats;p--)
	if ((BYTE*) p->Successor >= stream.Memory.UnitsStart
	    && Order < stream.MaxOrder)
	    P_CALL2(removeBinConts, stream);
	else
	    p->Successor=NULL;
    return this;
}

//static PPM_CONTEXT* _FASTCALL CreateSuccessors(BOOL Skip,PPM_CONTEXT::STATE* p,
//					       PPM_CONTEXT* pc);

//void PPM_CONTEXT::rescale(PPM_CONTEXT::STATE * &FoundState,
//			  const int OrderFall,
//			  const MR_METHOD MRMethod)
void PPM_CONTEXT::rescale(PPMD_Stream &stream)
{
    UINT OldNU, Adder, EscFreq, i=NumStats;
    STATE tmp, * p1, * p;
    for (p=stream.FoundState;p != Stats;p--)       SWAP(p[0],p[-1]);
    p->Freq += 4;                           SummFreq += 4;
    EscFreq=SummFreq-p->Freq;
    Adder=(stream.OrderFall != 0 || stream.MRMethod > MRM_FREEZE);
    SummFreq = (p->Freq=(p->Freq+Adder) >> 1);
    do {
        EscFreq -= (++p)->Freq;
        SummFreq += (p->Freq=(p->Freq+Adder) >> 1);
        if (p[0].Freq > p[-1].Freq) {
            StateCpy(tmp,*(p1=p));
            do StateCpy(p1[0],p1[-1]); while (tmp.Freq > (--p1)[-1].Freq);
            StateCpy(*p1,tmp);
        }
    } while ( --i );
    if (p->Freq == 0) {
        do { i++; } while ((--p)->Freq == 0);
        EscFreq += i;
	OldNU=(NumStats+2) >> 1;
        if ((NumStats -= i) == 0) {
            StateCpy(tmp,*Stats);
            tmp.Freq=(2*tmp.Freq+EscFreq-1)/EscFreq;
            if (tmp.Freq > MAX_FREQ/3)
		tmp.Freq=MAX_FREQ/3;
            stream.Memory.FreeUnits(Stats,OldNU);
	    StateCpy(oneState(),tmp);
            Flags=(Flags & 0x10)+0x08*(tmp.Symbol >= 0x40);
            stream.FoundState=&oneState();
	    return;
        }
        Stats = (STATE*)
	    stream.Memory.ShrinkUnits(Stats,OldNU,(NumStats+2) >> 1);
        Flags &= ~0x08;
	i=NumStats;
        Flags |= 0x08*((p=Stats)->Symbol >= 0x40);
        do {
	    Flags |= 0x08*((++p)->Symbol >= 0x40);
	} while ( --i );
    }
    SummFreq += (EscFreq -= (EscFreq >> 1));
    Flags |= 0x04;
    stream.FoundState=Stats;
}

inline void PPMD_Stream::UpdateModel(PPM_CONTEXT* MinContext)
{
    PPM_CONTEXT::STATE* p=NULL;
    PPM_CONTEXT* Successor, * FSuccessor, * pc, * pc1=MaxContext;
    UINT ns1, ns, cf, sf, s0, FFreq=FoundState->Freq;
    BYTE Flag, sym, FSymbol=FoundState->Symbol;
    FSuccessor=FoundState->Successor;       pc=MinContext->Suffix;
    if (FFreq < MAX_FREQ/4 && pc) {
        if ( pc->NumStats ) {
            if ((p=pc->Stats)->Symbol != FSymbol) {
                do { sym=p[1].Symbol;       p++; } while (sym != FSymbol);
                if (p[0].Freq >= p[-1].Freq) {
                    SWAP(p[0],p[-1]);       p--;
                }
            }
            cf=2*(p->Freq < MAX_FREQ-9);
            p->Freq += cf;                  pc->SummFreq += cf;
        } else { p=&(pc->oneState());       p->Freq += (p->Freq < 32); }
    }
    if (!OrderFall && FSuccessor) {
        FoundState->Successor=CreateSuccessors(PPMD_TRUE,p,MinContext);
        if ( !FoundState->Successor )       goto RESTART_MODEL;
        MaxContext=FoundState->Successor;   return;
    }
    *(Memory.pText++) = FSymbol;
    Successor = (PPM_CONTEXT*) Memory.pText;
    if (Memory.pText >= Memory.UnitsStart)
	goto RESTART_MODEL;
    if ( FSuccessor ) {
        if ((BYTE*) FSuccessor < Memory.UnitsStart)
	    FSuccessor=CreateSuccessors(PPMD_FALSE,p,MinContext);
    } else
	FSuccessor=ReduceOrder(p,MinContext);
    if ( !FSuccessor )
	goto RESTART_MODEL;
    if ( !--OrderFall ) {
        Successor=FSuccessor;
	Memory.pText -= (MaxContext != MinContext);
    } else if (MRMethod > MRM_FREEZE) {
        Successor=FSuccessor;
	Memory.pText=Memory.HeapStart;
        OrderFall=0;
    }
    s0=MinContext->SummFreq-(ns=MinContext->NumStats)-FFreq;
    for (Flag=0x08*(FSymbol >= 0x40);pc1 != MinContext;pc1=pc1->Suffix) {
        if ((ns1=pc1->NumStats) != 0) {
            if ((ns1 & 1) != 0) {
                p=(PPM_CONTEXT::STATE*)
		    Memory.ExpandUnits(pc1->Stats,(ns1+1) >> 1);
                if ( !p )
		    goto RESTART_MODEL;
                pc1->Stats=p;
            }
            pc1->SummFreq += (3*ns1+1 < ns);
        } else {
            p=(PPM_CONTEXT::STATE*) Memory.AllocUnits(1);
            if ( !p )                       goto RESTART_MODEL;
            StateCpy(*p,pc1->oneState());   pc1->Stats=p;
            if (p->Freq < MAX_FREQ/4-1)     p->Freq += p->Freq;
            else                            p->Freq  = MAX_FREQ-4;
            pc1->SummFreq=p->Freq+InitEsc+(ns > 2);
        }
        cf=2*FFreq*(pc1->SummFreq+6);       sf=s0+pc1->SummFreq;
        if (cf < 6*sf) {
            cf=1+(cf > sf)+(cf >= 4*sf);
            pc1->SummFreq += 4;
        } else {
            cf=4+(cf > 9*sf)+(cf > 12*sf)+(cf > 15*sf);
            pc1->SummFreq += cf;
        }
        p=pc1->Stats+(++pc1->NumStats);     p->Successor=Successor;
        p->Symbol = FSymbol;                p->Freq = cf;
        pc1->Flags |= Flag;
    }
    MaxContext=FSuccessor;                  return;
RESTART_MODEL:
    RestoreModelRare(pc1,MinContext,FSuccessor);
}

inline void PPMD_Stream::ClearMask() 
{
    EscCount=1;
    memset(CharMask,0,sizeof(CharMask));
    // if (++PrintCount == 0)
    // PrintInfo(DecodedFile,EncodedFile);
}

void PPMD_Stream::StartModelRare(int MaxOrder,MR_METHOD MRMethod)
{
    UINT i, k, m;
    memset(CharMask,0,sizeof(CharMask));
    EscCount=1; //PrintCount=1;
    if (MaxOrder < 2) {                     // we are in solid mode
        OrderFall=this->MaxOrder;
        for (PPM_CONTEXT* pc=MaxContext;pc->Suffix != NULL;pc=pc->Suffix)
                OrderFall--;
        return;
    }
    OrderFall=this->MaxOrder=MaxOrder;
    this->MRMethod=MRMethod;
    Memory.InitSubAllocator();
    RunLength=InitRL=-((MaxOrder < 12)?MaxOrder:12)-1;
    MaxContext = (PPM_CONTEXT*) Memory.AllocContext();
    MaxContext->Suffix=NULL;
    MaxContext->SummFreq=(MaxContext->NumStats=255)+2;
    MaxContext->Stats = (PPM_CONTEXT::STATE*) Memory.AllocUnits(256/2);
    for (PrevSuccess=i=0;i < 256;i++) {
        MaxContext->Stats[i].Symbol=i;      MaxContext->Stats[i].Freq=1;
        MaxContext->Stats[i].Successor=NULL;
    }
static const WORD InitBinEsc[]={0x3CDD,0x1F3F,0x59BF,0x48F3,0x64A1,0x5ABC,0x6632,0x6051};
    for (i=m=0;m < 25;m++) {
        while (QTable[i] == m)              i++;
        for (k=0;k < 8;k++)
                BinSumm[m][k]=BIN_SCALE-InitBinEsc[k]/(i+1);
        for (k=8;k < 64;k += 8)
                memcpy(BinSumm[m]+k,BinSumm[m],8*sizeof(WORD));
    }
    for (i=m=0;m < 24;m++) {
        while (QTable[i+3] == m+3)          i++;
        SEE2Cont[m][0].init(2*i+5);
        for (k=1;k < 32;k++)                SEE2Cont[m][k]=SEE2Cont[m][0];
    }
}

PPM_CONTEXT* PPMD_Stream::ReduceOrder(PPM_CONTEXT::STATE* p,
					     PPM_CONTEXT* pc)
{
    PPM_CONTEXT::STATE* p1,  * ps[MAX_O], ** pps=ps;
    PPM_CONTEXT* pc1=pc, * UpBranch = (PPM_CONTEXT*) Memory.pText;
    BYTE tmp, sym=FoundState->Symbol;
    *pps++ = FoundState;                    FoundState->Successor=UpBranch;
    OrderFall++;
    if ( p ) { pc=pc->Suffix;               goto LOOP_ENTRY; }
    for ( ; ; ) {
        if ( !pc->Suffix ) {
            if (MRMethod > MRM_FREEZE) {
	    FROZEN:
		do {
		    (*--pps)->Successor = pc;
		} while (pps != ps);
		Memory.pText=Memory.HeapStart+1;
		OrderFall=1;
            }
            return pc;
        }
        pc=pc->Suffix;
        if ( pc->NumStats ) {
            if ((p=pc->Stats)->Symbol != sym)
                    do { tmp=p[1].Symbol;   p++; } while (tmp != sym);
            tmp=2*(p->Freq < MAX_FREQ-9);
            p->Freq += tmp;                 pc->SummFreq += tmp;
        } else { p=&(pc->oneState());       p->Freq += (p->Freq < 32); }
    LOOP_ENTRY:
        if ( p->Successor )                 break;
        *pps++ = p;                         p->Successor=UpBranch;
        OrderFall++;
    }
    if (MRMethod > MRM_FREEZE) {
        pc = p->Successor;
	goto FROZEN;
    } else if (p->Successor <= UpBranch) {
        p1=FoundState;
	FoundState=p;
        p->Successor=CreateSuccessors(PPMD_FALSE,NULL,pc);
        FoundState=p1;
    }
    if (OrderFall == 1 && pc1 == MaxContext) {
        FoundState->Successor=p->Successor;
	Memory.pText--;
    }
    return p->Successor;
}

void PPMD_Stream::RestoreModelRare(PPM_CONTEXT* pc1,
				   PPM_CONTEXT* MinContext,
				   PPM_CONTEXT* FSuccessor)
{
    PPM_CONTEXT* pc;
    PPM_CONTEXT::STATE* p;
    for (pc=MaxContext, Memory. pText=Memory.HeapStart;
	 pc != pc1;
	 pc=pc->Suffix)
            if (--(pc->NumStats) == 0) {
                pc->Flags=(pc->Flags & 0x10)+0x08*(pc->Stats->Symbol >= 0x40);
                p=pc->Stats;
                StateCpy(pc->oneState(),*p);
                Memory.SpecialFreeUnit(p);
                pc->oneState().Freq=(pc->oneState().Freq+11) >> 3;
            } else
		pc->refresh((pc->NumStats+3) >> 1,PPMD_FALSE, *this);
    for ( ;pc != MinContext;pc=pc->Suffix)
            if ( !pc->NumStats )
                    pc->oneState().Freq -= pc->oneState().Freq >> 1;
            else if ((pc->SummFreq += 4) > 128+4*pc->NumStats)
		pc->refresh((pc->NumStats+2) >> 1, PPMD_TRUE, *this);
    if (MRMethod > MRM_FREEZE) {
        MaxContext=FSuccessor;
	Memory.GlueCount += !(Memory.BList[1].Stamp & 1);
    }
    else if (MRMethod == MRM_FREEZE) {
        while ( MaxContext->Suffix )
	    MaxContext=MaxContext->Suffix;
        MaxContext->removeBinConts(0, *this);
	MRMethod=MR_METHOD(MRMethod+1);
        Memory.GlueCount=0;
	OrderFall=MaxOrder;
    }
    else if (MRMethod == MRM_RESTART || Memory.GetUsedMemory() < (Memory.SubAllocatorSize >> 1)) {
        StartModelRare(MaxOrder,MRMethod);
        EscCount=0;
	// PrintCount=0xFF;
    }
    else {
        while ( MaxContext->Suffix )
	    MaxContext=MaxContext->Suffix;
        do {
            MaxContext->cutOff(0, *this);
	    Memory.ExpandTextArea();
        } while (Memory.GetUsedMemory() > 3*(Memory.SubAllocatorSize >> 2));
        Memory.GlueCount=0;
	OrderFall=MaxOrder;
    }
}

PPM_CONTEXT* PPMD_Stream::CreateSuccessors(BOOL Skip,PPM_CONTEXT::STATE* p,
        PPM_CONTEXT* pc)
{
    PPM_CONTEXT ct, * UpBranch=FoundState->Successor;
    PPM_CONTEXT::STATE* ps[MAX_O], ** pps=ps;
    UINT cf, s0;
    BYTE tmp, sym=FoundState->Symbol;
    if ( !Skip ) {
        *pps++ = FoundState;
        if ( !pc->Suffix )                  goto NO_LOOP;
    }
    if ( p ) { pc=pc->Suffix;               goto LOOP_ENTRY; }
    do {
        pc=pc->Suffix;
        if ( pc->NumStats ) {
            if ((p=pc->Stats)->Symbol != sym)
                    do { tmp=p[1].Symbol;   p++; } while (tmp != sym);
            tmp=(p->Freq < MAX_FREQ-9);
            p->Freq += tmp;                 pc->SummFreq += tmp;
        } else {
            p=&(pc->oneState());
            p->Freq += (!pc->Suffix->NumStats & (p->Freq < 24));
        }
LOOP_ENTRY:
        if (p->Successor != UpBranch) {
            pc=p->Successor;                break;
        }
        *pps++ = p;
    } while ( pc->Suffix );
NO_LOOP:
    if (pps == ps)                          return pc;
    ct.NumStats=0;                          ct.Flags=0x10*(sym >= 0x40);
    ct.oneState().Symbol=sym=*(BYTE*) UpBranch;
    ct.oneState().Successor=(PPM_CONTEXT*) (((BYTE*) UpBranch)+1);
    ct.Flags |= 0x08*(sym >= 0x40);
    if ( pc->NumStats ) {
        if ((p=pc->Stats)->Symbol != sym)
                do { tmp=p[1].Symbol;       p++; } while (tmp != sym);
        s0=pc->SummFreq-pc->NumStats-(cf=p->Freq-1);
        ct.oneState().Freq=1+((2*cf <= s0)?(5*cf > s0):((cf+2*s0-3)/s0));
    } else
            ct.oneState().Freq=pc->oneState().Freq;
    do {
        PPM_CONTEXT* pc1 = (PPM_CONTEXT*) Memory.AllocContext();
        if ( !pc1 )                         return NULL;
        ((DWORD*) pc1)[0] = ((DWORD*) &ct)[0];
        ((DWORD*) pc1)[1] = ((DWORD*) &ct)[1];
        pc1->Suffix=pc;                     (*--pps)->Successor=pc=pc1;
    } while (pps != ps);
    return pc;
}

void PPMD_Encoder::EncodeFile(PPMD_Out* EncodedFile, PPMD_In* DecodedFile,
			      int MaxOrder,MR_METHOD MRMethod)
{
    ari.EncoderInit();
    StartModelRare(MaxOrder,MRMethod);
    for (PPM_CONTEXT* MinContext; ; ) {
        BYTE ns=(MinContext=MaxContext)->NumStats;
        int c = _PPMD_E_GETC(DecodedFile);
        if ( ns ) {
            MinContext->encodeSymbol1(c, *this);
	    ari.EncodeSymbol();
        } else {
            MinContext->encodeBinSymbol(c, *this);
	    ari.ShiftEncodeSymbol(TOT_BITS);
        }
        while ( !FoundState ) {
            ari.EncoderNormalize(EncodedFile);
            do {
                OrderFall++;
                MinContext=MinContext->Suffix;
                if ( !MinContext )
		    goto STOP_ENCODING;
            } while (MinContext->NumStats == NumMasked);
            MinContext->encodeSymbol2(c, *this);
	    ari.EncodeSymbol();
        }
        if (!OrderFall && (BYTE*) FoundState->Successor >= Memory.UnitsStart)
                PrefetchData(MaxContext=FoundState->Successor);
        else {
            UpdateModel(MinContext);
	    PrefetchData(MaxContext);
            if (EscCount == 0)
		// ClearMask(EncodedFile,DecodedFile);
		ClearMask();
        }
        ari.EncoderNormalize(EncodedFile);
    }
STOP_ENCODING:
    ari.EncoderFlush(EncodedFile);
    // PrintInfo(DecodedFile,EncodedFile);
}

void PPMD_Decoder::DecodeFile(PPMD_Out* DecodedFile, PPMD_In* EncodedFile,
			      int MaxOrder,MR_METHOD MRMethod)
{
    ari.DecoderInit(EncodedFile);
    StartModelRare(MaxOrder,MRMethod);
    PPM_CONTEXT* MinContext=MaxContext;
    for (BYTE ns=MinContext->NumStats; ; ) {
        ( ns )
	    ? (MinContext->decodeSymbol1(*this))
	    : (MinContext->decodeBinSymbol(*this));
        ari.RemoveSubrange();
        while ( !FoundState ) {
            ari.DecoderNormalize(EncodedFile);
            do {
                OrderFall++;
                MinContext=MinContext->Suffix;
                if ( !MinContext )
		    goto STOP_DECODING;
            } while (MinContext->NumStats == NumMasked);
            MinContext->decodeSymbol2(*this);
	    ari.RemoveSubrange();
        }
        _PPMD_D_PUTC(FoundState->Symbol,DecodedFile);
        if (!OrderFall && (BYTE*) FoundState->Successor >= Memory.UnitsStart)
                PrefetchData(MaxContext=FoundState->Successor);
        else {
            UpdateModel(MinContext);
	    PrefetchData(MaxContext);
            if (EscCount == 0)
		// ClearMask(EncodedFile,DecodedFile);
		ClearMask();
        }
        ns=(MinContext=MaxContext)->NumStats;
        ari.DecoderNormalize(EncodedFile);
    }
STOP_DECODING:
    return;
    // PrintInfo(DecodedFile,EncodedFile);
}


BOOL PPMD_Stream::StartSubAllocator(UINT SASize) {
    return Memory.StartSubAllocator(SASize);
}

void PPMD_Stream::StopSubAllocator() {
    Memory.StopSubAllocator();
}

