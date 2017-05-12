#include "dissect.h"
#include "string.h"
#include "token.h"

static unsigned dotc_stream;

static inline char storage(struct symbol *sym)
{
	int t = sym->type;
	unsigned m = sym->ctype.modifiers;

	if (m & MOD_INLINE || t == SYM_STRUCT || t == SYM_UNION /*|| t == SYM_ENUM*/)
		return sym->pos->pos.stream == dotc_stream ? 's' : 'g';

	return (m & MOD_STATIC) ? 's' : (m & MOD_NONLOCAL) ? 'g' : 'l';
}

static inline const char *show_mode(unsigned mode)
{
	static char str[3];

	if (mode == -1)
		return "def";

#define	U(u_r)	"-rwm"[(mode / u_r) & 3]
	str[0] = U(U_R_AOF);
	str[1] = U(U_R_VAL);
	str[2] = U(U_R_PTR);
#undef	U

	return str;
}

static void print_usage(SCTX_ struct token *pos, struct symbol *sym, unsigned mode)
{
	static unsigned curr_stream = -1;

	if (curr_stream != pos->pos.stream) {
		curr_stream = pos->pos.stream;
		printf("\nFILE: %s\n\n", stream_name(sctx_ curr_stream));
	}

	printf("%s%4d:%-3d %c %-5.3s", sctxp reporter->indent ? "\t" : "",
		pos->pos.line, pos->pos.pos, storage(sym), show_mode(mode));
}

static int isglobal(SCTX_ struct symbol *sym) {
	int t = sym->type;
	unsigned m = sym->ctype.modifiers;

	if (m & MOD_INLINE || t == SYM_STRUCT || t == SYM_UNION /*|| t == SYM_ENUM*/)
		return sym->pos->pos.stream == dotc_stream ? 0 : 1;

	return (m & MOD_STATIC) ? 1 : (m & MOD_NONLOCAL) ? 1 : 0;
}

static int isfunc(SCTX_ struct symbol *sym) {
	if (sym->ctype.base_type && sym->ctype.base_type->type == SYM_FN)
		return 1;
	return 0;
}

static const char *symbol_type_name(enum type type)
{
	static const char *type_name[] = {
		[SYM_UNINITIALIZED] = "SYM_UNINITIALIZED",
		[SYM_PREPROCESSOR] = "SYM_PREPROCESSOR",
		[SYM_BASETYPE] = "SYM_BASETYPE",
		[SYM_NODE] = "SYM_NODE",
		[SYM_PTR] = "SYM_PTR",
		[SYM_FN] = "SYM_FN",
		[SYM_ARRAY] = "SYM_ARRAY",
		[SYM_STRUCT] = "SYM_STRUCT",
		[SYM_UNION] = "SYM_UNION",
		[SYM_ENUM] = "SYM_ENUM",
		[SYM_TYPEDEF] = "SYM_TYPEDEF",
		[SYM_TYPEOF] = "SYM_TYPEOF",
		[SYM_MEMBER] = "SYM_MEMBER",
		[SYM_BITFIELD] = "SYM_BITFIELD",
		[SYM_LABEL] = "SYM_LABEL",
		[SYM_RESTRICT] = "SYM_RESTRICT",
		[SYM_FOULED] = "SYM_FOULED",
		[SYM_KEYWORD] = "SYM_KEYWORD",
		[SYM_BAD] = "SYM_BAD",
	};
	return type_name[type] ?: "UNKNOWN_TYPE";
}

static void r_symbol(SCTX_ unsigned mode, struct token *pos, struct symbol *sym)
{
	char b[512];
	
	if ((!sym->ctype.base_type || sym->ctype.base_type->type != SYM_FN) && !isglobal(sctx_ sym))
	  return;
	
	print_usage(sctx_ pos, sym, mode);

	if (!sym->ident)
		sym->ident = MK_IDENT("__asm__");
	
	memcpy(b, sym->ident->name, sym->ident->len);
	b[sym->ident->len] = 0;
	if (isfunc(sctx_ sym))
		strcat(b, "()");
	
	printf("%s%-32.*s %s 0x%x 0x%p %s\n", sctxp reporter->indent ? "\t" : "",
	       (int)strlen(b), b,
	       show_typename(sctx_ sym->ctype.base_type),
	       (unsigned int )sym->ctype.modifiers, sym, symbol_type_name(sym->type));
}


static void r_member(SCTX_ unsigned mode, struct token *pos, struct symbol *sym, struct symbol *mem)
{
	struct ident *ni, *si, *mi;
	
	return;
	
	print_usage(sctx_ pos, sym, mode);

	ni = MK_IDENT("?");
	si = sym->ident ?: ni;
	/* mem == NULL means entire struct accessed */
	mi = mem ? (mem->ident ?: ni) : MK_IDENT("*");

	printf("%s%.*s.%-*.*s %s 0x%x 0x%p %s\n", sctxp reporter->indent ? "\t" : "",
		si->len, si->name,
		32-1 - si->len, mi->len, mi->name,
	       show_typename(sctx_ mem ? mem->ctype.base_type : sym), 
	       (unsigned int )sym->ctype.modifiers, sym, symbol_type_name(sym->type));
}

static void r_symdef(SCTX_ struct symbol *sym)
{
	if (sym->type == SYM_STRUCT)
		return;
	r_symbol(sctx_ -1, sym->pos, sym);
}

int main(int argc, char **argv)
{
	
	static struct reporter reporter = {
		.r_symdef = r_symdef,
		.r_symbol = r_symbol,
		.r_member = r_member,
	};
	struct string_list *filelist = NULL;
	char *file;
	SPARSE_CTX_INIT;

	sparse_initialize(sctx_ argc, argv, &filelist);

	FOR_EACH_PTR_NOTAG(filelist, file) {
		dotc_stream = sctxp input_stream_nr;
		dissect(sctx_ __sparse(sctx_ file), &reporter);
	} END_FOR_EACH_PTR_NOTAG(file);

	return 0;
}
