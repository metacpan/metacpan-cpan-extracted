MODULE = Clang				PACKAGE = Clang::Index

Index
new(class, exclude_decls)
	SV *class
	int exclude_decls

	CODE:
		RETVAL = clang_createIndex(exclude_decls, 0);

	OUTPUT: RETVAL

void
DESTROY(self)
	Index self

	CODE:
		clang_disposeIndex(self);

TUnit
parse(self, file, ...)
	Index self
	SV *file

	CODE:
		const char *path = SvPVbyte_nolen(file);
		TUnit tu = clang_parseTranslationUnit(
			self, path, NULL, 0, NULL, 0, 0
		);

		RETVAL = tu;

	OUTPUT: RETVAL
