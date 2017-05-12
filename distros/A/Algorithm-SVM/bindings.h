#ifndef __BINDINGS_H__
#define __BINDINGS_H__

using namespace std;

#include <vector>
#include <map>
#include <assert.h>

#include "libsvm.h"

class DataSet {
  friend class SVM;

 private:
  double label;
  struct svm_node *attributes;
	int n; int max_n; int max_i;
	bool realigned;
 public:
  DataSet(double l);
  void   setLabel(double l) { label = l; }
  double getLabel() { return label; }
	int getMaxI() { return max_i; }
  void   setAttribute(int k, double v);
  double getAttribute(int k);
	int    getIndexAt(int i) { if (i<=n) { return attributes[i].index; } else { return -1; }}
	double getValueAt(int i) { if (i<=n) { return attributes[i].value; } else { return 0; }}

	void realign(struct svm_node *address);
  ~DataSet();
};


class SVM {
 public:
  SVM(int st, int kt, int d, double g, double c0, double C, double nu,
      double e);
  void   addDataSet(DataSet *ds);
  int    saveModel(char *filename);
  int    loadModel(char *filename);
  void   clearDataSet();
  int    train(int retrain);
  double predict_value(DataSet *ds);
  double predict(DataSet *ds);
	void   free_x_space();
  void   setSVMType(int st) { param.svm_type = st; }
  int    getSVMType() { return param.svm_type; }
  void   setKernelType(int kt) { param.kernel_type = kt; }
  int    getKernelType() { return param.kernel_type; }
  void   setGamma(double g) { param.gamma = g; }
  double getGamma() { return param.gamma; }
  void   setDegree(int d) { param.degree = d; }
  double getDegree() { return param.degree; }
  void   setCoef0(double c) { param.coef0 = c; }
  double getCoef0() { return param.coef0; }
  void   setC(double c) { param.C = c; }
  double getC() { return param.C; }
  void   setNu(double n) { param.nu = n; }
  double getNu() { return param.nu; }
  void   setEpsilon(double e) { param.p = e; }
  double getEpsilon() { return param.p; }
  double crossValidate(int nfolds);
  int    getNRClass();
  int    getLabels(int* label);
  double getSVRProbability();
  int    checkProbabilityModel();

  ~SVM();
 private:
	long   nelem;
  struct svm_parameter param;
  vector<DataSet *> dataset;
  struct svm_problem *prob;
  struct svm_model *model;
	struct svm_node *x_space;
  int randomized;
};

#endif
