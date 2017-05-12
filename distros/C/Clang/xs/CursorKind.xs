MODULE = Clang				PACKAGE = Clang::CursorKind

SV *
spelling(self)
	CursorKind self

	CODE:
		CXString spelling = clang_getCursorKindSpelling(self);
		RETVAL = newSVpv(clang_getCString(spelling), 0);

	OUTPUT: RETVAL

SV *
is_declaration(self)
	CursorKind self

	CODE:
		RETVAL = clang_isDeclaration(self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_reference(self)
	CursorKind self

	CODE:
		RETVAL = clang_isReference(self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_expression(self)
	CursorKind self

	CODE:
		RETVAL = clang_isExpression(self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_statement(self)
	CursorKind self

	CODE:
		RETVAL = clang_isStatement(self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_attribute(self)
	CursorKind self

	CODE:
		RETVAL = clang_isAttribute(self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_invalid(self)
	CursorKind self

	CODE:
		RETVAL = clang_isInvalid(self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_tunit(self)
	CursorKind self

	CODE:
		RETVAL = clang_isTranslationUnit(self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_preprocessing(self)
	CursorKind self

	CODE:
		RETVAL = clang_isPreprocessing(self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_unexposed(self)
	CursorKind self

	CODE:
		RETVAL = clang_isUnexposed(self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL
