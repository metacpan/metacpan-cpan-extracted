#include "bindings.h"
#include <errno.h>

#ifdef DEBUG
#include <stdarg.h>
void printf_dbg(const char *a, ...) {
  va_list alist;
	va_start(alist,a);
	vfprintf(stdout,a,alist);
	va_end(alist);
	fflush(NULL);
}
#else
void printf_dbg(const char *a, ...) {}
#endif

DataSet::DataSet(double l) {
  label = l;
	realigned=false;
	n=0;
	max_n=16;
	attributes = (struct svm_node *)malloc(sizeof(struct svm_node) * max_n);
	assert(attributes!=NULL);
	attributes[0].index=-1;  // insert end-of-data marker
	max_i=-1;
}

DataSet::~DataSet() {
  printf_dbg("destructor DS called\n");
	if (realigned) {
		attributes[n].value=-1; // notify svm that dataset is destroyed
	} else {
		free(attributes);
	}
}

void DataSet::realign(struct svm_node *address) {
  assert(address!=NULL);
	memcpy(address,attributes,sizeof(struct svm_node)*(n+1));
  free(attributes); attributes=address;
	max_n=n+1; realigned=true; attributes[n].value=0;
}

void DataSet::setAttribute(int k, double v) {
  if (realigned) {
		printf_dbg("set Attr with realigned k=%d, v=%lf\n",k,v);
		max_n=n+2; attributes[n].value=-1; // notify svm to not care about allocating memory for this dataset
		struct svm_node *address=(struct svm_node *)malloc(sizeof(struct svm_node)*max_n);
		assert(address!=NULL);
		memcpy(address,attributes,sizeof(struct svm_node)*(n+1));
		attributes=address; realigned=false; if (k==-1) { return; }
	} else {
	  printf_dbg("set Attr without realigned k=%d, v=%lf\n",k,v);
	}

  if (k>max_i) {
		max_i=k;
		if (v!=0) {
			attributes[n].index=k;
			attributes[n].value=v; n++; attributes[n].index=-1;
		}
	} else {
    // assume sorted array - check where it belongs
		int upper = n-1; int lower=0; int midpos=0; int midk=-1;
		while (lower<=upper) {
			midpos = (upper+lower)/2;
			midk=attributes[midpos].index;
			if (k>midk) { lower=midpos+1; }
			else if (k<midk) { upper=midpos-1; }
			else { break; }
		}
		if (k==midk) { attributes[midpos].value=v; }
		else {
			if (v!=0) {
				for (int i=n; i>lower; i--) {
					attributes[i].index=attributes[i-1].index;
					attributes[i].value=attributes[i-1].value;
				}
				attributes[lower].index=k;
				attributes[lower].value=v; n++; attributes[n].index=-1;
			}
		}
	}
	if (n>=max_n-1) {
		max_n*=2;
		attributes = (struct svm_node *)realloc(attributes,sizeof(struct svm_node)*max_n);
		assert(attributes!=NULL);
	}
}

double DataSet::getAttribute(int k) {
	int upper = n-1; int lower=0; int midpos=0; int midk=-1;
	while (upper>=lower) {
		midpos = (upper+lower)/2;
		midk=attributes[midpos].index;
		if (k>midk) { lower=midpos+1; }
		else if (k<midk) { upper=midpos-1; }
		else { break; }
	}
	if (k==midk) { return attributes[midpos].value; } else { return 0; }
	return -1;
}


SVM::SVM(int st, int kt, int d, double g, double c0, double C, double nu,
	 double e) {

  // Default parameter settings.
  param.svm_type = st;
  param.kernel_type = kt;
  param.degree = d;
  param.gamma = g;
  param.coef0 = c0;
  param.nu = nu;
  param.cache_size = 40;
  param.C = 1;
  param.eps = 1e-3;
  param.p = e;
  param.shrinking = 1;
  param.nr_weight = 0;
  param.weight_label = NULL;
  param.weight = NULL;
  param.probability = 0;
	nelem=0;
 
  x_space = NULL;	
  model   = NULL;
  prob    = NULL;

  randomized = 0;
}

void SVM::addDataSet(DataSet *ds) {

  if(ds != NULL) dataset.push_back(ds);
}


void SVM::clearDataSet() {
  dataset.clear();
}

void SVM::free_x_space() {
  if (x_space!=NULL) {
		long idx=nelem;
		for (int i=dataset.size()-1; i>=0; i--) {
			assert(x_space[idx-1].index==-1);
			if (x_space[idx-1].value!=-1) {
				printf_dbg((dataset[i]->realigned ? "+" : "-"));
				printf_dbg("%lf\n",x_space[idx-1].value);
			  idx-=((dataset[i]->n)+1);
				dataset[i]->setAttribute(-1,0);
			} else {
				printf_dbg("%d already destroyed or changed.\n",i);
				idx-=2; while (idx >= 0 && x_space[idx].index!=-1) { idx--; }
				idx++;
			}
		}
		assert(idx==0);
		free(x_space); x_space=NULL;
	}
}

int SVM::train(int retrain) {
  const char *error;

  // Free any old model we have.
  if(model != NULL) {
    svm_destroy_model(model);
    model = NULL;
  }

  if(retrain) {
    if(prob == NULL) return 0;
    model = svm_train(prob, &param);
    return 1;
  }

	if (x_space != NULL) free_x_space();
  if(prob != NULL) free(prob);

  model   = NULL;
  prob    = NULL;

  // Allocate memory for the problem struct.
  if((prob = (struct svm_problem *)malloc(sizeof(struct svm_problem))) == NULL) return 0;

  prob->l = dataset.size();

  // Allocate memory for the labels/nodes.
  prob->y = (double *)malloc(sizeof(double) * prob->l);
  prob->x = (struct svm_node **)malloc(sizeof(struct svm_node *) * prob->l);

  if((prob->y == NULL) || (prob->x == NULL)) {
    if(prob->y != NULL) free(prob->y);
    if(prob->x != NULL) free(prob->x);
    free(prob);
    return 0;
  }

  // Check for errors with the parameters.
  error = svm_check_parameter(prob, &param);
  if(error) { free(prob->x); free (prob->y); free(prob); return 0; }

	// Allocate x_space and successively release dataset memory
	// (realigning the dataset memory to x_space)
	nelem=0;
	for (unsigned int i=0; i<dataset.size(); i++) {
		nelem+=dataset[i]->n+1;
  }
	x_space = (struct svm_node *)malloc(sizeof(struct svm_node)*nelem);
	long idx=0;
	for (unsigned int i=0; i<dataset.size(); i++) {
		dataset[i]->realign(x_space+idx);
		idx+=(dataset[i]->n)+1;
	}

	if (x_space==NULL) {
    free(prob->y);
		free(prob->x);
		free(prob);
		nelem=0;
		return 0;
	}

  // Munge the datasets into the format that libsvm expects.
  int maxi = 0; long n=0;
  for(int i = 0; i < prob->l; i++) {
    prob->x[i] = &x_space[n]; //dataset[i]->attributes;
		assert((dataset[i]->attributes)==(&x_space[n]));
		n+=dataset[i]->n+1;
    prob->y[i] = dataset[i]->getLabel();

    if( dataset[i]->max_i > maxi) maxi = dataset[i]->max_i;
  }
	printf_dbg("\nnelem=%ld\n",n);

  if(param.gamma == 0) param.gamma = 1.0/maxi;

  model = svm_train(prob, &param);

  return 1;
}

double SVM::predict_value(DataSet *ds) {
  double pred[100];

  if(ds == NULL) return 0;
 
  svm_predict_values(model, ds->attributes, pred);

  return pred[0];
}


double SVM::predict(DataSet *ds) {
  double pred;

  if(ds == NULL) return 0;
 
  pred = svm_predict(model, ds->attributes);

  return pred;
}

int SVM::saveModel(char *filename) {

  if((model == NULL) || (filename == NULL)) {
    return 0;
  } else {
    return ! svm_save_model(filename, model);
  }
}

int SVM::loadModel(char *filename) {
  struct svm_model *tmodel;

  if(filename == NULL) return 0;

	if(x_space != NULL) {
    free_x_space();
  }

  if(model != NULL) {
    svm_destroy_model(model);
    model = NULL;
  }

  if((tmodel = svm_load_model(filename)) != NULL) {
    model = tmodel;
    return 1;
  }

  return 0;
}

double SVM::crossValidate(int nfolds) {
  double sumv = 0, sumy = 0, sumvv = 0, sumyy = 0, sumvy = 0;
  double total_error = 0;
  int total_correct = 0;
  int i;

  if(! prob) return 0;

  if(! randomized) {
    // random shuffle
    for(i=0;i<prob->l;i++) {
      int j = i+rand()%(prob->l-i);
      struct svm_node *tx;
      double ty;

      tx = prob->x[i];
      prob->x[i] = prob->x[j];
      prob->x[j] = tx;

      ty = prob->y[i];
      prob->y[i] = prob->y[j];
      prob->y[j] = ty;
    }

    randomized = 1;
  }

  for(i=0;i<nfolds;i++) {
    int begin = i*prob->l/nfolds;
    int end = (i+1)*prob->l/nfolds;
    int j,k;
    struct svm_problem subprob;

    subprob.l = prob->l-(end-begin);
    subprob.x = (struct svm_node**)malloc(sizeof(struct svm_node)*subprob.l);
    subprob.y = (double *)malloc(sizeof(double)*subprob.l);

    k=0;
    for(j=0;j<begin;j++) {
      subprob.x[k] = prob->x[j];
      subprob.y[k] = prob->y[j];
      ++k;
    }

    for(j=end;j<prob->l;j++) {
      subprob.x[k] = prob->x[j];
      subprob.y[k] = prob->y[j];
      ++k;
    }

    if(param.svm_type == EPSILON_SVR || param.svm_type == NU_SVR) {
      struct svm_model *submodel = svm_train(&subprob,&param);
      double error = 0;
      for(j=begin;j<end;j++) {
	double v = svm_predict(submodel,prob->x[j]);
	double y = prob->y[j];
	error += (v-y)*(v-y);
	sumv += v;
	sumy += y;
	sumvv += v*v;
	sumyy += y*y;
	sumvy += v*y;
      }
      svm_destroy_model(submodel);
      // cout << "Mean squared error = %g\n", error/(end-begin));
      total_error += error;			
    } else {
      struct svm_model *submodel = svm_train(&subprob,&param);

      int correct = 0;
      for(j=begin;j<end;j++) {
	double v = svm_predict(submodel,prob->x[j]);
	if(v == prob->y[j]) ++correct;
      }
      svm_destroy_model(submodel);
      //cout << "Accuracy = " << 100.0*correct/(end-begin) << " (" <<
      //correct << "/" << (end-begin) << endl;
      total_correct += correct;
    }

    free(subprob.x);
    free(subprob.y);
  }		
  if(param.svm_type == EPSILON_SVR || param.svm_type == NU_SVR) {
    return ((prob->l*sumvy-sumv*sumy)*(prob->l*sumvy-sumv*sumy))/
      ((prob->l*sumvv-sumv*sumv)*(prob->l*sumyy-sumy*sumy));
  } else {
    return 100.0*total_correct/prob->l;
  }
}

int SVM::getNRClass() {

  if(model == NULL) {
    return 0;
  } else {
    return svm_get_nr_class(model);
  }
}

int SVM::getLabels(int* label) {
    if(model == NULL) {
	return 0;
    } else {
	svm_get_labels(model, label);
	return 1;
    }
}

double SVM::getSVRProbability() {

  if((model == NULL) || (svm_check_probability_model(model))) {
    return 0;
  } else {
    return svm_get_svr_probability(model);
  }
}

int SVM::checkProbabilityModel() {

  if(model == NULL) {
    return 0;
  } else {
    return svm_check_probability_model(model);
  }
}

SVM::~SVM() {
	if(x_space!=NULL) { free_x_space(); }
  if(model != NULL) { svm_destroy_model(model); model=NULL; }
  if(prob != NULL) { free(prob); prob=NULL; }
}
