MODULE = Clang				PACKAGE = Clang::Type

Cursor
declaration(self)
	Type self

	CODE:
		Cursor retval = malloc(sizeof(CXCursor));
		CXCursor cursor  = clang_getTypeDeclaration(*self);
		*retval = cursor;

		RETVAL = retval;

	OUTPUT: RETVAL

TypeKind
kind(self)
	Type self

	CODE:
		RETVAL = self -> kind;

	OUTPUT: RETVAL

SV *
is_const(self)
	Type self

	CODE:
		RETVAL = clang_isConstQualifiedType(*self) ?
			&PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_volatile(self)
	Type self

	CODE:
		RETVAL = clang_isVolatileQualifiedType(*self) ?
			&PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_restrict(self)
	Type self

	CODE:
		RETVAL = clang_isRestrictQualifiedType(*self) ?
			&PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

void
DESTROY(self)
	Type self

	CODE:
		free(self);
