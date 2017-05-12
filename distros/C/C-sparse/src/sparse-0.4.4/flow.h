#ifndef FLOW_H
#define FLOW_H

#include "lib.h"

#ifndef DO_CTX
extern unsigned long bb_generation;
#endif

#define REPEAT_CSE		1
#define REPEAT_SYMBOL_CLEANUP	2

struct entrypoint;
struct instruction;

extern int simplify_flow(SCTX_ struct entrypoint *ep);

extern void simplify_symbol_usage(SCTX_ struct entrypoint *ep);
extern void simplify_memops(SCTX_ struct entrypoint *ep);
extern void pack_basic_blocks(SCTX_ struct entrypoint *ep);

extern void convert_instruction_target(SCTX_ struct instruction *insn, pseudo_t src);
extern void cleanup_and_cse(SCTX_ struct entrypoint *ep);
extern int simplify_instruction(SCTX_ struct instruction *);

extern void kill_bb(SCTX_ struct basic_block *);
extern void kill_use(SCTX_ pseudo_t *);
extern void kill_instruction(SCTX_ struct instruction *);
extern void kill_unreachable_bbs(SCTX_ struct entrypoint *ep);

void check_access(SCTX_ struct instruction *insn);
void convert_load_instruction(SCTX_ struct instruction *, pseudo_t);
void rewrite_load_instruction(SCTX_ struct instruction *, struct pseudo_list *);
int dominates(SCTX_ pseudo_t pseudo, struct instruction *insn, struct instruction *dom, int local);

extern void clear_liveness(SCTX_ struct entrypoint *ep);
extern void track_pseudo_liveness(SCTX_ struct entrypoint *ep);
extern void track_pseudo_death(SCTX_ struct entrypoint *ep);
extern void track_phi_uses(SCTX_ struct instruction *insn);

extern void vrfy_flow(SCTX_ struct entrypoint *ep);
extern int pseudo_in_list(SCTX_ struct pseudo_list *list, pseudo_t pseudo);

#endif
