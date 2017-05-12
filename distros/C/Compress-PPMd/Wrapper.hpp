#include "Exception.hpp"

class PPMD_Encoder_Perl : public PPMD_Encoder {
public:
    PPMD_Encoder_Perl(unsigned int MaxOrder, unsigned int Size, int MRMethod, int Solid) :
	myMaxOrder(MaxOrder), myCurrentMaxOrder(MaxOrder), myMRMethod(MRMethod), mySolid(Solid) {
	if (MaxOrder<2 || MaxOrder>16)
	    throw PPMD_Exception("Invalid argument: MaxOrder out of range");
	if (MRMethod<1 || MRMethod>3)
	    throw PPMD_Exception("Invalid argument: MRMethod out of range");

	if (!StartSubAllocator(Size)) 
	    throw PPMD_Exception("Unable to create SubAllocator: out of memory");
    }

    SV *encode (SV *in) {
	PPMD_In in_b(in);
	SV *out=newSVpvn("", 0);
	SvGROW(out, sv_len(in)/2);
	sv_2mortal(out);
	PPMD_Out out_b(out);
	int MaxOrder;
	if (mySolid) {
	    MaxOrder=myCurrentMaxOrder;
	    myCurrentMaxOrder=1;
	}
	EncodeFile(&out_b, &in_b, MaxOrder, (MR_METHOD)myMRMethod);
	SvREFCNT_inc(out);
	return out;
    }

    void reset() { myCurrentMaxOrder=myMaxOrder; }

private:
    unsigned int myMaxOrder;
    unsigned int myCurrentMaxOrder;
    int myMRMethod;
    int mySolid;
};

class PPMD_Decoder_Perl : public PPMD_Decoder {
public:
    PPMD_Decoder_Perl(unsigned int MaxOrder, unsigned int Size, int MRMethod, int Solid) :
	myMaxOrder(MaxOrder), myCurrentMaxOrder(MaxOrder), myMRMethod(MRMethod), mySolid(Solid) {
	if (MaxOrder<2 || MaxOrder>16)
	    throw PPMD_Exception("Invalid argument: MaxOrder out of range");
	if (MRMethod<1 || MRMethod>3)
	    throw PPMD_Exception("Invalid argument: MRMethod out of range");

	if (!StartSubAllocator(Size)) 
	    throw PPMD_Exception("Unable to create SubAllocator: out of memory");
    }

    SV *decode (SV *in) {
	PPMD_In in_b(in, 1);
	SV *out=newSVpvn("", 0);
	SvGROW(out, sv_len(in)*6);
	sv_2mortal(out);
	PPMD_Out out_b(out);
	int MaxOrder;
	if (mySolid) {
	    MaxOrder=myCurrentMaxOrder;
	    myCurrentMaxOrder=1;
	}
	DecodeFile(&out_b, &in_b, MaxOrder, (MR_METHOD)myMRMethod);
	SvREFCNT_inc(out);
	return out;
    }

    void reset() { myCurrentMaxOrder=myMaxOrder; }

private:
    unsigned int myMaxOrder;
    unsigned int myCurrentMaxOrder;
    int myMRMethod;
    int mySolid;
};
