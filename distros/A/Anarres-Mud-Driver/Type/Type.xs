#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "type.h"

/* Apparently we are expected to provide this type as named. */

typedef char *Anarres__Mud__Driver__Compiler__Type;

static HV			*amd_typecache;

	/* These are used as strings and must be allocated. */
static const char T_UNKNOWN[]	= { C_UNKNOWN, 0 };
static const char T_INTEGER[]	= { C_INTEGER, 0 };
static const char T_ARRAY[]	= { C_M_ARRAY, C_UNKNOWN, 0 };
static const char T_MAPPING[]	= { C_M_MAPPING, C_UNKNOWN, 0 };
static const char T_M_CLASS_END[] = { C_M_CLASS_END, 0 };

SV *
amd_type_new(const char *str)
{
	SV      **svp;
	SV		 *sv;
	SV		 *bsv;
	STRLEN	  len;

	len = strlen(str);

	svp = hv_fetch(amd_typecache, str, len, FALSE);
	if (svp)
		return *svp;

	// fprintf(stderr, "Creating new type %s\n", str);

	sv = newSVpvn(str, len);
	bsv = sv_bless(
			newRV_noinc(sv),
					gv_stashpv(_AMD "::Compiler::Type", TRUE));
	hv_store(amd_typecache, str, len, bsv, 0);
	return bsv;
}

#define EXPORT_TYPE(x) do { code[0] = C_ ## x; \
			sv = amd_type_new(code); \
			newCONSTSUB(stash, "T_" #x, sv); \
			av_push(export, newSVpv("T_" #x, strlen(#x) + 2)); \
				} while(0)

#define EXPORT_TYPE_MODIFIER(x) do { code[0] = C_ ## x; \
			newCONSTSUB(stash, "T_" #x, newSVpvn(code, 1)); \
			av_push(export, newSVpv("T_" #x, strlen(#x) + 2)); \
				} while(0)

#define EXPORT_MODIFIER(x) do { \
			newCONSTSUB(stash, #x, newSViv(x)); \
			av_push(export, newSVpv(#x, strlen(#x))); \
				} while(0)

MODULE = Anarres::Mud::Driver::Compiler	PACKAGE = Anarres::Mud::Driver::Compiler

PROTOTYPES: ENABLE

BOOT:
{
	{
		amd_typecache = get_hv(_AMD "::Compiler::Type::CACHE", TRUE);
	}

	{
		HV	*stash;
		AV	*export;
		SV	*sv;
		char code[2];

		// fprintf(stderr, _AMD "::Compiler::Type: Building %%CACHE\n");

		stash = gv_stashpv(_AMD "::Compiler::Type", TRUE);
		export = get_av(_AMD "::Compiler::Type::EXPORT_OK", TRUE);
		code[1] = '\0';

		EXPORT_TYPE(VOID);
		EXPORT_TYPE(NIL);
		EXPORT_TYPE(UNKNOWN);
		EXPORT_TYPE(BOOL);
		EXPORT_TYPE(CLOSURE);
		EXPORT_TYPE(INTEGER);
		EXPORT_TYPE(OBJECT);
		EXPORT_TYPE(STRING);

		EXPORT_TYPE(FAILED);

		sv = amd_type_new(T_ARRAY);
		newCONSTSUB(stash, "T_ARRAY", sv);
		av_push(export, newSVpv("T_ARRAY", strlen("T_ARRAY")));

		sv = amd_type_new(T_MAPPING);
		newCONSTSUB(stash, "T_MAPPING", sv);
		av_push(export, newSVpv("T_MAPPING", strlen("T_MAPPING")));

		EXPORT_TYPE_MODIFIER(M_ARRAY);
		EXPORT_TYPE_MODIFIER(M_MAPPING);
		EXPORT_TYPE_MODIFIER(M_CLASS_BEGIN);
		EXPORT_TYPE_MODIFIER(M_CLASS_MID);
		EXPORT_TYPE_MODIFIER(M_CLASS_END);

	}
	
	{
		HV	*stash;
		AV	*export;

		stash = gv_stashpv(_AMD "::Compiler::Type", TRUE);
		export = get_av(_AMD "::Compiler::Type::EXPORT_OK", TRUE);

		EXPORT_MODIFIER(M_NOMASK);
		EXPORT_MODIFIER(M_NOSAVE);
		EXPORT_MODIFIER(M_STATIC);
		EXPORT_MODIFIER(M_PRIVATE);
		EXPORT_MODIFIER(M_PROTECTED);
		EXPORT_MODIFIER(M_PUBLIC);
		EXPORT_MODIFIER(M_VARARGS);
		EXPORT_MODIFIER(M_EFUN);
		EXPORT_MODIFIER(M_APPLY);
		EXPORT_MODIFIER(M_INHERITED);
		EXPORT_MODIFIER(M_HIDDEN);
		EXPORT_MODIFIER(M_UNKNOWN);
		EXPORT_MODIFIER(M_PURE);
	}
}

MODULE = Anarres::Mud::Driver::Compiler::Type	PACKAGE = Anarres::Mud::Driver::Compiler::Type

SV *
new(self, code)
	SV *	self
	char *	code
	CODE:
		RETVAL = amd_type_new(code);
		/* This is automatically mortalised.
		 * We always have a ref to it through the hash anyway. */
		SvREFCNT_inc(RETVAL);
	OUTPUT:
		RETVAL

void
compatible(self, arg)
	Anarres::Mud::Driver::Compiler::Type	self
	Anarres::Mud::Driver::Compiler::Type	arg
	CODE:
		{
			/* This actually returns a boolean */
			/* Can we assign type 'self' to type 'arg'? */

			if (!*arg)
				croak("arg is not a valid type: it is empty");

			/* TODO: Make two compatible classes with different
			 * names be compatible. */

			while (*self) {
				if (*arg == *self) {
					self++;
					arg++;
					continue;
				}
				else if (*arg == C_UNKNOWN) {
					/* We can assign anything to a mixed. */
					XSRETURN_YES;
				}
				else if (*self == C_NIL) {
					/* We can assign a NIL to anything. */
					XSRETURN_YES;
				}
				else if (*self == C_BOOL && *arg == C_INTEGER) {
					/* We can assign a BOOL to INTEGER */
					XSRETURN_YES;
				}
				else {	/* Including !*arg, which should never happen */
					XSRETURN_NO;
				}
			}

			/* If we get here, then the two types were identical.
			 * However, a class name may be an initial substring of
			 * another class name, therefore we must check identity
			 * here. */
			/* Actually, it can't be since classes are in braces */

			if (*arg)
				XSRETURN_NO;

			XSRETURN_YES;
		}

SV *
unify(self, arg)
	Anarres::Mud::Driver::Compiler::Type	self
	Anarres::Mud::Driver::Compiler::Type	arg
	CODE:
		{
			SV		*out;
			int		 len;
			int		 i;
			char	 incomplete;

			incomplete = 1;	/* We haven't got anything yet */
			for (len = 0; self[len]; len++) {
				if (self[len] != arg[len])
					break;
				else if (self[len] == C_M_MAPPING)
					incomplete = 1;
				else if (self[len] == C_M_ARRAY)
					incomplete = 1;
				else if (self[len] == C_M_CLASS_BEGIN) {
					/* XXX Really, if the two classes are strictly
					 * compatible, either one will do. */
					for (i = len + 1; self[i]; i++) {
						if (self[i] != arg[i]) {
							incomplete = 1;
							goto unify_endloop;
						}
					}
					len = i;
					incomplete = 0;
				}
				else
					incomplete = 0;
			}
unify_endloop:

			/* Now we have to exploit that information. */

			if (!self[len]) {
				/* The two types were equal. */
				out = newSVpvn(self, len);
			}
			else if (self[len] == C_NIL) {
				/* Anything unifies with a 'nil' */
				out = newSVpv(arg, 0);
			}
			else if (arg[len] == C_NIL) {
				/* Anything unifies with a 'nil' */
				out = newSVpv(self, 0);
			}
			else if ((arg[len] == C_BOOL || arg[len] == C_INTEGER) &&
					(self[len] == C_BOOL || self[len] == C_INTEGER)) {
				out = newSVpvn(self, len);
				sv_catpvn(out, T_INTEGER, strlen(T_INTEGER));
			}
			else if (incomplete) {
				out = newSVpvn(self, len);
				sv_catpvn(out, T_UNKNOWN, strlen(T_UNKNOWN));
			}
			else {
				out = newSVpvn(self, len);
			}

			RETVAL = amd_type_new(SvPV_nolen(out));
			SvREFCNT_inc(RETVAL);
			SvREFCNT_dec(out);
		}
	OUTPUT:
		RETVAL
