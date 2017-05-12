#ifndef SCOPE_H
#define SCOPE_H

#include "scope_struct.h"

#ifndef DO_CTX
extern struct scope
		*block_scope,
		*function_scope,
		*file_scope,
		*global_scope;
#endif

static inline int toplevel(SCTX_ struct scope *scope)
{
	return scope == sctxp file_scope || scope == sctxp global_scope;
}

extern void start_file_scope(SCTX);
extern void end_file_scope(SCTX);
extern void new_file_scope(SCTX);

extern void start_symbol_scope(SCTX);
extern void end_symbol_scope(SCTX);

extern void start_function_scope(SCTX);
extern void end_function_scope(SCTX);

extern void bind_scope(SCTX_ struct symbol *, struct scope *);

extern int is_outer_scope(SCTX_ struct scope *);
#endif
