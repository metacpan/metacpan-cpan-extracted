#ifndef COMPILE_H
#define COMPILE_H

struct symbol;

extern void emit_one_symbol(SCTX_ struct symbol *);
extern void emit_unit_begin(SCTX_ const char *);
extern void emit_unit_end(SCTX);

#endif /* COMPILE_H */
