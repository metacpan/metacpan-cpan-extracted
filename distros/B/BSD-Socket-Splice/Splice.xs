#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/socket.h>

MODULE = BSD::Socket::Splice		PACKAGE = BSD::Socket::Splice

SV *
setsplice(PerlIO *so, ...)
    PREINIT:
	PerlIO *sosp;
	struct splice sp;
	double max, idle;
	void *optval;
	socklen_t optlen;
	int fd;
    CODE:
	bzero(&sp, sizeof(sp));
	optval = &sp;
	optlen = sizeof(sp);
	fd = PerlIO_fileno(so);
	if (items <= 1) {
		sp.sp_fd = -1;
	} else {
		sosp = IoIFP(sv_2io(ST(1)));
		sp.sp_fd = PerlIO_fileno(sosp);
	}
	if (items <= 2) {
		/* use simplified syscall interface */
		optval = &sp.sp_fd;
		optlen = sizeof(sp.sp_fd);
	}
	if (items >= 3) {
		if (SvUOK(ST(2))) {
			sp.sp_max = SvUV(ST(2));
		} else if (SvIOK(ST(2))) {
			sp.sp_max = SvIV(ST(2));
		} else if (SvNOK(ST(2))) {
			max = floor(SvNV(ST(2)));
			sp.sp_max = (off_t)max;
			if ((double)sp.sp_max != max) {
				errno = EINVAL;
				XSRETURN_UNDEF;
			}
		} else if (SvOK(ST(2))) {
			croak("Non numeric max value for setsplice");
		}
		if (sp.sp_max < 0) {
			errno = EINVAL;
			XSRETURN_UNDEF;
		}
	}
	if (items >= 4) {
		if (SvUOK(ST(3))) {
			sp.sp_idle.tv_sec = SvUV(ST(3));
		} else if (SvIOK(ST(3))) {
			sp.sp_idle.tv_sec = SvIV(ST(3));
		} else if (SvNOK(ST(3))) {
			idle = SvNV(ST(3));
			sp.sp_idle.tv_sec = (long)floor(idle);
			idle -= (double)sp.sp_idle.tv_sec;
			if (fabs(idle) >= 1.) {
				errno = EINVAL;
				XSRETURN_UNDEF;
			}
			sp.sp_idle.tv_usec = (long)floor(1000000 * idle);
		} else if (SvOK(ST(3))) {
			croak("Non numeric idle value for setsplice");
		}
		if (sp.sp_idle.tv_sec < 0 || sp.sp_idle.tv_usec < 0) {
			errno = EINVAL;
			XSRETURN_UNDEF;
		}
		optval = &sp;
		optlen = sizeof(sp);
	}
	if (items >= 5) {
		croak("Too many arguments for setsplice");
	}
	if (setsockopt(fd, SOL_SOCKET, SO_SPLICE, optval, optlen) == -1)
		XSRETURN_UNDEF;
	XSRETURN_YES;

SV *
getsplice(PerlIO *so)
    PREINIT:
	off_t len;
	socklen_t optlen;
	int fd;
    CODE:
	fd = PerlIO_fileno(so);
	optlen = sizeof(len);
	if (getsockopt(fd, SOL_SOCKET, SO_SPLICE, &len, &optlen) == -1)
		XSRETURN_UNDEF;
	if (len < 0) {
		errno = EINVAL;
		XSRETURN_UNDEF;
	}
	RETVAL = newSVuv((UV)len);
	if ((off_t)SvUV(RETVAL) != len) {
		sv_setnv(RETVAL, (double)len);
		if (SvNV(RETVAL) != (double)len) {
			SvREFCNT_dec(RETVAL);
			errno = EINVAL;
			XSRETURN_UNDEF;
		}
	}
    OUTPUT:
	RETVAL

SV *
geterror(PerlIO *so)
    PREINIT:
	socklen_t optlen;
	int fd, error;
    CODE:
	fd = PerlIO_fileno(so);
	optlen = sizeof(error);
	error = 0;
	if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &optlen) == -1)
		XSRETURN_UNDEF;
	RETVAL = newSViv(error);
	errno = error;
    OUTPUT:
	RETVAL

SV *
SO_SPLICE()
    CODE:
	RETVAL = newSVuv(SO_SPLICE);
    OUTPUT:
	RETVAL
