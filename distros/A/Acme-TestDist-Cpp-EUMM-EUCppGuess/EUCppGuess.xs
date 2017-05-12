#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "nuratest.cpp"

MODULE = Acme::TestDist::Cpp::EUMM::EUCppGuess		PACKAGE = Acme::TestDist::Cpp::EUMM::EUCppGuess

int
returnOne()

	OUTPUT:
		RETVAL

