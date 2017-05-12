#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* Standard system headers: */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>

/* Stuff from the SVM Light source: */
/* #include "kernel.h" */
#include "svm_common.h"
#include "svm_learn.h"


#define INITIAL_DOCS 8
#define EXPANSION_FACTOR 2.0

typedef struct {
  long num_features;
  long num_docs;
  long allocated_docs;
  DOC **docs;
  double *labels;
} corpus;

double ranking_callback(DOC **docs, double *rankvalue, long i, long j, LEARN_PARM *learn_parm) {
  dSP;
  SV *callback = (SV *) learn_parm->costfunccustom;
  int count;
  double result;

  /* Don't bother checking the type of 'callback' - it could be a CODE
   * reference or a string, and perl will throw its own error otherwise.
   */

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVnv(rankvalue[i])));
  XPUSHs(sv_2mortal(newSVnv(rankvalue[j])));
  XPUSHs(sv_2mortal(newSVnv(docs[i]->costfactor)));
  XPUSHs(sv_2mortal(newSVnv(docs[j]->costfactor)));
  PUTBACK ;

  count = call_sv(callback, G_SCALAR);
  SPAGAIN;
  if (count != 1)
    croak("Expected 1 return value from ranking callback, but got %d", count);
  result = POPn;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return result;
}


SV **
self_store(SV *self, void *ptr, const char *slot, int make_readonly) {
  HV *self_hash = (HV*) SvRV(self);
  SV **fetched = hv_fetch(self_hash, slot, strlen(slot), 1);
  if (fetched == NULL) croak("Couldn't create the %s slot in $self", slot);
  
  SvREADONLY_off(*fetched);
  sv_setiv(*fetched, (IV) ptr);
  if (make_readonly) SvREADONLY_on(*fetched);
  return fetched;
}

void *
self_fetch(SV *self, const char *slot) {
  HV *self_hash = (HV*) SvRV(self);
  SV **fetched = hv_fetch(self_hash, slot, strlen(slot), 0);
  if (fetched == NULL) croak("Couldn't fetch the %s slot in $self", slot);

  return (void *) SvIV(*fetched);
}

/* Extract the '_corpus' structure out of $self */
corpus *get_corpus (SV *self) {
  return (corpus *) self_fetch(self, "_corpus");
}

/* Convert a SV* containing an arrayref into an AV* */
AV *unpack_aref(SV *input_rv, char *name) {
  if ( !SvROK(input_rv) || SvTYPE(SvRV(input_rv)) != SVt_PVAV ) {
    croak("Argument '%s' must be array reference", name);
  }
  
  return (AV*) SvRV(input_rv);
}

WORD *create_word_array(AV *indices_av, AV *values_av, int *num_words) {
  WORD *words;
  SV **fetched;
  int j, n;

  n = av_len(indices_av)+1;
  if (num_words)
    *num_words = n;

  /* Get the data from the two parallel arrays and put into *words array */
  if (n != av_len(values_av)+1)
    croak("Different number of entries in indices & values arrays");
  
  New(id, words, n+1, WORD);
  for (j=0; j<n; j++) {
    fetched = av_fetch(indices_av, j, 0);
    if (fetched == NULL)
      croak("Missing index for element number %d", j);
    words[j].wnum = SvIV(*fetched);

    if (words[j].wnum <= 0)
      croak("Feature indices must be positive integers");

    if (j>0 && words[j-1].wnum >= words[j].wnum)
      croak("Feature indices must be in strictly increasing order");
    
    fetched = av_fetch(values_av, j, 0);
    if (fetched == NULL)
      croak("Missing value for element number %d", j);
    words[j].weight = (FVAL) SvNV(*fetched);
  }
  words[n].wnum = 0;
  words[n].weight = 0.0;

  return words;
}



MODULE = Algorithm::SVMLight         PACKAGE = Algorithm::SVMLight

PROTOTYPES: ENABLE

void
_xs_init (SV *self)
CODE:
{
  /* Initializes data structures that will be used in the lifetime of $self */
  corpus *c;
  LEARN_PARM *learn_parm;
  KERNEL_PARM *kernel_parm;

  /* Initialize the corpus */
  New(id, c, 1, corpus);
  
  c->num_features = 0;
  c->num_docs = 0;
  New(id, c->docs, INITIAL_DOCS, DOC*);
  New(id, c->labels, INITIAL_DOCS, double);
  c->allocated_docs = INITIAL_DOCS;
  
  self_store(self, c, "_corpus", 1);

  New(id, learn_parm, 1, LEARN_PARM);
  New(id, kernel_parm, 1, KERNEL_PARM);

  self_store(self, learn_parm, "_learn_parm", 1);
  self_store(self, kernel_parm, "_kernel_parm", 1);

  set_learning_defaults(learn_parm, kernel_parm);
  check_learning_parms(learn_parm, kernel_parm);
}

void
ranking_callback (SV *self, SV *callback)
CODE:
{
  LEARN_PARM *learn_parm = (LEARN_PARM*) self_fetch(self, "_learn_parm");
  learn_parm->costfunc = &ranking_callback;
  learn_parm->costfunccustom = newSVsv(callback);
}

void
add_instance_i (SV *self, double label, char *name, SV *indices, SV *values, long query_id = 0, long slack_id = 0, double cost_factor = 1.0)
CODE:
{
  corpus *c = get_corpus(self);
  AV *indices_av = unpack_aref(indices, "indices");
  AV  *values_av = unpack_aref( values,  "values");
  WORD *words;
  int num_words;
  
  words = create_word_array(indices_av, values_av, &num_words);

  if (words[num_words-1].wnum > c->num_features)
    c->num_features = words[num_words-1].wnum;


  /* Check whether we need to allocate more slots for documents */
  if (c->num_docs >= c->allocated_docs) {
    c->allocated_docs *= EXPANSION_FACTOR;
    Renew(c->docs, c->allocated_docs, DOC*);
    if (!(c->docs)) croak("Couldn't allocate more array space for documents");
    Renew(c->labels, c->allocated_docs, double);
    if (!(c->labels)) croak("Couldn't allocate more array space for document labels");
  }

  c->labels[ c->num_docs ] = label;

  c->docs[ c->num_docs ] = create_example( c->num_docs,
					   query_id,
					   slack_id,
					   cost_factor,
					   create_svector(words, name, 1.0) );
  c->num_docs++;
}

void
read_instances (SV *self, char *docfile)
CODE:
{
  corpus *c = get_corpus(self);
  Safefree(c->docs);
  Safefree(c->labels);
  read_documents(docfile, &(c->docs), &(c->labels), &(c->num_features), &(c->num_docs));
}

void
train (SV *self)
CODE:
{
  corpus *c = get_corpus(self);
  MODEL *model;
  double *alpha_in=NULL;
  KERNEL_CACHE *kernel_cache;
  KERNEL_PARM *kernel_parm = (KERNEL_PARM*) self_fetch(self, "_kernel_parm");
  LEARN_PARM *learn_parm = (LEARN_PARM*) self_fetch(self, "_learn_parm");

  /* XXX may need to "restart" alpha_in */
  
  if(kernel_parm->kernel_type == LINEAR) { /* don't need the cache */
    kernel_cache=NULL;
  } else {
    kernel_cache=kernel_cache_init(c->num_docs, learn_parm->kernel_cache_size);
  }

  New(id, model, 1, MODEL);
  
  switch (learn_parm->type) {
  case CLASSIFICATION:
    svm_learn_classification(c->docs, c->labels, c->num_docs, c->num_features, learn_parm,
                             kernel_parm,kernel_cache,model,alpha_in);
    break;
  case REGRESSION:
    svm_learn_regression(c->docs, c->labels, c->num_docs, c->num_features, learn_parm,
                         kernel_parm,&kernel_cache,model);
    break;
  case RANKING:
    svm_learn_ranking(c->docs, c->labels, c->num_docs, c->num_features, learn_parm,
                      kernel_parm,&kernel_cache,model);
    break;
  case OPTIMIZATION:
    svm_learn_optimization(c->docs, c->labels, c->num_docs, c->num_features, learn_parm,
                           kernel_parm,kernel_cache,model,alpha_in);
    break;
  default:
    croak("Unknown learning type '%d'", learn_parm->type);
  }

  if (model->kernel_parm.kernel_type == 0) { /* linear kernel */
    /* compute weight vector */
    add_weight_vector_to_linear_model(model);
  }
  
  /* free(alpha_in); */

  if(kernel_cache) {
    /* Free the memory used for the cache. */
    kernel_cache_cleanup(kernel_cache);
  }

  /* Since the model contains references to the training documents, we
   * can't free up space by freeing the documents.  We could revisit
   * this in a future release if memory becomes tight.
   */
  
  self_store(self, model, "_model", 1);
}

double
predict_i(SV *self, SV *indices, SV *values)
CODE:
{
  MODEL *model = (MODEL*) self_fetch(self, "_model");
  AV *indices_av = unpack_aref(indices, "indices");
  AV  *values_av = unpack_aref( values,  "values");

  WORD *words = create_word_array(indices_av, values_av, NULL);
  DOC *d = create_example(-1, 0, 0, 0.0, create_svector(words, "", 1.0));

  double dist = (model->kernel_parm.kernel_type == 0
		 ? classify_example_linear(model, d)
		 : classify_example(model, d));

  RETVAL = dist;
}
OUTPUT:
  RETVAL

void
_write_model(SV *self, char *modelfile)
CODE:
{
  MODEL *m = (MODEL*) self_fetch(self, "_model");
  write_model(modelfile, m);
}

SV*
get_linear_weights(SV *self)
CODE:
{
  MODEL *m;
  int i;
  AV *result;

  if (!hv_exists((HV*) SvRV(self), "_model", 6))
    croak("Model has not yet been trained");

  m = (MODEL*) self_fetch(self, "_model");
  if (m->kernel_parm.kernel_type != 0)
    croak("Kernel type is not linear");

  result = newAV();
  av_push(result, newSVnv(m->b));

  for (i=1; i<m->totwords+1; i++) {
    av_push(result, newSVnv(m->lin_weights[i]));
  }

  RETVAL = newRV_noinc((SV*) result);
}
OUTPUT:
  RETVAL

void
_read_model(SV *self, char *modelfile)
CODE:
{
  MODEL *m = read_model(modelfile);
  corpus *c = get_corpus(self);

  if (m->kernel_parm.kernel_type == 0) { /* linear kernel */
    /* compute weight vector - it's not stored in the model file */
    add_weight_vector_to_linear_model(m);
  }

  self_store(self, m, "_model", 1);

  /* Fetch a little training info from the model struct */
  c->num_docs = m->totdoc;
  c->num_features = m->totwords;

  /* No actual documents are stored in our corpus - free the memory
     now so DESTROY doesn't get confused later. */
  Safefree(c->docs);
  c->docs = NULL;
}


int
num_features (SV *self)
CODE:
  RETVAL = (get_corpus(self))->num_features;
OUTPUT:
  RETVAL

int
num_instances (SV *self)
CODE:
  RETVAL = (get_corpus(self))->num_docs;
OUTPUT:
  RETVAL


void
DESTROY(SV *self)
CODE:
{
  corpus *c = get_corpus(self);
  MODEL *m;
  int i;

  HV *self_hash = (HV*) SvRV(self);

  if (hv_exists(self_hash, "_model", strlen("_model"))) {
    m = (MODEL*) self_fetch(self, "_model");
    free_model(m, 0);
  }

  if (c->docs != NULL) {
    for(i=0;i<c->num_docs;i++)
      free_example(c->docs[i],1);

    Safefree(c->docs);
  }

  Safefree(c->labels);
  Safefree(c);
}

INCLUDE: param_set.c
