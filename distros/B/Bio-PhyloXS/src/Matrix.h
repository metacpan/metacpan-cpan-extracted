#ifndef MATRIX_H
#define MATRIX_H

# include "src/TypeSafeData.h"
# include "src/Characters.h"

typedef struct {
	TypeSafeData type;
	AV* charlabels;
	AV* statelabels;
	int gapmode;
	char matchchar;
	int polymorphism;
	int respectcase;
	Characters * characters;
} Matrix;

void initialize_matrix(Matrix* self);
void destroy_matrix(Matrix* self);

#endif
