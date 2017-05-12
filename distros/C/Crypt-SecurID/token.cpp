/*
 * token.cpp - cmdline token emulator, produces a display code
 *
 * $Id: token.cpp,v 1.2 2002/07/04 16:22:29 pliam Exp $
 */

#include <stdlib.h>
#include "securid.h"

int main(void) {
	char sernum[] = "123";
	char file[] = "secretfile.asc";
	SecurID *t = new SecurID();
	if (!t->importToken(file, sernum)) {
		printf("Error: %s\n", t->error());
		exit(EXIT_FAILURE);
	}
	printf("%s\n", t->code());
	exit(EXIT_SUCCESS);
}
