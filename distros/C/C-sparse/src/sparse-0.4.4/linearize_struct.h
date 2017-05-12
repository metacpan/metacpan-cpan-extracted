#ifndef LINEARIZE_STRUCT_H
#define LINEARIZE_STRUCT_H

#include "ptrlist.h"

struct instruction;
DECLARE_PTR_LIST(pseudo_ptr_list, pseudo_t);

struct pseudo_user {
	struct instruction *insn;
	pseudo_t *userp;
};

enum pseudo_type {
	PSEUDO_VOID,
	PSEUDO_REG,
	PSEUDO_SYM,
	PSEUDO_VAL,
	PSEUDO_ARG,
	PSEUDO_PHI,
};

struct pseudo {
	int nr;
	enum pseudo_type type;
	struct pseudo_user_list *users;
	struct ident *ident;
	union {
		struct symbol *sym;
		struct instruction *def;
		long long value;
	};
	void *priv;
};

#endif /* LINEARIZE_H */

