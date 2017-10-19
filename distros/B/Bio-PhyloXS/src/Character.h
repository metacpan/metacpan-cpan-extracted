#ifndef CHARACTER_H
#define CHARACTER_H

# include "src/TypeSafeData.h"

typedef struct {
	TypeSafeData type;
} Character;

void initialize_character(Character* self);
void destroy_character(Character* self);

#endif
