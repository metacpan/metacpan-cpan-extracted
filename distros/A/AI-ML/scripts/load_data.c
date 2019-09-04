#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

//https://gist.github.com/spaghetti-source/5620288

typedef struct s_matrix {
        int columns;
        int rows;
        double *values;
} Matrix;

#define NEW_MATRIX(m,r,c)   m=(Matrix*)malloc(sizeof(Matrix));\
                            m->rows = r; m->columns = c;\
                            m->values = (double*) malloc (r * c * sizeof(double));


void endianSwap(unsigned int *x) {
  *x = (*x>>24)|((*x<<8)&0x00FF0000)|((*x>>8)&0x0000FF00)|(*x<<24);
}

Matrix *read_csv(char *path){
  FILE *fimage = fopen(path, "rb");
  unsigned int magic, num, row, col;
  int i, j;
  unsigned char pixel;

  if(fread(&magic, 4, 1, fimage) <= 0) exit(1);
  assert(magic == 0x03080000);

  if(fread(&num, 4, 1, fimage) <= 0) exit(1);
  endianSwap(&num);

  if(fread(&row, 4, 1, fimage) <= 0) exit(1);
  endianSwap(&row);

  if(fread(&col, 4, 1, fimage) <= 0) exit(1);
  endianSwap(&col);
	
  Matrix *matrices;
  int size = row * col;

  NEW_MATRIX(matrices, num, size);
  for(i = 0; i < num * size; i++){
    if(fread(&pixel, 1, 1, fimage) <= 0){
      exit(1);
    }
    //printf("value: %f\n", (double)pixel);
	matrices->values[i] = (double)pixel;
  }
  fclose(fimage);

  return matrices;
}

/*Matrix *read_label_csv(char *path){
	FILE *flabel = fopen(path, "rb");
	unsigned int magic, num;
	unsigned char value;	
	if( fread(&magic, 4, 1, flabel) <= 0) exit(1);
	assert(magic = 0x01080000);
	if( fread(&num, 4, 1, flabel) <= 0) exit(1);
	endianSwap(&num);

	Matrix *m;
	NEW_MATRIX(m, num, 1);
	
	int i;
	for( i = 0; i < num; i++){
		if( fread(&value, 1 , 1, flabel) <= 0 ) exit(1);
		m->values[i] = (float)value;
		//printf("%d\n",value);
	}
	fclose(flabel);
	return m;
}*/

Matrix *read_label_csv(char *path){
	FILE *flabel = fopen(path, "rb");
	unsigned int magic, num;
	unsigned char value;	
	if( fread(&magic, 4, 1, flabel) <= 0) exit(1);
	assert(magic = 0x01080000);
	if( fread(&num, 4, 1, flabel) <= 0) exit(1);
	endianSwap(&num);

	Matrix *m;
	NEW_MATRIX(m, num, 10);
	int i;
	for( i = 0; i < num; i++){
		if( fread(&value, 1 , 1, flabel) <= 0 ) {exit(1);}
        if(i < 10) fprintf(stderr, "%d\n",value);
        m->values[i * m->columns + value] = 1;
		//printf("%d\n",pos);
	}
	fclose(flabel);
	return m;
}

void save(Matrix *m, char *path){
  FILE *f;
  f = fopen(path, "w");

  if(f == NULL) {
    fprintf(stderr, "save: can't create file\n");
    exit(1);
  }
  
    int row, col;
  for( row = 0; row < m->rows; row++ ) {
        for( col = 0; col < m->columns; col++ ) {
            if( col == 0 ) {
                fprintf(f, "%f", (double)m->values[row * m->columns + col]);
            } else {
                fprintf(f, ",%f", (double)m->values[row * m->columns + col]);
            }
        }
        if( row < m->rows ) fprintf(f, "\n");
  }
                 

  fclose(f);
}

void destroy(Matrix *m){
  free(m->values);
  free(m);
}

void print_values(Matrix *m){
    int rows = 10;
    int cols = m->columns;
    for(int i = 0; i < rows; i++){
        for(int j = 0; j < cols; j++){
            fprintf(stderr, "%f\t", m->values[i * cols + j]);
        }
        fprintf(stderr, "\n");
    }
}

int main(int argc, char *argv[]){
    if (argc != 4) {
        fprintf(stderr, "Usage: load <type> input-ubyte output-txt\n");
        fprintf(stderr, "\ttype can be:\n");
        fprintf(stderr, "\t\timages\n");
        fprintf(stderr, "\t\tlabels\n");
        exit(1);
    }

    char *path = argv[2];
    Matrix *m;
    if (strcmp(argv[1], "images") == 0) {
        m = read_csv(path);
    } else if (strcmp(argv[1], "labels") == 0) {
        m = read_label_csv(path);
    } else {
        fprintf(stderr, "Unknown file type: %s\n", argv[1]);
    } 
	save(m, argv[3]);
	destroy(m);

    return 0;
}
