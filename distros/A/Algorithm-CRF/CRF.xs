#include "common.h"
#include "encoder.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

using namespace CRFPP;

MODULE = Algorithm::CRF		PACKAGE = Algorithm::CRF		

PROTOTYPES: ENABLE

bool
crfpp_learn( templfile, trainfile, modelfile, textmodelfile, maxitr, freq, eta, C, thread_num , shrinking_size, algorithm, convert)
	const char *templfile
	const char *trainfile
	const char *modelfile
	bool textmodelfile
	size_t maxitr
	size_t freq
	double eta
	double C
	unsigned short thread_num
	unsigned short shrinking_size
	int algorithm
	bool convert
    CODE:
CRFPP::Encoder encoder;
    if (thread_num > 1024)
	fprintf (stderr,"#thread is too big\n",encoder.what());
    if (convert) {
	if (! encoder.convert(templfile, trainfile)) {
	    //cerr << encoder.what() << endl;
	    fprintf (stderr,"%s\n",encoder.what());
	    RETVAL = -1;
	}
    } else {
	if (! encoder.learn ( templfile, 
	trainfile, 
	modelfile, 
	textmodelfile, 
	maxitr, 
	freq, 
	eta, 
	C, 
	thread_num,
        shrinking_size,
	algorithm )) {
	    //	cerr << encoder.what() << endl;
	    fprintf (stderr,"%s\n",encoder.what());
	    RETVAL = -1;
	} else
	    RETVAL = 0;
    }
    OUTPUT:
	RETVAL

