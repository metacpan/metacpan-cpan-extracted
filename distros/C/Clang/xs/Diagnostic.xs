MODULE = Clang				PACKAGE = Clang::Diagnostic

SV *
format(self, with_source)
	Diagnostic self
	bool with_source

	CODE:
		unsigned int opts = 0;

		if (with_source) {
			opts = CXDiagnostic_DisplaySourceLocation |
				CXDiagnostic_DisplayColumn;
		}

		CXString fmt = clang_formatDiagnostic(self, opts);

		RETVAL = newSVpv(clang_getCString(fmt), 0);

	OUTPUT: RETVAL

void
location(self)
	Diagnostic self

	INIT:
		CXFile file;
		const char *filename;
		unsigned int line, column, offset;

	PPCODE:
		CXSourceLocation loc = clang_getDiagnosticLocation(self);

		clang_getSpellingLocation(loc, &file, &line, &column, NULL);

		filename = clang_getCString(clang_getFileName(file));

		if (filename != NULL)
			mXPUSHp(filename, strlen(filename));
		else
			mXPUSHp("", 0);

		mXPUSHi(line);
		mXPUSHi(column);

void DESTROY(self)
	Diagnostic self

	CODE:
		clang_disposeDiagnostic(self);
