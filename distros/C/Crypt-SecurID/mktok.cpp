/*
 * mktok.cpp - make a secret token file
 *
 * $Id: mktok.cpp,v 1.2 2002/07/05 12:58:01 pliam Exp $
 */

#include <stdlib.h>
#include "securid.h"
int main(void) {
	// char hexkey[] = "c8f1ee9a7c5fd4b3"; that's a weird key
	char hexkey[] = "1e7c9ff7318f3b57";
	char sernum[] = "123";
	char file[] = "secretfile.asc";
	SecurID *t = new SecurID(hexkey);
	if (!t->exportToken(file, sernum)) {
		printf("Error: %s\n", t->error());
		exit(EXIT_FAILURE);
	}
	exit(EXIT_SUCCESS);
}
