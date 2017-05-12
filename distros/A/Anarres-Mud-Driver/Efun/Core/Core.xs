#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

MODULE = Anarres::Mud::Driver::Efun::Core PACKAGE = Anarres::Mud::Driver::Efun::Core

PROTOTYPES: ENABLE

MODULE = Anarres::Mud::Driver::Efun::Core PACKAGE = Anarres::Mud::Driver::Efun::Core::intp

int
invoke(arg)
	SV *	arg
	CODE:
		RETVAL = SvIOKp(arg);	/* Not necessarily the best way? */
	OUTPUT:
		RETVAL

MODULE = Anarres::Mud::Driver::Efun::Core PACKAGE = Anarres::Mud::Driver::Efun::Core::floatp

int
invoke(arg)
	SV *	arg
	CODE:
		RETVAL = SvNOKp(arg);
	OUTPUT:
		RETVAL

MODULE = Anarres::Mud::Driver::Efun::Core PACKAGE = Anarres::Mud::Driver::Efun::Core::stringp

int
invoke(arg)
	SV *	arg
	CODE:
		RETVAL = SvPOKp(arg);
	OUTPUT:
		RETVAL

MODULE = Anarres::Mud::Driver::Efun::Core PACKAGE = Anarres::Mud::Driver::Efun::Core::replace_string

SV *
invoke(big, find, replace)
	char *	big
	char *	find
	char *	replace
	CODE:
		{
			/* This is horribly slow but will do for now. */
			char	*op;
			char	*cp;
			int		 flen;
			int		 rlen;

			flen = strlen(find);
			rlen = strlen(replace);

			RETVAL = sv_2mortal(newSVpvn("", 0));

			op = big;
			cp = strstr(big, find);

			while (cp) {
				sv_catpvn(RETVAL, op, (cp - op));
				sv_catpvn(RETVAL, replace, rlen);
				op = cp + flen;
				cp = strstr(op, find);
			}
			sv_catpv(RETVAL, op);
		}
	OUTPUT:
		RETVAL

MODULE = Anarres::Mud::Driver::Efun::Core PACKAGE = Anarres::Mud::Driver::Efun::Core::explode

SV *
invoke(str, sep)
	char *	str
	char *	sep
	CODE:
		{
			/* Also really inefficient but will do for now. */
			AV		*av;
			SV		*sv;
			char	*cp;
			char	*ep;
			int		 slen;
			int		 i;

			av = newAV();
			slen = strlen(sep);

			if (!slen) {
				slen = strlen(str);
				for (i = 0; i < slen; i++) {
					sv = newSVpvn(str + i, 1);
					av_push(av, sv);
				}
			}
			else {
				cp = str;
				while (*cp) {
					ep = strstr(cp, sep);
					if (ep) {
						sv = newSVpvn(cp, (ep - cp));
						av_push(av, sv);
						cp = ep + slen;
					}
					else {
						sv = newSVpv(cp, 0);
						av_push(av, sv);
						break;
					}
				}
			}

			RETVAL = sv_2mortal(newRV_noinc((SV *)av));
		}
	OUTPUT:
		RETVAL

MODULE = Anarres::Mud::Driver::Efun::Core PACKAGE = Anarres::Mud::Driver::Efun::Core::substr

SV *
invoke(input, start, end, sep, eep)
	SV *	input;
	int		start
	int		end
	int		sep
	int		eep
	CODE:
		{
			char	*str;
			STRLEN	 length;

			str = SvPV(input, length);
			if (sep)
				start = length - start + 1;
			if (eep)
				end = length - end + 1;
			if (start < 0)
				start = 0;
			if (end  < 0)
				end = 0;
			if (start > length)
				start = length;
			if (end > length)
				end = length;
			RETVAL = newSVpvn(str + start, (end - start));
		}
	OUTPUT:
		RETVAL


MODULE = Anarres::Mud::Driver::Efun::Core PACKAGE = Anarres::Mud::Driver::Efun::Core::subchar

SV *
invoke(input, idx, ep)
	SV *	input;
	int		idx
	int		ep
	CODE:
		{
			char	*str;
			STRLEN	 length;

			str = SvPV(input, length);
			if (ep)
				idx = length - idx + 1;
			if (idx < 0)
				idx = 0;
			if (idx > length)
				idx = length;
			RETVAL = newSViv((IV)str[idx]);
		}
	OUTPUT:
		RETVAL

