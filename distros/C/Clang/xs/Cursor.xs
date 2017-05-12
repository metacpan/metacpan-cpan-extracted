MODULE = Clang				PACKAGE = Clang::Cursor

CursorKind
kind(self)
	Cursor self

	CODE:
		RETVAL = clang_getCursorKind(*self);

	OUTPUT: RETVAL

Type
type(self)
	Cursor self

	CODE:
		CXType *retval = malloc(sizeof(CXType));
		CXType type = clang_getCursorType(*self);
		*retval = type;
		RETVAL = retval;

	OUTPUT: RETVAL

SV *
spelling(self)
	Cursor self

	CODE:
		CXString spelling = clang_getCursorSpelling(*self);
		RETVAL = newSVpv(clang_getCString(spelling), 0);

	OUTPUT: RETVAL

int
num_arguments(self)
	Cursor self

	CODE:
		int num_arguments  = clang_Cursor_getNumArguments(*self);
		RETVAL = num_arguments;

	OUTPUT: RETVAL

SV *
displayname(self)
	Cursor self

	CODE:
		CXString dname = clang_getCursorDisplayName(*self);
		RETVAL = newSVpv(clang_getCString(dname), 0);

	OUTPUT: RETVAL

AV *
children(self)
	Cursor self

	CODE:
		AV *children = newAV();

		clang_visitChildren(*self, visitor, children);

		RETVAL = children;

	OUTPUT: RETVAL

SV *
is_pure_virtual(self)
	Cursor self

	CODE:
		RETVAL = clang_CXXMethod_isPureVirtual(*self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

SV *
is_virtual(self)
	Cursor self

	CODE:
		RETVAL = clang_CXXMethod_isVirtual(*self) ? &PL_sv_yes : &PL_sv_no;

	OUTPUT: RETVAL

void
location(self)
	Cursor self

	INIT:
		CXFile file;
		const char *filename;
		unsigned int line, line_end, col, col_end, offset;

	PPCODE:
		CXSourceLocation loc = clang_getCursorLocation(*self);

		CXSourceRange range = clang_getCursorExtent(*self);

		CXSourceLocation end = clang_getRangeEnd(range);

		clang_getSpellingLocation(loc, &file, &line, &col, NULL);
		clang_getSpellingLocation(end, NULL, &line_end, &col_end, NULL);

		filename = clang_getCString(clang_getFileName(file));

		if (filename != NULL)
			mXPUSHp(filename, strlen(filename));
		else
			mXPUSHp("", 0);

		mXPUSHi(line);
		mXPUSHi(col);
		mXPUSHi(line_end);
		mXPUSHi(col_end);

SV *
access_specifier(self)
	Cursor self

	CODE:
		enum CX_CXXAccessSpecifier access =
			clang_getCXXAccessSpecifier(*self);

		const char *accessStr = 0;

		switch (access) {
			case CX_CXXInvalidAccessSpecifier:
				accessStr = "invalid";
				break;

			case CX_CXXPublic:
				accessStr = "public";
				break;

			case CX_CXXProtected:
				accessStr = "protected";
				break;

			case CX_CXXPrivate:
				accessStr = "private";
				break;
		}

		RETVAL = newSVpv(accessStr, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	Cursor self

	CODE:
		free(self);
