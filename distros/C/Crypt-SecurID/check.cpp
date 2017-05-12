/*
 * check.cpp - validate a code
 *
 * $Id: check.cpp,v 1.2 2002/07/05 12:58:01 pliam Exp $
 */

#include <stdlib.h>
#include "securid.h"

int main(int argc, char *argv[]) {
	char sernum[] = "123";
	char file[] = "secretfile.asc";

    if (argc != 2) {
		printf ("usage: %s %s\n", argv[0], "<token_code>");
		exit(EXIT_FAILURE);
	}

	SecurID *t = new SecurID();
	if (!t->importToken(file, sernum)) {
		printf("Error: %s\n", t->error());
		exit(EXIT_FAILURE);
	}
	if (t->validate(argv[1])) {
		printf("Code OK: drift = %ld.\n", t->drift());
		exit(EXIT_SUCCESS);
	}
	else {
		printf("Code NOT ok.\n");
		exit(EXIT_FAILURE);
	}
}
