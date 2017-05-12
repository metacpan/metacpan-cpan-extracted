#ifndef ALLOCATE_H
#define ALLOCATE_H

#include "ctx.h"

#include "allocate_struct.h"

extern void protect_allocations(SCTX_ struct allocator_struct *desc);
extern void drop_all_allocations(SCTX_ struct allocator_struct *desc);
extern void *allocate(SCTX_ struct allocator_struct *desc, unsigned int size);
extern void free_one_entry(SCTX_ struct allocator_struct *desc, void *entry);
extern void show_allocations(SCTX_ struct allocator_struct *);

#define __DECLARE_ALLOCATOR(type, x)		\
	extern type *__alloc_##x(SCTX_ int);		\
	extern void __free_##x(SCTX_ type *);		\
	extern void show_##x##_alloc(SCTX);	\
	extern void clear_##x##_alloc(SCTX);	\
	extern void protect_##x##_alloc(SCTX);
#define DECLARE_ALLOCATOR(x) __DECLARE_ALLOCATOR(struct x, x)


#define __DO_ALLOCATOR(type, objsize, objalign, objname, x, norel)	\
	__DO_ALLOCATOR_DATA(type, objsize, objalign, objname, x, norel) \
	type *__alloc_##x(SCTX_ int extra)			\
	{							\
		return allocate(sctx_ &sctxp x##_allocator, objsize+extra); \
	}							\
	void __free_##x(SCTX_  type *entry)			\
	{							\
		if ((!sctxp x##_allocator.nofree))			\
			free_one_entry(sctx_  &sctxp x##_allocator, entry); \
	}							\
	void show_##x##_alloc(SCTX)				\
	{							\
		show_allocations(sctx_ &sctxp x##_allocator);	\
	}							\
	void clear_##x##_alloc(SCTX)				\
	{							\
		if ((!sctxp x##_allocator.nofree))			\
			drop_all_allocations(sctx_ &sctxp x##_allocator); \
	}							\
	void protect_##x##_alloc(SCTX)				\
	{							\
		protect_allocations(sctx_ &sctxp x##_allocator); \
	}

#define __ALLOCATOR(t, n, x, norel) 					\
	__DO_ALLOCATOR(t, sizeof(t), __alignof__(t), n, x, norel)

#define ALLOCATOR(x, n, norel) __ALLOCATOR(struct x, n, x, norel)

#define __DO_ALLOCATOR_INIT(type, objsize, objalign, objname, x, norel)	\
	__DO_ALLOCATOR_DATA_INIT(type, objsize, objalign, objname, x, norel) \

#define __ALLOCATOR_INIT(t, n, x, norel) 					\
	__DO_ALLOCATOR_INIT(t, sizeof(t), __alignof__(t), n, x, norel)

#define ALLOCATOR_INIT(x, n, norel) __ALLOCATOR_INIT(struct x, n, x, norel)


DECLARE_ALLOCATOR(ident);
DECLARE_ALLOCATOR(token);
DECLARE_ALLOCATOR(pushdown_stack_op);
DECLARE_ALLOCATOR(cons);
DECLARE_ALLOCATOR(expansion);
DECLARE_ALLOCATOR(sym_context);
DECLARE_ALLOCATOR(symbol);
DECLARE_ALLOCATOR(expression);
DECLARE_ALLOCATOR(statement);
DECLARE_ALLOCATOR(string);
DECLARE_ALLOCATOR(CString);
DECLARE_ALLOCATOR(scope);
__DECLARE_ALLOCATOR(void, bytes);
DECLARE_ALLOCATOR(basic_block);
DECLARE_ALLOCATOR(entrypoint);
DECLARE_ALLOCATOR(instruction);
DECLARE_ALLOCATOR(multijmp);
DECLARE_ALLOCATOR(phi);
DECLARE_ALLOCATOR(pseudo);

#endif
