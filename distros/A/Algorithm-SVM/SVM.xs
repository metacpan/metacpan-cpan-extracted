#include <vector>
#include <map>

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

#include "bindings.h"
#include "libsvm.h"

DataSet *_new_dataset(double l) {

  return new DataSet(l);
}

SVM *_new_svm(int st, int kt, int d, double g, double c0, double C,
	      double nu, double e) {

  return new SVM(st, kt, d, g, c0, C, nu, e);
}

MODULE = Algorithm::SVM::DataSet	PACKAGE = Algorithm::SVM::DataSet

DataSet *
_new_dataset(l)
     double l

double
DataSet::_getLabel()
    CODE:
      RETVAL = THIS->getLabel();
    OUTPUT:
      RETVAL

void
DataSet::_setLabel(l)
     double l
    CODE:
      THIS->setLabel(l);

double
DataSet::_getAttribute(k)
     int k
    CODE:
      RETVAL = THIS->getAttribute(k);
    OUTPUT:
      RETVAL

void
DataSet::_setAttribute(k,v)
     int k
     double v
    CODE:
      THIS->setAttribute(k,v);

int
DataSet::_getIndexAt(i)
			int i
		CODE:
			RETVAL = THIS->getIndexAt(i);
		OUTPUT:
			RETVAL

double
DataSet::_getValueAt(i)
			int i
		CODE:
			RETVAL = THIS->getValueAt(i);
		OUTPUT:
			RETVAL

int
DataSet::_getMaxI()
		CODE:
			RETVAL = THIS->getMaxI();
		OUTPUT:
			RETVAL

void
DataSet::DESTROY()

MODULE = Algorithm::SVM			PACKAGE = Algorithm::SVM

SVM *
_new_svm(st,kt,d,g,c0,C,nu,e)
     int st
     int kt
     int d
     double g
     double c0
     double C
     double nu
     double e

void
SVM::_addDataSet(ds)
     DataSet *ds
    CODE:
      THIS->addDataSet(ds);

void
SVM::_clearDataSet()
    CODE:
      THIS->clearDataSet();

int
SVM::_train(retrain)
     int retrain
    CODE:
      RETVAL = THIS->train(retrain);
    OUTPUT:
      RETVAL

double
SVM::_crossValidate(nfolds)
     int nfolds
    CODE:
      RETVAL = THIS->crossValidate(nfolds);
    OUTPUT:
      RETVAL

double
SVM::_predict_value(ds)
     DataSet *ds
    CODE:
      RETVAL = THIS->predict_value(ds);
    OUTPUT:
      RETVAL

double
SVM::_predict(ds)
     DataSet *ds
    CODE:
      RETVAL = THIS->predict(ds);
    OUTPUT:
      RETVAL

int
SVM::_saveModel(filename)
     char *filename
    CODE:
      RETVAL = THIS->saveModel(filename);
    OUTPUT:
      RETVAL

int
SVM::_loadModel(filename)
     char *filename
    CODE:
      RETVAL = THIS->loadModel(filename);
    OUTPUT:
      RETVAL

int
SVM::_getNRClass()
    CODE:
      RETVAL = THIS->getNRClass();
    OUTPUT:
      RETVAL

void
SVM::_getLabels(classes)
     int classes
    PPCODE:
     int i;
     int *labels;
     labels = new int[classes];
     if(THIS->getLabels(labels)) {
       for (i=0;i < classes; i++) {
	  XPUSHs(sv_2mortal(newSViv(labels[i])));
       }
     } else {
       XSRETURN_UNDEF;
     }

double
SVM::_getSVRProbability()
    CODE:
      RETVAL = THIS->getSVRProbability();
    OUTPUT:
      RETVAL

int
SVM::_checkProbabilityModel()
    CODE:
      RETVAL = THIS->checkProbabilityModel();
    OUTPUT:
      RETVAL

void
SVM::_setSVMType(st)
     int st
    CODE:
      THIS->setSVMType(st);

int
SVM::_getSVMType()
    CODE:
      RETVAL = THIS->getSVMType();
    OUTPUT:
      RETVAL

void
SVM::_setKernelType(kt)
     int kt
    CODE:
      THIS->setKernelType(kt);

int
SVM::_getKernelType()
    CODE:
      RETVAL = THIS->getKernelType();
    OUTPUT:
      RETVAL

void
SVM::_setGamma(g)
     double g
    CODE:
      THIS->setGamma(g);

double
SVM::_getGamma()
    CODE:
      RETVAL = THIS->getGamma();
    OUTPUT:
      RETVAL

void
SVM::_setDegree(d)
     int d
    CODE:
      THIS->setDegree(d);

double
SVM::_getDegree()
    CODE:
      RETVAL = THIS->getDegree();
    OUTPUT:
      RETVAL

void
SVM::_setCoef0(c)
     double c
    CODE:
      THIS->setCoef0(c);

double
SVM::_getCoef0()
    CODE:
      RETVAL = THIS->getCoef0();
    OUTPUT:
      RETVAL

void
SVM::_setC(c)
     double c
    CODE:
      THIS->setC(c);

double
SVM::_getC()
    CODE:
      RETVAL = THIS->getC();
    OUTPUT:
      RETVAL

void
SVM::_setNu(n)
     double n
    CODE:
      THIS->setNu(n);

double
SVM::_getNu()
    CODE:
      RETVAL = THIS->getNu();
    OUTPUT:
      RETVAL

void
SVM::_setEpsilon(e)
     double e
    CODE:
      THIS->setEpsilon(e);

double
SVM::_getEpsilon()
    CODE:
      RETVAL = THIS->getEpsilon();
    OUTPUT:
      RETVAL

void
SVM::DESTROY()
