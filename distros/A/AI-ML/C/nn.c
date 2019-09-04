#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "C/nn.h"

#define NEW_MATRIX(t,m,r,c) 	m = (Matrix*)malloc(sizeof(Matrix));\
								m->rows = r; m->columns = c;\
								m->values = (t*)malloc(r*c*sizeof(t));

REAL sigmoid(REAL a, void* v){
	#ifdef USE_REAL
		return (1 / (1 + exp(-a)));
	#else
		return (1 / (1 + expf(-a)));
	#endif
}

REAL d_sigmoid(REAL a, void* v){
	REAL s = sigmoid(a, NULL);
	return s * (1 - s);
}

REAL hyperbolic_tan(REAL a, void* v){
#ifdef USE_REAL
	return tanh(a);
#else
	return tanhf(a); 
#endif
}

REAL d_hyperbolic_tan(REAL a, void* v){
#ifdef USE_REAL
	return (1 - pow(tanh(a),2));
#else
	return (1 - powf(tanhf(a),2)); 
#endif
}


Matrix *matrix_sigmoid(Matrix *m){
	return element_wise(m, sigmoid, NULL);
}

Matrix *matrix_ReLU(Matrix *m){
	return element_wise(m, ReLU, NULL);
}

Matrix *matrix_d_ReLU(Matrix *m){
	return element_wise(m, d_ReLU, NULL);
}

Matrix *matrix_LReLU(Matrix *m, REAL v){
	return element_wise(m, LReLU, &v);
}

Matrix *matrix_d_LReLU(Matrix *m, REAL v){
	return element_wise(m, d_LReLU, &v);
}

REAL ReLU(REAL a, void* v){
	if(a >= 0) return a;
	return 0;
}

REAL d_ReLU(REAL a, void *v){
    if(a < 0) return 0;
    return 1;
}

REAL LReLU(REAL a, void *v){
	if(a >= 0) return a;
	return a * * ((REAL*)v);
}

REAL d_LReLU(REAL a, void *v){
	if(a >= 0) return 1;
	return *((REAL*)v);
}

Matrix *matrix_softmax(Matrix *m){
	Matrix *sm = matrix_sum(m, -get_max(m));
	Matrix *em = matrix_exp(sm);
	Matrix *vm;
	if(m->rows == 1 && m->columns > 1){
			vm = sum(em, HORIZONTAL);
	}
	else if(m->columns == 1 && m->rows > 1){
			vm = sum(em, VERTICAL);
	}
	Matrix *sf = div_matrices(em, vm);
	destroy(sm);
	destroy(vm);
	destroy(em);
	return sf;
}

Matrix *matrix_d_softmax(Matrix *m){
    Matrix *exp = matrix_exp(m);
    Matrix *s = sum(exp, VERTICAL);
    return div_matrices( mul_matrices(exp, sub_matrices(s, exp)) ,s);
} 
    

Matrix *matrix_d_sigmoid(Matrix *m){
    return element_wise(m, d_sigmoid, NULL);
}

Matrix *matrix_tanh(Matrix *m){
	return element_wise(m, hyperbolic_tan, NULL);
}

Matrix *matrix_d_tanh(Matrix *m){
	return element_wise(m, d_hyperbolic_tan, NULL);
}

Matrix *matrix_exp(Matrix *m){
	return element_wise(m, exponential, NULL);
}

REAL sigmoid_cost(Matrix *X, Matrix *Y, Matrix *weights){
	Matrix *h;
	int m, i, size;
	m = Y->rows;
	h = matrix_sigmoid(dot(X,weights,0,0));
	
	//class1 = matrix_mul(mul_matrices(transpose(Y), matrix_log(h)),-1);
	//class2 = mul_matrices(matrix_sum(matrix_mul(Y, -1), 1), matrix_sum(matrix_mul(h, -1), 1));
	
	size = Y->rows * Y->columns;

# ifdef USE_REAL
	double cost = 0;
	for(i = 0; i < size; i++){
		cost += -Y->values[i]*log(h->values[i]) - ( 1 - Y->values[i]) * log(1 - h->values[i]); 
	}
# else
	float cost = 0;
	for(i = 0; i < size; i++){
		cost += -Y->values[i]*logf(h->values[i]) - ( 1 - Y->values[i]) * logf(1 - h->values[i]); 
	}
	
# endif
	return cost/m;
}

Matrix *mini_batch(Matrix *m, int start, int size, int axis){
    Matrix *r;
    int end;
    if(start < 0){
        fprintf(stderr, "start index need to be bigger or equal index 0\n");
        exit(1);
    }
    end = start + size - 1;
    if(axis == 0) // every training example is a column
    {
        if(end >= m->columns){
            fprintf(stderr, "Out of index of columns\n");
            exit(1);
        }
        r = slice(m, -1, -1, start, end);
    }
    else if(axis == 1){
        if(end >= m->rows){
            fprintf(stderr, "Out of index of rows\n");
            exit(1);
        }
        r = slice(m, start, end, -1, -1);
    }
    else{
        fprintf(stderr, "Invalid axis\n");
        exit(1);
    }
    return r;
}

Matrix *predict_binary_classification(Matrix *m, REAL threshold){
	Matrix *yatt;
	int i, rows, cols, size;
	rows = m->rows;
	cols = m->columns;
	size = rows * cols;
	NEW_MATRIX(REAL, yatt, rows, cols);
	for( i = 0; i < size; i++ ){
			//fprintf(stderr, "%f\n", m->values[i]);
			if(m->values[i] >= threshold){
				yatt->values[i] = 1;
			}
			else{
				yatt->values[i] = 0;
			}
		  //fprintf(stderr, "%f -> %f\n", m->values[i], yatt->values[i]);
	}
	return yatt;
}


double accuracy(Matrix *y, Matrix *yatt){
	double total = 0;
	int size = y->columns * y->rows;
	for ( int i = 0; i < size; i++ ){
		if(y->values[i] == yatt->values[i]) total++;
	}
	return (total /size);
}


double precision(Matrix *y, Matrix *yatt){
	double tp = 0, fp = 0;
	int size = y->columns * y->rows;
	for ( int i = 0; i < size; i++ ){
		// Total predicted positive
		if(yatt->values[i] == 1){
			// True positive
			if(y->values[i] == 1) tp++;
			else fp++; // False positive
		}
	}
	return (tp / (tp + fp));
}


double recall(Matrix *y, Matrix *yatt){
	double tp = 0, fn = 0;
	int size = y->columns * y->rows;
	for ( int i = 0; i < size; i++ ){
		//Total actual positive
		if(y->values[i] == 1){
			// True Positive
			if(yatt->values[i] == 1) tp++;
			else fn++; 
		}
	}
	return (tp / (tp + fn));
}


double f1(Matrix *y, Matrix *yatt){
	double prec = precision(y, yatt);
  double rec  = recall(y, yatt);
	double v = 2* ( ( prec * rec ) / ( prec + rec ) );
	return v;	
}
