/*
 * Example test program that just uses the tokenization and
 * preprocessing phases, and prints out the results.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 */
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <fcntl.h>

#include "token.h"
#include "symbol.h"

int main(int argc, char **argv)
{
	struct string_list *filelist = NULL;
	char *file;
	SPARSE_CTX_INIT

	sctxp preprocess_only = 1;
	sparse_initialize(sctx_ argc, argv, &filelist);
	FOR_EACH_PTR_NOTAG(filelist, file) {
		sparse(sctx_ file);
	} END_FOR_EACH_PTR_NOTAG(file);
	show_identifier_stats(sctx);
	return 0;
}
