#include "ctx.h"
#include "lib.h"
#include "string.h"
#include "allocate.h"
#include "lib.h"
#include "allocate.h"
#include "compat.h"
#include "token.h"
#include "symbol.h"
#include "scope_struct.h"
#include "expression.h"
#include "linearize.h"
#include "storage.h"
#include "sparse-llvm.h"

struct sparse_ctx *sparse_ctx_init(struct sparse_ctx *ctx) {
#ifdef DO_CTX
	struct sparse_ctx *_sctx = ctx;
#endif

	memset(ctx, 0, sizeof(struct sparse_ctx));
	ctx->gcc_major = __GNUC__;
	ctx->gcc_minor = __GNUC_MINOR__;
	ctx->gcc_patchlevel = __GNUC_PATCHLEVEL__;
	ctx->gcc_base_dir = GCC_BASE;
	ctx->max_warnings = 100;
	ctx->show_info = 1;
	ctx->Waddress_space = 1;
	ctx->Wcast_truncate = 1;
	ctx->Wcontext = 1;
	ctx->Wdecl = 1;
	ctx->Wdeclarationafterstatement = -1;
	ctx->Wdesignated_init = 1;
	ctx->Wenum_mismatch = 1;
	ctx->Wnon_pointer_null = 1;
	ctx->Wold_initializer = 1;
	ctx->Wone_bit_signed_bitfield = 1;
	ctx->Wuninitialized = 1;
	ctx->Wvla = 1;
	ctx->arch_m64 = ARCH_M64_DEFAULT;
	ctx->arch_msize_long = 0;

	struct warning warnings[WCNT] = {
	{ "address-space", &ctx-> Waddress_space },
	{ "bitwise", &ctx-> Wbitwise },
	{ "cast-to-as", &ctx-> Wcast_to_as },
	{ "cast-truncate", &ctx-> Wcast_truncate },
	{ "context", &ctx-> Wcontext },
	{ "decl", &ctx-> Wdecl },
	{ "declaration-after-statement", &ctx-> Wdeclarationafterstatement },
	{ "default-bitfield-sign", &ctx-> Wdefault_bitfield_sign },
	{ "designated-init", &ctx-> Wdesignated_init },
	{ "do-while", &ctx-> Wdo_while },
	{ "enum-mismatch", &ctx-> Wenum_mismatch },
	{ "init-cstring", &ctx-> Winit_cstring },
	{ "non-pointer-null", &ctx-> Wnon_pointer_null },
	{ "old-initializer", &ctx-> Wold_initializer },
	{ "one-bit-signed-bitfield", &ctx-> Wone_bit_signed_bitfield },
	{ "paren-string", &ctx-> Wparen_string },
	{ "ptr-subtraction-blows", &ctx-> Wptr_subtraction_blows },
	{ "return-void", &ctx-> Wreturn_void },
	{ "shadow", &ctx-> Wshadow },
	{ "transparent-union", &ctx-> Wtransparent_union },
	{ "typesign", &ctx-> Wtypesign },
	{ "undef", &ctx-> Wundef },
	{ "uninitialized", &ctx-> Wuninitialized },
	{ "vla", &ctx-> Wvla },
	};
	memcpy(ctx->warnings, warnings, sizeof(ctx->warnings));
	
	struct warning debugs[DCNT] = {
	{ "entry", &ctx->dbg_entry},
	{ "dead", &ctx->dbg_dead},
	};
	memcpy(ctx->debugs, debugs, sizeof(ctx->debugs));
	
	/* pre-process.c */
	ctx->includepath[0] = "";
	ctx->includepath[1] = "/usr/include";
	ctx->includepath[2] = "/usr/local/include";
	ctx->includepath[3] =  NULL;
	
	ctx->quote_includepath = ctx->includepath;
	ctx->angle_includepath = ctx->includepath + 1;
	ctx->isys_includepath   = ctx->includepath + 1;
	ctx->sys_includepath   = ctx->includepath + 1;
	ctx->dirafter_includepath = ctx->includepath + 3;

	/* tokenize.c */
	ctx->tabstop = 8;
	memset(ctx->input_stream_hashes,-1,sizeof(ctx->input_stream_hashes));
	
	/* target.c */
	ctx->size_t_ctype = &ctx->uint_ctype;
	ctx->ssize_t_ctype = &ctx->int_ctype;

	ctx-> max_alignment = 16;
	
	ctx-> bits_in_bool = 1;
	ctx-> bits_in_char = 8;
	ctx-> bits_in_short = 16;
	ctx-> bits_in_int = 32;
	ctx-> bits_in_long = 32;
	ctx-> bits_in_longlong = 64;
	ctx-> bits_in_longlonglong = 128;
	
	ctx-> max_int_alignment = 4;
	
	ctx-> bits_in_float = 32;
	ctx-> bits_in_double = 64;
	ctx-> bits_in_longdouble = 80;
	
	ctx-> max_fp_alignment = 8;
	
	ctx-> bits_in_pointer = 32;
	ctx-> pointer_alignment = 4;
	
	ctx-> bits_in_enum = 32;
	ctx-> enum_alignment = 4;

	/* symbol.c */
	sparse_ctx_init_symbols(ctx);

	/* parse.c */
	sparse_ctx_init_parse1(ctx);
	sparse_ctx_init_parse2(ctx);
	sparse_ctx_init_show_parse(ctx);
	
	/* scope.c */
	sparse_ctx_init_scope(ctx);

	/* linearize.c */
	ALLOCATOR_INIT(pseudo_user, "pseudo_user", 0);
	ALLOCATOR_INIT(asm_rules, "asm rules", 0);
	ALLOCATOR_INIT(asm_constraint, "asm constraints", 0);

	/* allocate.c */
	ALLOCATOR_INIT(ident, "identifiers",0);
	ALLOCATOR_INIT(token, "tokens",1);
	ALLOCATOR_INIT(cons, "cons",1);
	ALLOCATOR_INIT(expansion, "expansions",1);
	ALLOCATOR_INIT(sym_context, "sym_contexts",0);
	ALLOCATOR_INIT(symbol, "symbols",0);
	ALLOCATOR_INIT(expression, "expressions",0);
	ALLOCATOR_INIT(statement, "statements",0);
	ALLOCATOR_INIT(string, "strings",0);
	ALLOCATOR_INIT(CString, "CStrings",0);
	ALLOCATOR_INIT(scope, "scopes",0);
	__DO_ALLOCATOR_INIT(void, 0, 1, "bytes", bytes,0);
	ALLOCATOR_INIT(basic_block, "basic_block",0);
	ALLOCATOR_INIT(entrypoint, "entrypoint",0);
	ALLOCATOR_INIT(instruction, "instruction",0);
	ALLOCATOR_INIT(multijmp, "multijmp",0);
	ALLOCATOR_INIT(pseudo, "pseudo",0);

	/* ptrlist.c */
	__ALLOCATOR_INIT(struct ptr_list, "ptr list", ptrlist, 0);

	/* storage.c */
	ALLOCATOR_INIT(storage, "storages", 0);
	ALLOCATOR_INIT(storage_hash, "storage hash", 0);

	/* sparse-llvm.c */
	ALLOCATOR_INIT(llfunc, "llfuncs", 0);

	return ctx;
}
