#include "C/config.h"

typedef struct s_matrix{
	int columns;
	int rows;
	REAL *values;
}Matrix;

typedef enum _axis{
	HORIZONTAL = 0,
	VERTICAL = 1
} Axis;

Matrix *sub_matrices(Matrix *A, Matrix *B);

Matrix *mul_matrices(Matrix *A, Matrix *B);

Matrix *div_matrices(Matrix *A, Matrix *B);

Matrix *dot(Matrix *A, Matrix *B, int A_t, int B_t);

Matrix *slice(Matrix *m, int x0, int x1, int y0, int y1);

Matrix *mini_batch(Matrix *m, int start, int size, int axis);
Matrix *sum(Matrix *m, Axis axis);

Matrix *div_matrices(Matrix *A, Matrix *B);

Matrix *broadcasting(Matrix *A, Matrix *B, Axis axis, REAL f(REAL, REAL));

REAL real_mul(REAL a, REAL b);
REAL get_max(Matrix*);
Matrix* matrix_sum(Matrix*, REAL);

REAL real_sub(REAL a, REAL b);

REAL real_sum(REAL a, REAL b);

REAL real_div(REAL a, REAL b);

REAL sigmoid(REAL a, void* v);

REAL ReLU(REAL a, void* v);

REAL d_ReLU(REAL a, void* v);

REAL LReLU(REAL a, void *v);

REAL d_LReLU(REAL a, void *v);

REAL d_sigmoid(REAL a, void* v);

REAL exponential(REAL a, void* v);

Matrix *element_wise(Matrix *m, REAL f(REAL, void*), void* data);

Matrix *matrix_sigmoid(Matrix *m);

Matrix *matrix_ReLU(Matrix *m);

Matrix *matrix_d_ReLU(Matrix *m);

Matrix *matrix_LReLU(Matrix *m, REAL v);

Matrix *matrix_d_LReLU(Matrix *m, REAL v);

Matrix *matrix_softmax(Matrix *m);

Matrix *matrix_d_softmax(Matrix *m);

Matrix *matrix_d_sigmoid(Matrix *m);

Matrix *matrix_tanh(Matrix *m);

Matrix *matrix_d_tanh(Matrix *m);

Matrix *matrix_exp(Matrix *m);

void destroy(Matrix *m);

REAL sigmoid_cost(Matrix *X, Matrix *Y, Matrix *weights);

Matrix *predict_binary_classification(Matrix *m, REAL threshold);

double accuracy(Matrix *y, Matrix *yatt);
double precision(Matrix *y, Matrix *yatt);
double recall(Matrix *y, Matrix *yatt);
double f1(Matrix *y, Matrix *yatt);
#ifdef USE_REAL
void dgemm_ (char*, char*, int*, int*, int*, double*, double*, int*, double*, int*, double*, double*, int*);
#else
void sgemm_ (char*, char*, int*, int*, int*, float*, float*, int*, float*, int*, float*, float*, int*);
#endif
