
/**
 * this file contains the code common for SBL and buddy
 */

// XXX: we havent considred reordered variables yet!
// stuff like var2level() may be needed in some places when dynamic
// reordering is active!

//#include <jni.h>

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

// BuDDy headers
#include <bdd.h>
#include <kernel.h>
// #include <cache.h>

//#include "jbdd.h"

// best to use C++ keywords (?)
enum e_bool { false = 0, true = 1 };
//#define bool int


// see if the __func__ macro is available??
static void dummy_function() {
#ifndef __func__
 #define __func__ "?"
#endif
}

#define IGNORE_CALL fprintf(stderr,"(this function (%s, %s/%d) is not implemented)\n",  __func__, __FILE__, __LINE__)


// ----------------------------------------------------------------------
static int has_bdd = 0;

static int varnum = 0;		// max vars
static int varcount = 0;	// current var count!


#define MAX_NODES 8000000
#define MIN_NODES 1000


#define MAX_NODE_INCREASE 200000	/* default value is 50000 */

// -------------------------------------
#define CHECK_BDD(bdd)		/* do nothing */

// --------------------------------------------------------------------------------
