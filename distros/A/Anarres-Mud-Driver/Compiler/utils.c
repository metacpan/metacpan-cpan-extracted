#include "compiler.h"

/* There must be a function to do this already? */
void
amd_require(const char *package)
{
	char	 buf[512];
	char	*rp;
	char	*wp;
	SV		*sv;

	/* Leave space for ".pm" */
	strncpy(buf, package, 509);
	buf[509] = '\0';

	rp = buf;
	wp = buf;
	while (*rp) {
		if (*rp == ':' && *(rp + 1) == ':') {
			*wp++ = '/';
			rp++;
			if (!*rp)
				break;
			rp++;
		}
		else {
			*wp++ = *rp++;
		}
	}
	*wp = '\0';
	strcat(buf, ".pm");

	require_pv(buf);

	sv = get_sv("@", FALSE);
	if (SvTRUE(sv)) {
		croak("Compilation failed in amd_require(%s):\n%s",
						package,
						SvPV_nolen(sv));
	}
}

void
amd_dump(const char *prefix, SV *sv)
{
	dSP;
	int	 count;

	amd_require("Data::Dumper");

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv);
	PUTBACK;
	count = call_pv("Data::Dumper::Dumper", G_SCALAR);
	SPAGAIN;
	if (count != 1)
		croak("Didn't get a return value from Dumper\n");
	printf("%s: %s\n", prefix, POPp);
	fflush(stdout);
	PUTBACK;
	FREETMPS;
	LEAVE;
}

void
amd_peek(const char *prefix, SV *sv)
{
	dSP;
	int	 count;

	amd_require("Devel::Peek");

	printf("Peeking at %s\n", prefix);
	fflush(stdout);

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv);
	PUTBACK;
	count = call_pv("Devel::Peek::Dump", G_DISCARD);
	FREETMPS;
	LEAVE;
}
