#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "common.h"

void dumpBDD_info(int bdd)
{
  BddNode *node;

  node = &bddnodes[bdd];
  fprintf (stderr,
	   "BDD %d:	RefCount %d, Level %-3d, IF %-3d, ELSE %-3d, HASH %d\n",
	   bdd, node->refcou, node->level, node->high, node->low, node->hash);
	fflush(stderr);
}

long createPair(int *old, int *new_, int size) {
  bddPair *pair = bdd_newpair ();

  int i;
  int len = size;
  int *old_vars = (int *)old;
  int *new_vars = (int *)new_;

  for (i = 0; i < len; i++)
    {
      /*
       * XXX - not bdd_var() call for new_vars[i] ??
       */

      bdd_setbddpair (pair, bdd_var(old_vars[i]), new_vars[i]);
    }
    
  return (long)pair;
}

int makeSet(int *vars, int size, int offset)
{
  BDD tmp, ret = 1;
  int i;
  int *body = (int *)vars;

  // DONT USE ´ret = bdd_makeset(body + offset, size);´ (it uses index
  // not variables)

  bdd_addref (ret);
  for (i = size - 1; i >= 0; i--)
    {

      CHECK_BDD (body[offset + i]);

      tmp = bdd_apply (ret, body[offset + i], bddop_and);
      bdd_addref (tmp);
      bdd_delref (ret);
      ret = tmp;
    }

  return ret;
}

int checkBuddy() {
  int i;

  if (!checkBDD (0))
    {
      fprintf (stderr, "bdd FALSE failed sanity check\n");
      dumpBDD_info (0);
      return 0;
    }

  if (!checkBDD (1))
    {
      fprintf (stderr, "bdd TRUE failed sanity check\n");
      dumpBDD_info (1);
      return 0;
    }

  for (i = bddvarnum; i < bddvarnum; i++)
    {
      if (!checkBDD (2 * i + 2))
	{
	  dumpBDD_info (2 * i + 2);
	  printf ("bdd variable #%d failed sanity check\n", i);
	  return 0;
	}

      if (!checkBDD (2 * i + 3))
	{
	  printf ("shadow of bdd variable #%d failed sanity check\n", i);
	  dumpBDD_info (2 * i + 3);
	  return 0;
	}
    }

    return 1;
}

int checkBDD(int bdd)
{
  if (!bddrunning)
    {
      bdd_error (BDD_RUNNING);
      return 0;
    }
  if (bdd < 0 || (bdd) >= bddnodesize)
    {
      bdd_error (BDD_ILLBDD);
      return 0;
    }
  if (bdd >= 2 && LOW (bdd) == -1)
    {
      bdd_error (BDD_ILLBDD);
      return 0;
    }

  if (bddnodes[bdd].refcou == 0)
    {
      fprintf (stderr, "ERROR: refcount is zero\n");
      return 0;
    }
  // refcount for TRUE and FALSE is saturated by default, ignore them!
  if (bdd > 2 && bddnodes[bdd].refcou == MAXREF)
    {
      fprintf (stderr, "ERROR: refcount is saturated\n");
      return 0;
    }

  return 1;
}

void printSet_rec(char *txt, int level, int bdd)
 {

  if (bdd == 0)
    {
      /*
       * do nothing
       */
      return;
    }
  else if (bdd == 1)
    {
      printf ("%s	1\n", txt);
      return;
    }
  else
    {
      BDD low = LOW (bdd);
      BDD high = HIGH (bdd);
      int l;
      char save;


      // printf("BDD=%d/%d, LOW=%d, HIGH=%d\n", bdd,
      // bddlevel2var[LEVEL(bdd)], low, high);
      l = bdd < varcount * 2 ? bdd / 2 - 1 : bddlevel2var[LEVEL (bdd)];

      save = txt[l];
      txt[l] = '0';
      // printf("*L_low=%d\n", l);
      printSet_rec (txt, level + 1, low);
      txt[l] = save;


      save = txt[l];
      txt[l] = '1';
      // printf("*L_high=%d (%d)\n", l, varcount);
      printSet_rec (txt, level + 1, high);
      txt[l] = save;
    }
}

// XXX: we havent considred reordered variables yet!
// stuff like var2level() may be needed in some places when dynamic
// reordering is active!


// --- [ dynamic reordering ]
// --------------------------------------------------
#define MAX_REORDERING_METHODS		5
int reordering_method_table[MAX_REORDERING_METHODS] = {
  BDD_REORDER_NONE,		// JBDD_REORDER_NONE
  BDD_REORDER_WIN2,		// JBDD_REORDER_WIN2
  BDD_REORDER_WIN3,		// JBDD_REORDER_WIN3
  BDD_REORDER_SIFT,		// JBDD_REORDER_SIFT
  BDD_REORDER_RANDOM		// JBDD_REORDER_RANDOM
};


// -----------------------------------------------------------------------------------

static int current_reordering_method = BDD_REORDER_NONE;

MODULE = AI::PBDD		PACKAGE = AI::PBDD

PROTOTYPES: DISABLE

void 
reorder_setMethod(method)
   int method
PPCODE:
{
  if (method >= 0 && method < MAX_REORDERING_METHODS)
    current_reordering_method = reordering_method_table[method];
}

void reorder_now()
PPCODE:
{
  bdd_reorder (current_reordering_method);
}

void reorder_createVariableGroup(first, last, fix)
   int first
   int last
   int fix
PPCODE:
{
  bdd_intaddvarblock (first, last,
		      fix ? BDD_REORDER_FIXED : BDD_REORDER_FREE);
}

int internal_index(bdd) 
   int bdd
CODE:
{
  CHECK_BDD (bdd);

  RETVAL = (bdd < varcount * 2) ? (bdd / 2 - 1) : bddlevel2var[LEVEL (bdd)];
}
OUTPUT:
RETVAL

void printSet(bdd)
   int bdd;
PPCODE:
{

  char *txt;
  int i;


  CHECK_BDD (bdd);


  if (bdd < 2)
    {
      printf ("\n%s\n", bdd == 0 ? "False" : "True");
      return;
    }

  txt = (char *) malloc (bddvarnum + 2);
  if (!txt)
    {
      bdd_error (BDD_MEMORY);
      return;
    }

  for (i = 0; i < varcount; i++)
    txt[i] = '-';
  txt[i] = '\0';

  printf ("\n");
  printSet_rec (txt, 0, bdd);

  free (txt);
  fflush(stdout);
}

void init(varnum_, node_count)
   int varnum_
   int node_count
PPCODE:
{
  int ok;
  long nodenum, cachesize;

  if (node_count < MIN_NODES)
    node_count = MIN_NODES;
  else if (node_count > MAX_NODES)
    {
      fprintf (stderr,
	       "[JBDD:init()] Number of nodes should be between %d and %d	nodes\n",
	       MIN_NODES, MAX_NODES);
      exit (20);
    }

  nodenum = node_count;
  cachesize = nodenum / 8;	// WAS: 10


  if (has_bdd)
    {
      fprintf (stderr,
	       "A BDD package exist while you are trying to create another one\n"
	       "The BDD package is SINGLETON!\n");

      exit (20);
    }

  ok = bdd_init (nodenum, cachesize);
  if (ok == 0)
    {
      varnum = varnum_;
      varcount = 0;

      bdd_setmaxincrease (MAX_NODE_INCREASE);
      bdd_setvarnum (2 + 2 * varnum);
      has_bdd = 1;


       if (bdd_false () != 0 || bdd_true () != 1)
	{
	  fprintf (stderr, " INTERNAL ERROR : false = %d, true = %d\n",
		   bdd_false (), bdd_true ());
	  exit (20);
	}

    }
  else
    {
      fprintf (stderr, "bdd_init(%ld,%ld) Failed\n (error code %d)\n",
	       nodenum, cachesize, ok);
      exit (20);
    }
}

void kill ()
PPCODE:
{
  if (has_bdd)
    {
      bdd_done ();
      has_bdd = 0;
    }
  else
    fprintf (stderr, "Killing already dead BDD class :(\n");
}


int getOne()
CODE:
{
  BDD ret = bdd_true ();

  CHECK_BDD (ret);

  RETVAL = ret;
}
OUTPUT:
RETVAL

int getZero()
CODE:
{
  BDD ret = bdd_false ();

  CHECK_BDD (ret);

  RETVAL=ret;
}
OUTPUT:
RETVAL


int createBDD()
CODE:
{
  BDD ret;

  if (varcount >= varnum)
    {
      fprintf (stderr, "Maximum var count (%d) reached!!\n", varnum);
      exit (20);
    }

  ret = bdd_ithvar (varcount++);
  // bddnodes[ret].refcou = 1;	// why does BuDDy sets the initial
  // refcount to MAXREF (0x3FF) ?

  RETVAL=ret;
}
OUTPUT:
RETVAL

int getVarCount()
CODE:
{
  RETVAL = varcount;
}
OUTPUT:
RETVAL

int getBDD(index)
   int index
CODE:
{
  if (index < 0 || index >= varcount)
    {
      fprintf (stderr, "[JBUDDY.getBDD] requested bad BDD: %d\n", index);
      RETVAL=bdd_false();
    }
  RETVAL=bdd_ithvar (index);
}
OUTPUT:
RETVAL

int ref(bdd)
   int bdd
CODE:
{
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

void localDeref(bdd)
   int bdd
CODE:
{
  CHECK_BDD (bdd);

  bdd_delref (bdd);
}

void deref(bdd)
   int bdd
CODE:
{

  CHECK_BDD (bdd);

  // ok, there is no recursive deref in BuDDy, as it is in CUDD.
  // I don't know how to fix this. I don't even know if this is needed
  // at all :)
  bdd_delref (bdd);
}

int and(l, r)
   int l
   int r
CODE:
{
  int bdd;

  CHECK_BDD (l);
  CHECK_BDD (r);

  bdd = bdd_apply (l, r, bddop_and);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int or(l, r)
   int l
   int r
CODE:
{
  int bdd;

  CHECK_BDD (l);
  CHECK_BDD (r);

  bdd = bdd_apply (l, r, bddop_or);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int andTo(l, r)
   int l
   int r
CODE:
{
  BDD ret;

  CHECK_BDD (l);
  CHECK_BDD (r);

  ret = bdd_apply (l, r, bddop_and);
  bdd_addref (ret);
  bdd_delref (l);
  RETVAL=ret;
}
OUTPUT:
RETVAL

int orTo(l, r)
   int l
   int r
CODE:
{
  BDD ret;

  CHECK_BDD (r);
  CHECK_BDD (l);

  ret = bdd_apply (l, r, bddop_or);
  bdd_addref (ret);
  bdd_delref (l);
  RETVAL=ret;
}
OUTPUT:
RETVAL

int nand(l, r)
   int l
   int r
CODE:
{
  BDD bdd;

  CHECK_BDD (l);
  CHECK_BDD (r);

  bdd = bdd_apply (l, r, bddop_nand);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int nor(l, r)
   int l
   int r
CODE:
{
  BDD bdd;

  CHECK_BDD (l);
  CHECK_BDD (r);


  bdd = bdd_apply (l, r, bddop_nor);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int xor(l, r)
   int l
   int r
CODE:
{
  BDD bdd;

  CHECK_BDD (l);
  CHECK_BDD (r);

  bdd = bdd_apply (l, r, bddop_xor);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int ite(if_, then_, else_)
   int if_
   int then_
   int else_
CODE:
{

  BDD bdd;

  CHECK_BDD (if_);
  CHECK_BDD (then_);
  CHECK_BDD (else_);

  bdd = bdd_ite (if_, then_, else_);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int imp(l, r)
   int l
   int r
CODE:
{
  BDD bdd;

  CHECK_BDD (l);
  CHECK_BDD (r);

  bdd = bdd_apply (l, r, bddop_imp);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int biimp(l, r)
   int l
   int r
CODE:
{
  BDD bdd;

  CHECK_BDD (l);
  CHECK_BDD (r);

  bdd = bdd_apply (l, r, bddop_biimp);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int not(bdd)
   int bdd
CODE:
{
  BDD tmp;

  CHECK_BDD (bdd);

  tmp = bdd_not (bdd);
  bdd_addref (tmp);
  RETVAL = tmp;
}
OUTPUT:
RETVAL

int exists(bdd, cube)
   int bdd
   int cube
CODE:
{
  BDD tmp;

  CHECK_BDD (bdd);
  CHECK_BDD (cube);

  tmp = bdd_exist (bdd, cube);
  bdd_addref (tmp);
  RETVAL=tmp;
}
OUTPUT:
RETVAL

int forall(bdd, cube)
   int bdd
   int cube
CODE:
{
  BDD tmp;

  CHECK_BDD (bdd);
  CHECK_BDD (cube);

  tmp = bdd_forall (bdd, cube);
  bdd_addref (tmp);
  RETVAL=tmp;
}
OUTPUT:
RETVAL

int relProd(l, r, cube)
   int l
   int r
   int cube
CODE:
{

  BDD bdd;

  CHECK_BDD (l);
  CHECK_BDD (r);

  bdd = bdd_appex (l, r, bddop_and, cube);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int restrict(r, var)
   int r
   int var
CODE:
{
  BDD bdd;

  CHECK_BDD (r);
  CHECK_BDD (var);

  bdd = bdd_restrict (r, var);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

int constrain(f, c)
   int f
   int c
CODE:
{
  BDD bdd;

  CHECK_BDD (f);
  CHECK_BDD (c);

  bdd = bdd_constrain (f, c);
  bdd_addref (bdd);
  RETVAL=bdd;
}
OUTPUT:
RETVAL

long createPairI(old, new_,size)
   AV *old
   AV *new_
   int size
CODE:
{
  int *oldarr = malloc(size*sizeof(int));
  int *newarr = malloc(size*sizeof(int));
  int i;
  long pair;

  for (i=0; i<size; i++) {
    SV** elem = av_fetch(old, i, 0);
    oldarr[i] = SvNV(*elem);
  }

  for (i=0; i<size; i++) {
    SV** elem = av_fetch(new_, i, 0);
    newarr[i] = SvNV(*elem);
  }

  pair = createPair(oldarr, newarr, size);

  free(newarr);
  free(oldarr);

  RETVAL=pair;
}
OUTPUT:
RETVAL

void deletePair(pair)
    long pair
PPCODE:
{

  bdd_freepair ((bddPair *) pair);
}

int replace(bdd, pair)
   int bdd
   long pair
CODE:
{
  BDD tmp;

  CHECK_BDD (bdd);

  tmp = bdd_replace (bdd, (bddPair *) pair);
  bdd_addref (tmp);
  RETVAL=tmp;
}
OUTPUT:
RETVAL

void showPair(pair)
   int pair
PPCODE:
{
  printf ("(function not supported, yet)\n");
}

int support(bdd)
   int bdd
CODE:
{
  BDD tmp;

  CHECK_BDD (bdd);

  tmp = bdd_support (bdd);
  bdd_addref (tmp);
  RETVAL=tmp;
}
OUTPUT:
RETVAL

int nodeCount(bdd)
   int bdd
CODE:
{
  CHECK_BDD (bdd);

  RETVAL=bdd_nodecount (bdd);
}
OUTPUT:
RETVAL

int satOne(bdd)
   int bdd
CODE:
{
  BDD tmp;
  CHECK_BDD (bdd);

  tmp = bdd_satone (bdd);
  bdd_addref (tmp);
  RETVAL=tmp;
}
OUTPUT:
RETVAL

double satCount__I(bdd)
   int bdd
CODE:
 {
  double div, sat;

  CHECK_BDD (bdd);

  // See init for a explaination about 2 + varnum...
  div = pow (2, 2 + varnum);

  sat = bdd_satcount (bdd);
  // fprintf(stderr, "sat = %lf, div = %lf or 2^%ld\n", sat, div, ( 2 +
  // varnum));

  sat /= div;

  RETVAL=sat;
}
OUTPUT:
RETVAL

double satCount__II(bdd, vars_ignored)
   int bdd
   int vars_ignored
CODE:    
{

  CHECK_BDD (bdd);

  // see init ...
//
//  RETVAL=(double) bdd_satcount (bdd) / pow (2,
//				     2 + varnum + 2 * vars_ignored);
//

  RETVAL=(double) bdd_satcount (bdd) / pow(2, 2 + varnum + vars_ignored);
}
OUTPUT:
RETVAL

void gc()
PPCODE:
{
  bdd_gbc ();
}

void printDot__I(bdd)
   int bdd
PPCODE:
{

  CHECK_BDD (bdd);

  bdd_printdot (bdd);
  printf ("\n");
}

void printDot__II(bdd, filename)
   int bdd
   char *filename
PPCODE:
{
  CHECK_BDD (bdd);
  bdd_fnprintdot (filename, bdd);
}

void print(bdd)
   int bdd
PPCODE:
{

  CHECK_BDD (bdd);

  bdd_printtable (bdd);
  printf ("\n");
  fflush (stdout);
}

void printStats()
PPCODE:
{
  bdd_printstat ();
}

int checkPackage()
CODE:
{
  RETVAL=(checkBuddy () ? 1 : 0);
}
OUTPUT:
RETVAL

void debugPackage()
PPCODE:
{
  IGNORE_CALL;
}

int internal_refcount(bdd)
   int bdd
CODE:
{

  CHECK_BDD (bdd);

  RETVAL=(bddnodes[bdd].refcou);
}
OUTPUT:	
RETVAL

int internal_isconst(bdd)
   int bdd
CODE:
{

  CHECK_BDD (bdd);

  RETVAL=(bdd == bddfalse) || (bdd == bddtrue);
}
OUTPUT:
RETVAL

int internal_constvalue(bdd)
   int bdd
CODE:
{

  CHECK_BDD (bdd);

  if (bdd == bddfalse)
    RETVAL=0;
  else
    RETVAL=1;
}
OUTPUT:
RETVAL

int internal_iscomplemented(bdd)
   int bdd
CODE:
{
  CHECK_BDD (bdd);

  RETVAL=0;	// no CE in BuDDy
}
OUTPUT:
RETVAL

int internal_then(bdd)
   int bdd
CODE:
{
  CHECK_BDD (bdd);

  RETVAL=bdd_high (bdd);
}
OUTPUT:
RETVAL

int internal_else(bdd)
   int bdd
CODE:
{
  CHECK_BDD (bdd);

  RETVAL=bdd_low (bdd);
}
OUTPUT:
RETVAL

void verbose(verb_)
   int verb_
PPCODE:
{
	// NOT IMPLEMENTED!
}

int makeSetI(vars, size)
   AV *vars
   int size
CODE:
{
  int *varsarr = malloc((av_len(vars)+1)*sizeof(int));
  int i;

  for (i=0; i<=av_len(vars); i++) {
    SV** elem = av_fetch(vars, i, 0);
    varsarr[i] = SvNV(*elem);
  }

  RETVAL = makeSet(varsarr, size, 0);
}
OUTPUT:
RETVAL

int makeSetII(vars, size, offset)
   AV *vars
   int size
   int offset
CODE:
{
  int *varsarr = malloc(av_len(vars)*sizeof(int));
  int i;

  for (i=0; i<=av_len(vars); i++) {
    SV** elem = av_fetch(vars, i, 0);
    varsarr[i] = SvNV(*elem);
  }

  RETVAL = makeSet(varsarr, size, offset);
}
OUTPUT:
RETVAL

int debugBDD(bdd)
   int bdd
CODE:
{

  CHECK_BDD (bdd);

  dumpBDD_info (bdd);
  RETVAL=(checkBDD (bdd) ? 1 : 0);
}
OUTPUT:
RETVAL

void reorder_enableDynamic(enable)
   int enable
PPCODE:
{
  if (enable)
    bdd_enable_reorder ();
  else
    bdd_disable_reorder ();
}
