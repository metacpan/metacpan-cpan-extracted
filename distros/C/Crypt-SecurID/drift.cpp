/*
 * drift.cpp - test drift-measuring mechanism
 *
 * $Id: drift.cpp,v 1.2 2002/07/05 12:58:01 pliam Exp $
 */

#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "securid.h"

int main(void) {
	char key[] = "bdf942057b625f80";
	char code[20];
	long tm;

	SecurID *t = new SecurID(key);

	tm = time(NULL) - 3600; // back 1 hour
	strcpy(code, t->code(tm));
	if (t->validate(code)) {
		printf("Code OK: drift = %ld minutes.\n", t->drift());
		exit(EXIT_SUCCESS);
	}
	else {
		printf("Code NOT ok.\n");
		exit(EXIT_FAILURE);
	}
}
