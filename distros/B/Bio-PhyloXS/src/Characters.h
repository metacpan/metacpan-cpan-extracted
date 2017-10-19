#ifndef CHARACTERS_H
#define CHARACTERS_H

# include "src/TypeSafeData.h"

typedef struct {
	TypeSafeData type;
} Characters;

void initialize_characters(Characters* self);
void destroy_characters(Characters* self);

#endif
