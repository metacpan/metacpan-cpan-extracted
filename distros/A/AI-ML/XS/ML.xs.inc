#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "C/nn.h"

MODULE = AI::ML 	PACKAGE = AI::ML::Expr

SV *
_sigmoid(a)
	unsigned long a;

	PREINIT:
		Matrix *m;

	CODE:
		m = matrix_sigmoid((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
_tanh(a)
	unsigned long a;

	PREINIT:
		Matrix *m;

	CODE:
		m = matrix_tanh((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);

	OUTPUT:
		RETVAL

SV *
_d_tanh(a)
	unsigned long a;

	PREINIT:
		Matrix *m;

	CODE:
		m = matrix_d_tanh((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);

	OUTPUT:
		RETVAL

SV *
_relu(a)
    	unsigned long a;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_ReLU((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
_d_relu(a)
    	unsigned long a;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_d_ReLU((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
_lrelu(a, v)
    	unsigned long a;
    	REAL v;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_LReLU((Matrix*)a, v);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
_d_lrelu(a, v)
    	unsigned long a;
    	REAL v;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_d_LReLU((Matrix*)a, v);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
_predict_binary_classification(a, v)
    	unsigned long a;
    	REAL v;

	PREINIT:	
		Matrix* m;

	CODE:
		m = predict_binary_classification((Matrix*)a, v);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

		
SV *
_softmax(a)
    	unsigned long a;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_softmax((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
_d_softmax(a)
    	unsigned long a;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_d_softmax((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
        RETVAL

SV *
_d_sigmoid(a)
    	unsigned long a;
    	
	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_d_sigmoid((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:	
		RETVAL

SV *
_sigmoid_cost(x, y, w)
	unsigned long x;
	unsigned long y;
	unsigned long w;

	CODE:
        	RETVAL = newSVnv(sigmoid_cost((Matrix*)x, (Matrix*)y, (Matrix*)w));

	OUTPUT:
		RETVAL


SV *
_mini_batch(m, start, s, axis)
    unsigned long m;
    int start;
    int s;
    int axis;

    PREINIT:
        Matrix* r;

    CODE:
        r = mini_batch((Matrix*)m, start, s, axis);
        RETVAL = newSVnv((unsigned long)r);

    OUTPUT:
        RETVAL

SV *
_accuracy(y, yatt)
	unsigned long y;
	unsigned long yatt;

	CODE:
		RETVAL = newSVnv(accuracy((Matrix*)y, (Matrix*)yatt));
	OUTPUT:
		RETVAL


SV *
_precision(y, yatt)
	unsigned long y;
	unsigned long yatt;

	CODE:
		RETVAL = newSVnv(precision((Matrix*)y, (Matrix*)yatt));
	OUTPUT:
		RETVAL


SV *
_recall(y, yatt)
	unsigned long y;
	unsigned long yatt;

	CODE:
		RETVAL = newSVnv(recall((Matrix*)y, (Matrix*)yatt));
	OUTPUT:
		RETVAL


SV *
_f1(y, yatt)
	unsigned long y;
	unsigned long yatt;

	CODE:
		RETVAL = newSVnv(f1((Matrix*)y, (Matrix*)yatt));
	OUTPUT:
		RETVAL


