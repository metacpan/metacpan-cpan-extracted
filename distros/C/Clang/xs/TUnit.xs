MODULE = Clang				PACKAGE = Clang::TUnit

Cursor
cursor(self)
	TUnit self

	CODE:
		Cursor retval = malloc(sizeof(CXCursor));
		CXCursor cursor = clang_getTranslationUnitCursor(self);
		*retval = cursor;
		RETVAL = retval;

	OUTPUT: RETVAL

SV *
spelling(self)
	TUnit self

	CODE:
		CXString spelling = clang_getTranslationUnitSpelling(self);
		RETVAL = newSVpv(clang_getCString(spelling), 0);

	OUTPUT: RETVAL

AV *
diagnostics(self)
	TUnit self

	CODE:
		AV *diagnostics = newAV();
		unsigned int i, count = clang_getNumDiagnostics(self);

		for (i = 0; i < count; i++) {
			Diagnostic d = clang_getDiagnostic(self, i);
			SV *elem = sv_setref_pv(
				newSV(0), "Clang::Diagnostic", (void *) d
			);

			av_push(diagnostics, elem);
		}

		RETVAL = diagnostics;

	OUTPUT: RETVAL

void
DESTROY(self)
	TUnit self

	CODE:
		clang_disposeTranslationUnit(self);
