#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "Types.hpp"
#include "Model.hpp"
#include "Wrapper.hpp"


MODULE = Compress::PPMd                         PACKAGE = Compress::PPMd::Encoder
PROTOTYPES: DISABLE

SV *
PPMD_Encoder_Perl::encode(in)
    SV *in;

PPMD_Encoder_Perl *
PPMD_Encoder_Perl::new(MaxOrder=8, Size=4, MRMethod=2, Solid=1)
    unsigned int MaxOrder;
    unsigned int Size;
    int MRMethod
    int Solid
CODE:
    try {
	RETVAL=new PPMD_Encoder_Perl(MaxOrder, Size, MRMethod, Solid);
    }
    catch (PPMD_Exception e) {
	die (e.Text());
    }
OUTPUT:
    RETVAL

void
PPMD_Decoder_Perl::reset()

void
PPMD_Encoder_Perl::DESTROY()




MODULE = Compress::PPMd                    PACKAGE = Compress::PPMd::Decoder


SV *
PPMD_Decoder_Perl::decode(in)
    SV *in;
CODE:
    try {
	RETVAL=THIS->decode(in);
    }
    catch (PPMD_Exception e) {
	die (e.Text());
    }
OUTPUT:
    RETVAL


PPMD_Decoder_Perl *
PPMD_Decoder_Perl::new(MaxOrder=8, Size=4, MRMethod=2, Solid=1)
    unsigned int MaxOrder;
    unsigned int Size;
    int MRMethod
    int Solid
CODE:
    try {
	RETVAL=new PPMD_Decoder_Perl(MaxOrder, Size, MRMethod, Solid);
    }
    catch (PPMD_Exception e) {
	die (e.Text());
    }
OUTPUT:
    RETVAL

void
PPMD_Decoder_Perl::reset()

void
PPMD_Decoder_Perl::DESTROY()


MODULE = Compress::PPMd                         PACKAGE = Compress::PPMd

