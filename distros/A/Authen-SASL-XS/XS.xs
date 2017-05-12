=head1 NAME

Authen::SASL::XS	- XS code to glue Perl SASL to Cyrus SASL

=head1 SYNOPSIS

  use Authen::SASL;

  my $sasl = Authen::SASL->new(
         mechanism => 'NAME',
         callback => { NAME => VALUE, NAME => VALUE, ... },
  );

  my $conn = $sasl->client_new(<service>, <server>, <iplocalport>, <ipremoteport>);

  my $conn = $sasl->server_new(<service>, <host>, <iplocalport>, <ipremoteport>);

=head1 DESCRIPTION

SASL is a generic mechanism for authentication used by several
network protocols. B<Authen::SASL::XS> provides an implementation
framework that all protocols should be able to share.

The XS framework makes calls into the existing libsasl.so resp. libsasl2
shared library to perform SASL client connection functionality, including
loading existing shared library mechanisms.

=head1 CONSTRUCTOR

The constructor may be called with or without arguments. Passing arguments is
just a short cut to calling the C<mechanism> and C<callback> methods.

You have to use the C<Authen::SASL> new-constructor to create a SASL object.
The C<Authen::SASL> object then holds all necessary variables and callbacks, which
you gave when creating the object.
C<client_new> and C<server_new> will retrieve needed information from this
object.

=cut


#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef SASL2

#include <sasl/sasl.h>

#else

#include <sasl.h>

#endif

// Debugging stuff

//#define PERL_SASL_DEBUG

#ifdef PERL_SASL_DEBUG
#define _DEBUG(x,...) { printf("DEBUG: %s:%d: ",__FUNCTION__, __LINE__); printf(x, __VA_ARGS__); printf("\n"); }
#define __DEBUG(x) _DEBUG(x,NULL);
#else
#define _DEBUG(x,...)
#define __DEBUG(x)
#endif

#define SASL_IS_SERVER 0
#define SASL_IS_CLIENT 1

struct authensasl {
  sasl_conn_t *conn;
  sasl_callback_t *callbacks;
  int callback_count;

  char *server;
  char *service;
  char *mech;
  char *user;

  int error_code;
  char *additional_errormsg;

  int is_client;
};

typedef struct authensasl * Authen_SASL_XS;

struct _perlcontext {
  SV *func;
  SV *param;
  int intparam;

};

/* Define missing DEFINES, to help programmers avoiding conflict
 * between SASL v1 and v2 libs.
 * Ignore but allow setting callbacks which are lib version depending
 */

#ifdef SASL2

#define SASL_CB_SERVER_GETSECRET (0)
#define SASL_CB_SERVER_PUTSECRET (0)

#else

#define SASL_CB_SERVER_USERDB_CHECKPASS (0)
#define SASL_CB_SERVER_USERDB_SETPASS (0)

#define SASL_CB_CANON_USER (0x8007)

#define SASL_CU_AUTHID  (0x01)
#define SASL_CU_AUTHZID (0x02)

/* Simulation canon_user Callback in SASL1 */
struct _perlcontext *sp_canon = NULL;

#endif


/* Ulrich Pfeifer: Poor man's XPUSH macros for ancient perls. Note that the
 * stack is extended by a constant 1.  That is OK for the uses below, but
 * insufficient in general
 */

#ifndef dXSTARG
#undef XPUSHi
#undef XPUSHp
#define  XPUSHi(A) \
EXTEND(sp,1); \
PUSHs(sv_2mortal(newSViv(A)));
#define XPUSHp(A,B) \
EXTEND(sp,1); \
PUSHs(sv_2mortal(newSVpvn((char *)(A),(STRLEN)(B))));
#endif
#ifndef SvPV_nolen
#define SvPV_nolen(A) SvPV(A,PL_na)
#endif

// internal method for handling errors and their messages
int SetSaslError(Authen_SASL_XS sasl,int code, const char* msg)
{
	if (sasl == NULL)
#ifdef SASL2
		code = SASL_NOTINIT;
#else
		code = SASL_FAIL;
#endif
	else
	{
		_DEBUG("former error: %s, Code: %d",sasl->additional_errormsg,
				sasl->error_code);

		// Do not overwrite Error which are not handled yet, except this one which
		// aren't errors at all
		if (sasl->error_code == SASL_OK ||
			sasl->error_code == SASL_CONTINUE )
		{
			sasl->error_code = code;

			if (sasl->additional_errormsg != NULL)
				free(sasl->additional_errormsg);

			// Is there a message and is it really an error, otherwise ignore message
			if (msg != NULL &&
				code != SASL_OK &&
				code != SASL_CONTINUE)
				sasl->additional_errormsg = strdup(msg);
			else
				sasl->additional_errormsg = NULL;
		}
		_DEBUG("called Error: %s, Code: %d Client: %d",msg,code,sasl->is_client);
		_DEBUG("now Error: %s, Code: %d",sasl->additional_errormsg,sasl->error_code);
	}
	return code;
}

/*
   This is the wrapper function that calls Perl callback functions. The SASL
   library needs a C function to handle callbacks, and this function forms the
   glue to get from the C library back into Perl. The perlcontext is a wrapper
   around the context given to the "callbacks" method. It tells which Perl
   function should be called and what parameter to pass it.
   Different types of callbacks have different "output" parameters to give data
   back to the C library. This function needs to know how to take information
   returned from the Perl callback subroutine and load it back into the output
   parameters for the C library to read.
   Note that if the callback given to the "callbacks" Perl method is really just
   a string or integer, there is no need to jump into a Perl subroutine.
   The value is loaded directly into the output parameters.
*/

/*
	This function executes the perl sub/code and returns the result
	and its length.
*/
int PerlCallbackSub (struct _perlcontext *cp, char **result, STRLEN *len, AV *args)
{
	int rc = SASL_OK;

	int count;
	SV *rsv;

	if (result == NULL)
		return SASL_FAIL;

	if (*result != NULL)
		free(*result);

	if (len == NULL)
		return SASL_FAIL;

	__DEBUG("Callback Callback");

	if (cp->func == NULL) // No perl function given, but a value
	{
		if (cp->param == NULL)
			rc = SASL_FAIL;
		else {
			_DEBUG("PV: %s",SvPV(cp->param,*len));
			*result = strdup(SvPV(cp->param,*len));
		}
	}
	else // Call the perl function
	{
		/* Make a new call stack */
		dSP;
		/* We'll be making temporary perl variables */
		ENTER ;
		SAVETMPS ;

		PUSHMARK(SP);
		if (cp->param)
			XPUSHs( cp->param );

		// Push all other args from Array Args
		if (args != NULL)
			while (av_len(args) >= 0)
				XPUSHs(av_pop(args));
		PUTBACK ;

		count = call_sv(cp->func, G_SCALAR);

		/* Refresh the local stack in case the function played with it */
		SPAGAIN;

		_DEBUG("Count of retvals: %d",count);

		if (count != 1)
			rc = SASL_FAIL;
		else
		{
			rsv = POPs;
			if (SvOK(rsv)) { // we have to check for undef return values
				if ( (*result = strdup(SvPV(rsv, *len))) == NULL)
					rc = SASL_FAIL;
			} else {
				*result = strdup("");
			}
		}
		/* Final cleanup of the stack, since we may've pop'd one */
		PUTBACK ;

		/* Remember to delete temporary variables */
		FREETMPS ;
		LEAVE ;
	}
	return rc;
}

/* This function wraps sasl_getsimple_t function pointers for perl. Name is
   taken from earlier versions, which made no difference between Callback types */
int PerlCallback(void *context, int id, const char **result, unsigned *len)
{
	struct _perlcontext *cp = (struct _perlcontext *) context;
	int rc=SASL_OK;
        STRLEN llen;
	char *c = NULL;

	if (id != SASL_CB_USER &&
		id != SASL_CB_AUTHNAME &&
		id != SASL_CB_LANGUAGE)
	{
		croak("Authen::SASL::XS:  Don't know how to handle callback: %x\n", id);
		rc = -1;
	}
	else
		rc = PerlCallbackSub(cp,&c,&llen,NULL); // Execute PerlCode

	_DEBUG("simple Callback returns: %s %d",c,llen);

	if (rc == SASL_OK)
	{
		if (result != NULL)
			*result = strdup(c);

		if (len != NULL)
			*len = llen;
	}

	if (c != NULL)
		free(c);

	return rc;
}


int PerlCallbackRealm ( void *context, int id, const char **availrealms, const char **result)
{
	struct _perlcontext *cp = (struct _perlcontext *) context;
	int rc = SASL_OK,i;
        STRLEN len;
	char *c = NULL;

	AV *args = newAV();

	// Create the array
	if (availrealms != NULL)
		for (i=0; availrealms[i] != NULL; i++)
		{
			_DEBUG("added available realm: %s",availrealms[i]);
			av_push(args, newSVpv(availrealms[i],0));
		}

	/* HandlePerlStuff */
	rc = PerlCallbackSub(cp,&c,&len,args);

	// Clear the array
	av_clear(args);
	av_undef(args);

	if (rc == SASL_OK)
	{
		if (result != NULL)
			*result = strdup(c);
		else
			rc = -1;
	}

	if (c != NULL)
		free(c);
	return 1;
}

int FillSecret_t(char * p,int len, sasl_secret_t **psecret)
{
	int rc = SASL_OK;
	sasl_secret_t *pass;

	// Allocate sasl password stuff
	pass = (sasl_secret_t *) malloc( len + sizeof(sasl_secret_t) + 1); // 1 for \0
	if (pass == NULL)
		rc=SASL_FAIL;
	else
	{ // and fill it
		_DEBUG("passlen: %d, %s",len,p);
		pass->len = len;
		strncpy( (char *)pass->data,p,len);
		pass->data[len] = '\0';
		_DEBUG("passlen: %d, %s",pass->len,pass->data);
		*psecret = pass;
	}
	return rc;
}

/* This function wraps the sasl_getsecret_t function pointer for perl */
int PerlCallbackSecret (sasl_conn_t *conn, void *context, int id, sasl_secret_t **psecret)
{
	struct _perlcontext *cp = (struct _perlcontext *) context;
	STRLEN len;
        int rc = SASL_OK;
	char *c = NULL;

	/* HandlePerlStuff */
	rc = PerlCallbackSub(cp,&c,&len,NULL);

	if (rc == SASL_OK && psecret != NULL)
	{
		rc = FillSecret_t(c,len,psecret);
	}
	else
		rc = SASL_FAIL;

	if (c != NULL)
		free(c);

	return rc;
}

int PerlCallbackCanonUser(sasl_conn_t *conn, void *context, const char *user, unsigned ulen,
					unsigned flags, const char *user_realm, char *out_user, unsigned out_umax,
					unsigned *out_ulen)
{
	struct _perlcontext *cp = (struct _perlcontext *) context;
	int rc = SASL_OK;
        STRLEN len;
	char *c = NULL;

	AV *args;

	_DEBUG("Enter CanonUser user(%s,%d) user_realm(%s) out_user(%s) out_umax(%d).",user,ulen,user_realm,out_user,out_umax);

	if (!(flags & SASL_CU_AUTHID) && !(flags & SASL_CU_AUTHZID))
		return SASL_BADPARAM;

	args = newAV();

	// Create the parameter array and fill it
	av_push(args, newSVpv(user,ulen));
	av_push(args, newSViv(out_umax));
	av_push(args, newSVpv(user_realm == NULL ? "" : user_realm,0));
	av_push(args, newSVpv(flags & SASL_CU_AUTHID ? "AUTHID" : "AUTHZID" ,0));

	/* HandlePerlStuff */
	rc = PerlCallbackSub(cp,&c,&len,args);

	// Clear the array
	av_clear(args);
	av_undef(args);

	*out_ulen = len > out_umax ? out_umax : len;
	strncpy(out_user,c,*out_ulen);

	if (c != NULL)
		free(c);

	return rc;
}

#ifdef SASL2
/*
	This function wraps the sasl_server_userdb_checkpass_t function pointer for
	perl.
*/
int PerlCallbackServerCheckPass(sasl_conn_t *conn, void *context, const char *user,
	const char *pass, unsigned passlen, struct propctx *propctx)
{
	struct _perlcontext *cp = (struct _perlcontext *) context;
	int rc = SASL_OK;
        STRLEN len;
	char *c = NULL;

	AV *args = newAV();

	// Create the parameter array and fill it
	av_push(args, newSVpv(pass,0));
	av_push(args, newSVpv(user,0));

	_DEBUG("ServerCheckPass %s %s",user,pass);

	/* HandlePerlStuff */
	rc = PerlCallbackSub(cp,&c,&len,args);

	// Clear the array
	av_clear(args);
	av_undef(args);

	rc = strcmp(c,"1") == 0 ? SASL_OK : SASL_FAIL;

	if (c != NULL)
		free(c);

	_DEBUG("Checkpass retval: %d",rc);

	return rc;
}

int PerlCallbackServerSetPass(sasl_conn_t *conn, void *context,
				const char *user, const char *pass,
				unsigned passlen, struct propctx *propctx, unsigned flags)
{
	struct _perlcontext *cp = (struct _perlcontext *) context;
	AV *args = newAV();
	int rc = SASL_OK;
        STRLEN len;
	char *c = NULL;

	_DEBUG("ServerSetPass: %s, %s, %d",user,pass,passlen);

	av_push(args,newSViv(flags));
	if (passlen == 0)
		av_push(args,newSVpv("",0));
	else
		av_push(args,newSVpv(pass,passlen));
	av_push(args,newSVpv(user,0));

	rc = PerlCallbackSub(cp,&c,&len,args);

	av_clear(args);
	av_undef(args);
	_DEBUG("PerlCallback returns: %s,%d",c,rc);
	if (c != NULL)
		free(c);
	return rc;
}

int PerlCallbackAuthorize( sasl_conn_t *conn, void *context,
				const char *requested_user, unsigned rlen,
				const char *auth_identity, unsigned alen,
				const char *def_realm, unsigned urlen,
				struct propctx *propctx )
{
	struct _perlcontext *cp = (struct _perlcontext *) context;
	AV *args = newAV();
	int rc = SASL_OK;
        STRLEN len;
	char *c = NULL;

	_DEBUG("Authorize: %s, %s, %s",auth_identity,requested_user,def_realm);

	// Create the parameter array and fill it
	av_push(args, newSVpv(auth_identity,alen));
	av_push(args, newSVpv(requested_user,rlen));
// av_push(args, newSVpv(def_realm, urlen));

	/* HandlePerlStuff */
	rc = PerlCallbackSub(cp,&c,&len,args);

	// Clear the array
	av_clear(args);
	av_undef(args);

	rc = strcmp(c,"1") == 0 ? SASL_OK : SASL_FAIL;

	if (c != NULL)
		free(c);

	_DEBUG("Authorize: %x",rc);

	return rc;
}

#else

// Callbacks for SASL 1 (from version 1.5.28)

int PerlCallbackCanonUser1( void *context, const char *auth_identity, const char *requested_user,
					const char **user, const char **errstr)
{
	int rc = SASL_OK,len;
	char *c = malloc(sizeof(char) * 256);

	if (c != NULL)
		strcpy(c,"");
	else
		return SASL_FAIL;

	_DEBUG("%s,%s",auth_identity,requested_user);

	if (strcmp(auth_identity,requested_user))
		rc = PerlCallbackCanonUser(NULL,context,requested_user,strlen(requested_user),SASL_CU_AUTHZID,"",c,255,&len);

	rc = PerlCallbackCanonUser(NULL,context,auth_identity,strlen(auth_identity),SASL_CU_AUTHID,"",c,255,&len);

	*user = strdup(c);

	if (c != NULL)
		free(c);

	return rc;
}

int PerlCallbackAuthorize( void *context, const char *auth_identity, const char *requested_user,
					const char **user, const char **errstr)
{
	struct _perlcontext *cp = (struct _perlcontext *) context;
	int rc = SASL_OK;
        STRLEN len;
	AV *args;
	char *c = NULL;

	// SASL1 canonuser workaround
	if (sp_canon != NULL)
	{
		PerlCallbackCanonUser1( sp_canon, auth_identity, requested_user,(const char**) &c, errstr);
		free(c); // Throw away
		c = NULL;
	}

	_DEBUG("Authorize: %s, %s",auth_identity,requested_user);

	args = newAV();
	av_push(args, newSVpv(auth_identity,0));
	av_push(args, newSVpv(requested_user,0));

	rc = PerlCallbackSub(cp,&c,&len,args);

	av_clear(args);
	av_undef(args);

	*user = strndup(c,255);

	if (c != NULL)
		free(c);

	return rc;
}

int PerlCallbackGetSecret( void *context, const char *mechanism, const char *auth_identity,
							const char *realm, sasl_secret_t ** secret)
{
	struct _perlcontext *cp = (struct _perlcontext *) context;
	int rc = SASL_OK;
        STRLEN len;
	AV *args;
	char *c = NULL;

	args = newAV();
	av_push(args, newSVpv(realm,0));
	av_push(args, newSVpv(auth_identity,0));
	av_push(args, newSVpv(mechanism,0));

	rc = PerlCallbackSub(cp,&c,&len,args);

	av_clear(args);
	av_undef(args);

	_DEBUG("GetSecret, %s ,%s ,%s",mechanism,auth_identity,realm);

	if (rc == SASL_OK && c != NULL)
		rc = FillSecret_t(c,len,secret);
	else
		rc = SASL_FAIL;

	_DEBUG("GetSecret, pass: %s, rc: %x",(*secret)->data,rc);

	if (c != NULL)
		free(c);

	return rc;
}

#endif



=pod

=head1 CALLBACKS

Callbacks are very important. It depends on the mechanism which callbacks
have to be set. It is not a failure to set callbacks even they aren't used.
(e.g. password-callback when using GSSAPI or KERBEROS_V4)

The Cyrus-SASL library uses callbacks when the application
needs some information. Common reasons are getting
usernames and passwords.

Authen::SASL::XS allows Cyrus-SASL to use perl-variables and perl-subs
as callback-targets.

Currently Authen::SASL::XS supports the following Callback types:
(for a more detailed description on what the callback type is used for
see the respective man pages)

B<Remark>: All callbacks, which have to return some values (e.g.: **result in
C<sasl_getsimple_t>) do this by returning the value(s). See example below.

=over 4

=item user (client)

=item auth (client)

=item language (client)

This callbacks represent the C<sasl_getsimple_t> from the library.

Input: none

Output: C<username>, C<authname> or C<language>

=item password (client)

=item pass (client)

This callbacks represent the C<sasl_getsecret_t> from the library.

Input: none

Output: C<password>

=item realm <client>

This callback represents the C<sasl_getrealm_t> from the library.

Input: a list of available realms

Output: the chosen realm

(This has nothing to do with GSSAPI or KERBEROS_V4 realm).

=item checkpass (server, SASL v2 only)

This callback represents the C<sasl_server_userdb_checkpass_t> from the
library.

Input: C<username>, C<password>

Output: true or false


=item getsecret (server, SASL v1 only)

This callback represents the C<sasl_server_getsecret_t> from the library. Sasl
will check if the passwords are matching.

Input: C<mechanism>, C<username>, C<default_realm>

Output: C<secret_phrase (password)>

B<Remark>: Programmers that are using should specify both callbacks (getsecret and checkpass).
Then, depending on you Cyrus SASL library either the one or the other is called. Cyrus SASL v1
ignores checkpass and Cyrus SASL v2 ignores getsecret.

=item putsecret (SASL v1) and setpass (SASL v2)

are currently not supported (and won't be, unless someone needs it).

=item canonuser (server/client in SASL v2, server only in SASL v1)

This callback name represents the C<sasl_canon_user_t> from the library.

Input: C<Type of principal>, C<principal>, C<userrealm> and maximal allowed length of the output.

Output: canonicalised C<principal>

C<Type of principal> is "AUTHID" for Authentication ID or "AUTHZID"
for Authorisation ID.

B<Remark>: This callback is ideal to get the username of the user using your service.
If C<Authen::SASL::XS> is linked to Cyrus SASL v1, which doesn't have a canonuser callback,
it will simulate this callback by using the authorize callback internally. Don't worry, the
authorize callback is available anyway.

=item authorize (server)

This callback represents the C<sasl_authorize_t> from the library.

Input: C<authenticated_username>, C<requested_username>, (C<default_realm> SASL v2 only)

Output: C<canonicalised_username> SASL v1 resp. true or false when using SASL v2 lib
There is something TODO, I think.

=item setpass (server, SASL v2 only)

This callback represents the C<sasl_server_userdb_setpass_t> from the library.

Input: C<username>, C<new_password>, C<flags> (0x01 CREATE, 0x02 DISABLE,
0x04 NOPLAIN)

Out: true or false

=back

=head2 Ways to pass a callback

Authen::SASL::XS supports three different ways to pass a callback

=over 4

=item CODEREF

If the value passed is a code reference then, when needed, it will be called.

=item ARRAYREF

If the value passed is an array reference, the first element in the array
must be a code reference. When the callback is called the code reference
will be called with the value from the array passed after.

=item SCALAR
All other values passed will be returned directly to the SASL library
as the answer to the callback.

=back

=head2 Example of setting callbacks

$sasl = new Authen::SASL (
  mechanism => "PLAIN",
    callback => {
      # Scalar
      user => "mannfred",
      pass => $password,
      language => 1,

      # Coderef
      auth => sub { return "klaus", }
      realm => \&getrealm,

      # Arrayref
      canonuser => [ \&canon, $self ],
   }
);

The last example is ideal for using object methods as callback functions.
Then you can do something like this:

sub canon
{
  my ($this,$type,$realm,$maxlen,$user) = @_;
  $this->{_username} = $user if ($type eq "AUTHID");
  return $user;
}

=cut


/* Convert a Perl callback name into a C callback ID */
static
int CallbackNumber(char *name)
{
  if (!strcasecmp(name, "user"))           return(SASL_CB_USER);
  else if (!strcasecmp(name, "username"))  return(SASL_CB_USER);
  else if (!strcasecmp(name, "auth"))      return(SASL_CB_AUTHNAME);
  else if (!strcasecmp(name, "authname"))  return(SASL_CB_AUTHNAME);
  else if (!strcasecmp(name, "language"))  return(SASL_CB_LANGUAGE);
  else if (!strcasecmp(name, "password"))  return(SASL_CB_PASS);
  else if (!strcasecmp(name, "pass"))      return(SASL_CB_PASS);
  else if (!strcasecmp(name, "realm"))     return(SASL_CB_GETREALM);
  else if (!strcasecmp(name, "authorize")) return(SASL_CB_PROXY_POLICY);
  else if (!strcasecmp(name, "canonuser")) return(SASL_CB_CANON_USER);
  else if (!strcasecmp(name, "checkpass")) return(SASL_CB_SERVER_USERDB_CHECKPASS);
  else if (!strcasecmp(name, "setpass"))   return(SASL_CB_SERVER_USERDB_SETPASS);
  else if (!strcasecmp(name, "getsecret")) return(SASL_CB_SERVER_GETSECRET);
  else if (!strcasecmp(name, "putsecret")) return(SASL_CB_SERVER_PUTSECRET);

#ifdef SASL2
  croak("Unknown callback: '%s'. (user|auth|language|pass|realm|checkpass|canonuser|authorize)\n", name);
#else
  croak("Unknown callback: '%s'. (user|auth|language|pass|realm|getsecret|canonuser|authorize)\n", name);
#endif
}

/*
   Fill the passed callback action into the passed Perl/SASL callback. This
   is called either from ExtractParentCallbacks() when the "new" method is
   called, or from callbacks() when that method is called directly.
*/

static
void AddCallback(SV *action, struct _perlcontext *pcb, sasl_callback_t *cb)
{
	__DEBUG("AddCallback");

	if (SvROK(action)) {     /*   user =>  <ref>  */
		__DEBUG("SvROK -> Dereferencing");
		action = SvRV(action);
	}

	pcb->func = NULL;
	pcb->intparam = 0;
	pcb->param = NULL;

	_DEBUG("action type: %d",SvTYPE(action));

	switch (SvTYPE(action)) {
		case SVt_PVCV:	/* user => sub { },  user => \&func */
				pcb->func = action;
				__DEBUG("SVt_PVCV");
			break;

		case SVt_PVAV:	/* user => [ \&func, $param ] */
				pcb->func = av_shift((AV *)action); pcb->param = av_shift((AV *)action);
				_DEBUG("Parametered Callback: %s",SvPV_nolen(pcb->param));
			break;

		case SVt_PV:	/* user => $param */
		case SVt_PVMG:	/* user => $self->{value} */
		case SVt_PVIV:  /* $self->{value} = ""; [...] user => $self->{value} */
				pcb->param = action;
				_DEBUG("SVt- PV PVMG PVIV (%s)",SvPV_nolen(pcb->param));
			break;

		case SVt_IV:	/*  user => 1 */
				pcb->intparam = SvIV(action);
				__DEBUG("SVt_IV");
			break;

		default:
				_DEBUG("Unknown parameter %d %s",SvTYPE(action),SvPV_nolen(action));
				croak("Unknown parameter to %x callback.\n", cb->id);
			break;
	}

	_DEBUG("Callback: %x",cb->id);
	/* Write the C SASL callbacks */
	switch (cb->id)
	{
		case SASL_CB_USER:
		case SASL_CB_AUTHNAME:
		case SASL_CB_LANGUAGE:
				 cb->proc = PerlCallback;
			break;

		case SASL_CB_PASS:
				cb->proc = PerlCallbackSecret;
			break;

		case SASL_CB_GETREALM:
				cb->proc = PerlCallbackRealm;
			break;

		case SASL_CB_ECHOPROMPT:
		case SASL_CB_NOECHOPROMPT:
			break;
		case SASL_CB_PROXY_POLICY:
				cb->proc = PerlCallbackAuthorize;
			break;

		case SASL_CB_CANON_USER:
				cb->proc = PerlCallbackCanonUser;
			break;
#ifdef SASL2
		case SASL_CB_SERVER_USERDB_CHECKPASS:
				cb->proc = PerlCallbackServerCheckPass;
			break;

		case SASL_CB_SERVER_USERDB_SETPASS:
				cb->proc = PerlCallbackServerSetPass;
			break;
#else
		// SASL 1 Servercallbacks:
		case SASL_CB_SERVER_GETSECRET:
				cb->proc = PerlCallbackGetSecret;
			break;
		case SASL_CB_SERVER_PUTSECRET:
				// Not implemented yet maybe TODO, if ever needed
			break;
#endif
		default:
			break;
	}
  cb->context = pcb;
}

/*
 *  Take the callback stored in the parent object and install them into the
 *  current *sasl object.  This is called from the "new" method.
 */

static
void ExtractParentCallbacks(SV *parent, Authen_SASL_XS sasl)
{
	char *key;
	int count=0,i;
	long l;
#ifndef SASL2
	// Missing SASL1 canonuser workaround
	int canon=-1,auth=-1;
#endif
	struct _perlcontext *pcb;
	SV **hashval, *val;
	HV *hash=NULL;
	HE *iter;

	/* Make sure parent is a ref to a hash (with keys like "mechanism"
	and "callback") */
	if (!parent) return;
	if (!SvROK(parent)) return;
	if (SvTYPE(SvRV(parent)) != SVt_PVHV) return;
	hash = (HV *)SvRV(parent);

	/* Get the parent's callbacks */
	hashval = hv_fetch(hash, "callback", 8, 0);
	if (!hashval || !*hashval) return;
	val = *hashval;

	/* Parent's callbacks are another hash (with keys like "user" and "auth") */
	if (!SvROK(val)) return;
	if (SvTYPE(SvRV(val)) != SVt_PVHV) return;
	hash = (HV *)SvRV(val);

	/* Run through all of parent's callback types, counting them
	 * Only valid (non-zero) callbacks are counted.
	 */
	hv_iterinit(hash);
	for (iter=hv_iternext(hash);  iter;  iter=hv_iternext(hash))
	{
		key = hv_iterkey(iter,&l);
		if ((i=CallbackNumber(key))) {
#ifndef SASL2
			// Missing SASL1 canonuser workaround
			if (i == SASL_CB_CANON_USER) canon = count;
			if (i == SASL_CB_PROXY_POLICY) auth = count;
#endif
			count++;
		}
	}

	_DEBUG("Found %d valid callback(s)",count);

	/* Allocate space for the callbacks */
	if (sasl->callbacks) {
		free(sasl->callbacks->context);
		free(sasl->callbacks);
	}
	pcb = (struct _perlcontext *) malloc(count * sizeof(struct _perlcontext));
	if (pcb == NULL)
		croak("Out of memory\n");

	l = (count + 1) * sizeof(sasl_callback_t);
	sasl->callbacks = (sasl_callback_t *)malloc(l);
	if (sasl->callbacks == NULL)
		croak("Out of memory\n");

	memset(sasl->callbacks, 0, l);

	/* Run through all of parent's callback types, fill in the sasl->callbacks
	 * Only valid (non-zero) callbacks will be filled in
	 */
	hv_iterinit(hash);
	count = 0;
	for (iter=hv_iternext(hash);  iter;  iter=hv_iternext(hash)) {
		key = hv_iterkey(iter,&l);
		_DEBUG("Callback %d, %s",count, key);
		if ( (i = CallbackNumber(key))) {
			_DEBUG("Adding Callback %s %d %x.",key,count,i);
			sasl->callbacks[count].id = i;
			val = hv_iterval(hash, iter);
			AddCallback(val, &pcb[count], &sasl->callbacks[count]);
			count++;
		}
		else
			_DEBUG("Ignore Callback %s %d %x.",key,count,i);
	}
	sasl->callbacks[count].id = SASL_CB_LIST_END;
	sasl->callbacks[count].context = pcb;
	sasl->callback_count = count;

#ifndef SASL2
	// Missing-SASL1-canonuser workaround

	// If canon is needed
	if (canon != -1)
	{
		if (auth != -1) // and auth also
			sp_canon = sasl->callbacks[canon].context; // Auth has to call canon
		else
		{
			sasl->callbacks[canon].id = SASL_CB_PROXY_POLICY; // call canon when auth is actually needed
			sasl->callbacks[canon].proc = PerlCallbackCanonUser1;
		}
	}

	_DEBUG("index for auth: %d, index for canon: %d",auth,canon);
#endif

return;
}

#ifdef SASL2
#define SASL_IP_LOCAL 5
#define SASL_IP_REMOTE 6
#endif

static
int PropertyNumber(char *name)
{
  if (!strcasecmp(name, "user"))          return SASL_USERNAME;
  else if (!strcasecmp(name, "ssf"))      return SASL_SSF;
  else if (!strcasecmp(name, "maxout"))   return SASL_MAXOUTBUF;
  else if (!strcasecmp(name, "optctx"))   return SASL_GETOPTCTX;
#ifdef SASL2
  else if (!strcasecmp(name, "realm"))    return SASL_DEFUSERREALM;
  else if (!strcasecmp(name, "iplocalport"))  return SASL_IPLOCALPORT;
  else if (!strcasecmp(name, "ipremoteport"))  return SASL_IPREMOTEPORT;
  else if (!strcasecmp(name, "service"))  return SASL_SERVICE;
  else if (!strcasecmp(name, "serverfqdn"))  return SASL_SERVERFQDN;
  else if (!strcasecmp(name, "authsource"))  return SASL_AUTHSOURCE;
  else if (!strcasecmp(name, "mechname"))  return SASL_MECHNAME;
  else if (!strcasecmp(name, "authuser"))  return SASL_AUTHUSER;
  else if (!strcasecmp(name, "sockname")) return SASL_IP_LOCAL;
  else if (!strcasecmp(name, "peername")) return SASL_IP_REMOTE;
#else
  else if (!strcasecmp(name, "realm"))    return SASL_REALM;
  else if (!strcasecmp(name, "iplocal"))  return SASL_IP_LOCAL;
  else if (!strcasecmp(name, "sockname")) return SASL_IP_LOCAL;
  else if (!strcasecmp(name, "ipremote")) return SASL_IP_REMOTE;
  else if (!strcasecmp(name, "peername")) return SASL_IP_REMOTE;
#endif
#ifdef SASL2
  croak("Unknown SASL property: '%s' (user|ssf|maxout|realm|optctx|iplocalport|ipremoteport|service|serverfqdn|authsource|mechname|authuser)\n", name);
#else
  croak("Unknown SASL property: '%s' (user|ssf|maxout|realm|optctx|sockname|peername)\n", name);
#endif
  return -1;
}


int init_sasl (SV* parent,char* service,char* host, Authen_SASL_XS *sasl,int client)
{
	HV *hash;
	SV **hashval;

	if (sasl == NULL)
		return SASL_FAIL;

	// TODO if struct is already in use and now another type
	if (*sasl != NULL && (*sasl)->is_client != client)
		return SASL_FAIL;

	if (*sasl == NULL)
	{
		// Initialize the given sasl
		*sasl = (Authen_SASL_XS) malloc (sizeof(struct authensasl));
		if (*sasl == NULL)
			croak("Out of memory\n");
		memset(*sasl, 0, sizeof(struct authensasl));
	}

	(*sasl)->is_client = client;
	(*sasl)->additional_errormsg = NULL;
	(*sasl)->error_code = 0;

	if (!host || !*host)
	{
		if (client == SASL_IS_CLIENT)
			SetSaslError((*sasl),SASL_FAIL,"Need a 'hostname' for being a client.");
		(*sasl)->server = NULL; // When server side is needed, NULL forces sasl to lookup the name.
	}
	else
		(*sasl)->server = strdup(host);

	if (!service || !*service)
	{
		SetSaslError((*sasl),SASL_FAIL,"Need a 'service' name.");
		(*sasl)->service = NULL;
	}
	else
		(*sasl)->service = strdup(service);

	/* Extract callback info from the parent object */
	ExtractParentCallbacks(parent, *sasl);

	/* Extract mechanism info from the parent object */
	if (parent && SvROK(parent) && (SvTYPE(SvRV(parent)) == SVt_PVHV))
	{
		hash = (HV *)SvRV(parent);
		hashval = hv_fetch(hash, "mechanism", 9, 0);
		_DEBUG("%d, %d, %s",SvTYPE(*hashval),SVt_PV,SvPV_nolen(*hashval));
		if (hashval  && *hashval && SvTYPE(*hashval) == SVt_PV)
		{
			if ((*sasl)->mech)
				free((*sasl)->mech);
			(*sasl)->mech = strdup(SvPV_nolen(*hashval));
		}
		else
		{
			__DEBUG("Saslmech not recognised:");
		}
	}

	return (*sasl)->error_code;
}

#ifdef SASL2
void set_secprop (Authen_SASL_XS sasl)
{
	sasl_security_properties_t ssp;

	if (sasl == NULL)
		return;

	memset(&ssp, 0, sizeof(ssp));
	ssp.maxbufsize = 0xFFFF;
	ssp.max_ssf = 0xFF;
	sasl_setprop(sasl->conn, SASL_SEC_PROPS, &ssp);
}
#endif



MODULE=Authen::SASL::XS      PACKAGE=Authen::SASL::XS


=head1 Authen::SASL::XS METHODS

=over 4

=item server_new ( SERVICE , HOST = "" , IPLOCALPORT , IPREMOTEPORT )

Constructor for creating server-side sasl contexts.

Creates and returns a new connection object blessed into Authen::SASL::XS.
It is on that returned reference that the following methods are available.
The SERVICE is the name of the service being implemented, which may be used
by the underlying mechanism. An example service therefore is "ldap".

=cut


Authen_SASL_XS
server_new(pkg, parent, service, host = NULL, iplocalport=NULL, ipremoteport=NULL ...)
	char *pkg
	SV *parent
	char *service
	char *host
	char *iplocalport
	char *ipremoteport
	CODE:
	{
/* TODO realm parameter */
		Authen_SASL_XS sasl = NULL;
		int rc;

		if ((rc = init_sasl(parent,service,host,&sasl,SASL_IS_SERVER)) != SASL_OK)
			croak("Saslinit failed. (%x)\n",rc);

		_DEBUG("server_new: Service: %s Server: %s, %s %s %s %s",sasl->service,sasl->server,service,host,iplocalport,ipremoteport);

		if ((rc = sasl_server_init(NULL,sasl->service)) != SASL_OK)
			SetSaslError(sasl,rc,"server_init error.");
#ifdef SASL2
		rc = sasl_server_new(sasl->service, sasl->server, NULL, iplocalport, ipremoteport, sasl->callbacks, 1, &sasl->conn);
#else
		rc = sasl_server_new(sasl->service, sasl->server, NULL, sasl->callbacks, 1, &sasl->conn);
#endif

		if (SetSaslError(sasl,rc,"server_new error.") == SASL_OK)
		{
#ifdef SASL2
			set_secprop(sasl);
#endif
		}
		RETVAL = sasl;
	}
	OUTPUT:
		RETVAL

=pod

=item client_new ( SERVICE , HOST , IPLOCALPORT , IPREMOTEPORT )

Constructor for creating server-side sasl contexts.

Creates and returns a new connection object blessed into Authen::SASL::XS.
It is on that returned reference that the following methods are available.
The SERVICE is the name of the service being implemented, which may be used
by the underlying mechanism. An example service is "ldap". The HOST is the
name of the server being contacted, which may also be used
by the underlying mechanism.

=back

B<Remark>:
This and the C<server_new> function are called by L<Authen::SASL> when using
its C<*_new> function. Since the user has to use Authen::SASL anyway, normally
it is not necessary to call this function directly.

IPLOCALPORT and IPREMOTEPORT arguments are only available, when ASC is
linked against Cyrus SASL 2.x. This arguments are needed for KERBEROS_V4
and CS 2.x on the server side. Don't know if it necessary for the client
side. Format of this arguments in an IPv4 environment should be: a.b.c.d;port.
See sasl_server_new(3) for details.

=over 4

See SYNOPSIS for an example.

=cut

Authen_SASL_XS
client_new(pkg, parent, service, host, iplocalport = NULL, ipremoteport = NULL...)
    char *pkg
    SV *parent
    char *service
    char *host
	char *iplocalport
	char *ipremoteport
  CODE:
  {
	Authen_SASL_XS sasl = NULL;
	int rc;

	if ((rc = init_sasl(parent,service,host,&sasl,SASL_IS_CLIENT)) != SASL_OK)
		croak("Saslinit failed. (%x)\n",rc);

    sasl_client_init(NULL);
	_DEBUG("service: %s, host: %s, mech: %s",sasl->service,sasl->server,sasl->mech);
#ifdef SASL2
    rc = sasl_client_new(sasl->service, sasl->server, iplocalport, ipremoteport, sasl->callbacks, 1, &sasl->conn);
#else
    rc = sasl_client_new(sasl->service, sasl->server, sasl->callbacks, 1, &sasl->conn);
#endif

    if (SetSaslError(sasl,rc,"client_new error.") == SASL_OK)
	{
#ifdef SASL2
		set_secprop(sasl);
#endif
    }
    RETVAL = sasl;
  }
  OUTPUT:
    RETVAL


=pod

=item server_start ( CHALLENGE )

C<server_start> begins the authentication using the chosen mechanism.
If the mechanism is not supported by the installed Cyrus-SASL it fails.
Because for some mechanisms the client has to start the negotiation,
you can give the client challenge as a parameter.

=cut

char *
server_start(sasl,instring=NULL)
	Authen_SASL_XS sasl;
	const char *instring;
	PREINIT:
		int rc;
		unsigned outlen;
                STRLEN inlen;
#ifdef SASL2
		const char *outstring = NULL;
#else
		char *outstring = NULL;
		const char *error =NULL;
#endif

	PPCODE:
		_DEBUG("serverstart mech: %s",sasl->mech);

		if (sasl->error_code)
			XSRETURN_UNDEF;

		if (instring != NULL)
			SvPV(ST(1),inlen);
		else
			inlen = 0;

		_DEBUG("serverstart len: %d",inlen);

		_DEBUG("Server step: %s %d", instring,inlen);
#ifdef SASL2
		rc = sasl_server_start(sasl->conn,sasl->mech, instring, inlen, &outstring, &outlen);
#else
		rc = sasl_server_start(sasl->conn,sasl->mech, instring, inlen, &outstring, &outlen, &error);
#endif
		SetSaslError(sasl,rc,"server_start error."); // SASL_CONTINUE has to be set

		_DEBUG("Server step out: %s %d",outstring, outlen);
		if (rc != SASL_OK && rc != SASL_CONTINUE)
			XSRETURN_UNDEF;
		else // Everything works fine
			XPUSHp(outstring, outlen);

=pod

=item client_start ( )

The initial step to be performed. Returns the initial value to pass to the server.
Client has to start the negotiation always.

=cut

char *
client_start(sasl)
    Authen_SASL_XS sasl
  PREINIT:
	int rc;
	unsigned outlen;
#ifdef SASL2
	const char *outstring;
#else
	char *outstring;
#endif

	const char *mech;
  PPCODE:
		if (sasl->error_code != SASL_OK)
			XSRETURN_UNDEF;

      _DEBUG("mech: %s",sasl->mech);
#ifdef SASL2
      rc = sasl_client_start(sasl->conn, sasl->mech, NULL, &outstring, &outlen, &mech);
#else
      rc = sasl_client_start(sasl->conn, sasl->mech, NULL, NULL, &outstring, &outlen, &mech);
#endif
	  _DEBUG("client_start. error %x, len: %d",rc,outlen);
	  SetSaslError(sasl,rc,"client_start error. (Callbacks?)");
      if (rc != SASL_OK && rc != SASL_CONTINUE)
		XSRETURN_UNDEF;
	  else
	    XPUSHp(outstring, outlen);

=pod

=item server_step ( CHALLENGE )

C<server_step> performs the next step in the negotiation process. The
first parameter you give is the clients challenge/response.

=cut


char *
server_step(sasl, instring)
	Authen_SASL_XS sasl
	char *instring
	PREINIT:
#ifdef SASL2
		const char *outstring=NULL;
#else
		char *outstring=NULL;
		const char *error=NULL;
#endif
		int rc;
		unsigned int outlen=0;
                STRLEN inlen;
	PPCODE:
		if (sasl->error_code != SASL_CONTINUE)
			XSRETURN_UNDEF;

		SvPV(ST(1),inlen);
		_DEBUG("Server step: %s %d", instring,inlen);
#ifdef SASL2
		rc = sasl_server_step(sasl->conn,instring,inlen,&outstring,&outlen);
#else
		rc = sasl_server_step(sasl->conn,instring,inlen,&outstring,&outlen,NULL);
#endif
		// Setting error, if any
		SetSaslError(sasl,rc,"server_step error.");
		// return undef if error, code() will give the truth
		if (rc != SASL_OK && rc != SASL_CONTINUE)
			XSRETURN_UNDEF;
		else
			XPUSHp(outstring, outlen);

=pod

=item client_step ( CHALLENGE )

=back

B<Remark>:
C<client_start>, C<client_step>, C<server_start> and C<server_step>
will return the respective sasl response or undef. The returned value
says nothing about the current negotiation status. It is absolutely possible
that one of these functions return undef and everything is fine for SASL,
there is only another step needed.

Therefore you have to check C<need_step> and C<code> during negotiation.

See example below.

=over 4

=cut


char *
client_step(sasl, instring)
    Authen_SASL_XS sasl
    char *instring
  PPCODE:
  {
#ifdef SASL2
    const char *outstring=NULL;
#else
    char *outstring=NULL;
#endif
    int rc;
    unsigned int outlen=0;
    STRLEN inlen;

    if (sasl->error_code != SASL_CONTINUE)
      XSRETURN_UNDEF;

    SvPV(ST(1),inlen);

	_DEBUG("client_step: inlen: %d",inlen);

    rc = sasl_client_step(sasl->conn, instring, inlen, NULL, &outstring, &outlen);

	SetSaslError(sasl,rc,"client_step.");

	_DEBUG("client_step: error code: %x, len: %d",rc,outlen);
	if (rc != SASL_OK && rc != SASL_CONTINUE)
		XSRETURN_UNDEF;
	else
		XPUSHp(outstring, outlen);
  }

=pod

=item listmech( START , SEPARATOR , END )

C<listmech> returns a string containing all mechanisms allowed for the user
set by C<user>. START is the token which will be put at the beginning of the
string, SEPARATOR is the token which will be used to separate the mechanisms
and END is the token which will be put at the end of returned string.

=cut

char *
listmech(sasl,start="",separator="|",end="")
	Authen_SASL_XS sasl;
	const char* start;
	const char* separator;
	const char* end;
 	PPCODE:
	{
	    int rc;
#ifdef SASL2
	    const char *mechs;
#else
		char *mechs;
#endif
		int mechcount;
	    unsigned mechlen;

		rc = sasl_listmech(sasl->conn,sasl->user,start,separator,end,&mechs,&mechlen,&mechcount);

		if (rc == SASL_OK)
			XPUSHp(mechs,mechlen);
		else
		{
			SetSaslError(sasl,rc,"listmech error.");
			XSRETURN_UNDEF;
		}
	}


#ifdef SASL2

=pod

=item setpass(user, newpassword, oldpassword, flags)

=item checkpass(user, password)

C<setpass> and C<checkpass> is only available when using Cyrus-SASL 2.x library.

C<setpass> sets a new password (depends on the mechanism if the setpass callback
is called). C<checkpass> checks a password for the user (calls the checkpass
callback).

For both function see the man pages of the Cyrus SASL for a detailed description.

Both functions return true on success, false otherwise.

=cut

int
setpass(sasl, user, pass, oldpass, flags=0)
	Authen_SASL_XS sasl;
	const char *user;
	const char *pass;
	const char *oldpass;
	int flags;
PREINIT:
		int rc;
PPCODE:
		_DEBUG("setpass: %s,%s,%s,%d",user,pass,oldpass,flags);
		rc = sasl_setpass (sasl->conn,user,
						pass,strlen(pass),
						oldpass,strlen(oldpass),
						flags);
		XPUSHi(rc);


int checkpass(sasl,user,pass)
	Authen_SASL_XS sasl;
	const char *user;
	const char *pass;
PREINIT:
	int rc;
PPCODE:
	_DEBUG("checkpass: %s,%s",user,pass);
	rc = sasl_checkpass (sasl->conn,
			user, strlen(user),
			pass, strlen(pass));
	XPUSHi(rc);

=pod

=item global_listmech ( )

C<global_listmech> is only available when using Cyrus-SASL 2.x library.

It returns an array with all mechanisms loaded by the library.

=cut


void
global_listmech(sasl)
	Authen_SASL_XS sasl
	PREINIT:
		int i;
		const char **mechs;
	PPCODE:
		if (sasl->error_code)
			XSRETURN_UNDEF;
		mechs = sasl_global_listmech();
		if (mechs)
			for (i = 0; mechs[i]; i++)
				XPUSHs(sv_2mortal(newSVpv(mechs[i],0)));
		else
			XSRETURN_UNDEF;

#endif

=pod

=item encode ( STRING )

=item decode ( STRING )

Cyrus-SASL developers suggest using the C<encode> and C<decode> functions
for every traffic which will run over the network after a successful authentication

C<encode> returns the encrypted string generated from STRING.
C<decode> returns the decrypted string generated from STRING.

It depends on the used mechanism how secure the encryption will be.

=cut

char *
encode(sasl, instring)
    Authen_SASL_XS sasl
    char *instring
  PPCODE:
  {
#ifdef SASL2
    const char *outstring=NULL;
#else
    char *outstring=NULL;
#endif
    int rc;
	unsigned int outlen=0;
        STRLEN inlen;
	if (sasl->error_code)
		XSRETURN_UNDEF;

	instring = SvPV(ST(1),inlen);

	rc = sasl_encode(sasl->conn, instring, inlen, &outstring, &outlen);
    if (SetSaslError(sasl,rc,"sasl_encode failed") != SASL_OK)
		XSRETURN_UNDEF;
	else
	    XPUSHp(outstring, outlen);
  }




char *
decode(sasl, instring)
    Authen_SASL_XS sasl
    char *instring
  PPCODE:
  {
#ifdef SASL2
    const char *outstring=NULL;
#else
    char *outstring=NULL;
#endif
    int rc;
    unsigned int outlen=0;
    STRLEN inlen;

    if (sasl->error_code)
       XSRETURN_UNDEF;

    instring = SvPV(ST(1),inlen);

    rc = sasl_decode(sasl->conn, instring, inlen, &outstring, &outlen);
    if (SetSaslError(sasl,rc,"sasl_decode failed.") != SASL_OK)
		XSRETURN_UNDEF;
	else
	    XPUSHp(outstring, outlen);
  }




int
callback(sasl, ...)
	Authen_SASL_XS sasl
	CODE:
/*
 This function is unnecessary since there is no
 chance for changing callbacks in sasl after (server|
 client)_new function calls. But without calling one
 of these functions (from perl) you do not have an
 object of this class. So you cannot call ->callback.
 At least I was not able to use this function to fill in
 a callback with this function.
 -Patrick
*/
	croak("Deprecated. Don't use, it isn't working anymore.");
		RETVAL = 0;
	OUTPUT:
		RETVAL

=pod

=item error ( )

C<error> returns an array with all known error messages.
Basicly the sasl_errstring function is called with the current error_code.
When using Cyrus-SASL 2.x library also the string returned by sasl_errdetail
is given back. Additionally the special Authen::SASL::XS advise is
returned if set.
After calling the C<error> function, the error code and the special advice
are thrown away.

=cut

char *
error(sasl)
    Authen_SASL_XS sasl
  PPCODE:
  {
	_DEBUG("Current Error %x",sasl->error_code);

	XPUSHs(newSVpv((char *)sasl_errstring(sasl->error_code,NULL,NULL),0));
#ifdef SASL2
	XPUSHs(newSVpv((char *)sasl_errdetail(sasl->conn),0));
#endif

	if (sasl->additional_errormsg != NULL)
		XPUSHs(newSVpv(sasl->additional_errormsg,0));
	// only real error should be overwritten
	if (sasl->error_code != SASL_OK && sasl->error_code != SASL_CONTINUE)
	{
		sasl->error_code = SASL_OK;
		if (sasl->additional_errormsg != NULL)
			free(sasl->additional_errormsg);
		sasl->additional_errormsg = NULL;
	}
	__DEBUG("End of Error");
  }


=pod

=item code ( )

C<code> returns the current Cyrus-SASL error code.

=cut

int
code(sasl)
    Authen_SASL_XS sasl
  CODE:
    RETVAL=sasl->error_code;
  OUTPUT:
    RETVAL


=pod

=item mechanism ( )

C<mechanism> returns the current used authentication mechanism.

=cut

char *
mechanism(sasl)
    Authen_SASL_XS sasl
  CODE:
    RETVAL = sasl->mech;
  OUTPUT:
    RETVAL



char *
host(sasl, ...)
    Authen_SASL_XS sasl
  CODE:
    if (items > 1) {
      if (sasl->server) free(sasl->server);
      sasl->server = strdup(SvPV_nolen(ST(1)));
    }
    RETVAL = sasl->server;
  OUTPUT:
    RETVAL



char *
user(sasl, ...)
    Authen_SASL_XS sasl
  CODE:
    if (items > 1) {
      if (sasl->user) free(sasl->user);
      sasl->user = strdup(SvPV_nolen(ST(1)));
    }
    RETVAL = sasl->user;
  OUTPUT:
    RETVAL



char *
service(sasl, ...)
    Authen_SASL_XS sasl
  CODE:
    if (items > 1) {
      if (sasl->service) free(sasl->service);
      sasl->service = strdup(SvPV_nolen(ST(1)));
    }
    RETVAL = sasl->service;
  OUTPUT:
    RETVAL


=pod

=item need_step ( )

C<need_step> returns true if another step is need by the SASL library. Otherwise
false is returned. You can also use C<code == 1> but it looks smarter I think.
That's why we all using perl, eh?

=cut

int
need_step(sasl)
	Authen_SASL_XS sasl;
	CODE:
		RETVAL = sasl->error_code == SASL_CONTINUE;
	OUTPUT:
		RETVAL


int
property(sasl, ...)
Authen_SASL_XS sasl
PPCODE:
{
#ifdef SASL2
	const void *value=NULL;
#else
	void *value=NULL;
#endif
	char *name;
	int rc, x, propnum=-1;
	SV *prop;

	RETVAL = SASL_OK;

	if (!sasl->conn) {
#ifdef SASL2
		SetSaslError(sasl,SASL_NOTINIT,"property failed, init missed.");
		RETVAL = SASL_NOTINIT;
#else
		SetSaslError(sasl,SASL_FAIL,"property failed, init missed.");
		RETVAL = SASL_FAIL;
#endif
		items = 0;
	}
/* Querying the value of a property */
	if (items == 2) {
		name = SvPV_nolen(ST(1));
		propnum = PropertyNumber(name);
		rc = sasl_getprop(sasl->conn, propnum, &value);

		if (value == NULL || rc != SASL_OK)
			XSRETURN_UNDEF;

		switch(propnum){
			case SASL_USERNAME:
#ifdef SASL2
			case SASL_DEFUSERREALM:
#else
			case SASL_REALM:
#endif
				XPUSHp( (char *)value, strlen((char *)value));
			break;
			case SASL_SSF:
			case SASL_MAXOUTBUF:
				XPUSHi((int *)value);
			break;
#ifdef SASL2
			case SASL_IPLOCALPORT:
			case SASL_IPREMOTEPORT:
				XPUSHp( (char *)value, strlen((char *)value));
			break;
			case SASL_IP_LOCAL:
				propnum = SASL_IPLOCALPORT;
				{
					char *addr = inet_ntoa( (*(struct in_addr *)value));
					XPUSHp( addr, strlen(addr));
				}
			break;
			case SASL_IP_REMOTE:
				propnum = SASL_IPREMOTEPORT;
				{
					char *addr = inet_ntoa( (*(struct in_addr *)value));
					XPUSHp( addr, strlen(addr));
				}
			break;
#else
			case SASL_IP_LOCAL:
			case SASL_IP_REMOTE:
				XPUSHp( (char *)value, sizeof(struct sockaddr_in));
			break;
#endif
			default:
				XPUSHi(-1);
		}
		XSRETURN(1);
	}
/* Fill in the properties */
	for(x=1; x<items; x+=2) {

		prop = ST(x);
		value = (void *)SvPV_nolen( ST(x+1) );

		if (SvTYPE(prop) == SVt_IV) {
			propnum = SvIV(prop);
		} else if (SvTYPE(prop) == SVt_PV) {
			name = SvPV_nolen(prop);
			propnum = PropertyNumber(name);
		}
#ifdef SASL2
		if ((propnum == SASL_IP_LOCAL) || (propnum == SASL_IP_REMOTE))
			rc = 0;
		else
#endif
			rc = sasl_setprop(sasl->conn, propnum, value);
		if (SetSaslError(sasl,rc,"sasl_setprop failed.") != SASL_OK)
			RETVAL = 1;
	}
}

void
DESTROY(sasl)
    Authen_SASL_XS sasl
  CODE:
  {
	__DEBUG("DESTROY");
    if (sasl->conn)  sasl_dispose(&sasl->conn);
    if (sasl->callbacks) {
      free(sasl->callbacks[sasl->callback_count].context);
      free(sasl->callbacks);
    }
    if (sasl->service)   free(sasl->service);
    if (sasl->mech)      free(sasl->mech);
	if (sasl->additional_errormsg)  free(sasl->additional_errormsg);
    free(sasl);
	sasl_done();
  }



=pod

=back

=head1 EXAMPLE

=head2 Server-side

 # The example uses Cyrus-SASL v2
 # Set the SASL_PATH to the location of the SASL-Plugins
 # default is /usr/lib/sasl2
 $ENV{'SASL_PATH'} = "/opt/products/sasl/2.1.15/lib/sasl2";

 #
 my $sasl = Authen::SASL->new (
    mechanism => "PLAIN",
    callback => {
      checkpass => \&checkpass,
      canonuser => \&canonuser,
    }
 );

 # Creating the Authen::SASL::XS object
 my $conn = $sasl->server_new("service","","ip;port local","ip;port remote");

 # Clients first string (maybe "", depends on mechanism)
 # Client has to start always
 sendreply( $conn->server_start( &getreply() ) );

 while ($conn->need_step) {
    sendreply( $conn->server_step( &getreply() ) );
 }

 if ($conn->code == 0) {
    print "Negotiation succeeded.\n";
 } else {
    print "Negotiation failed.\n";
 }

=head2 Client-side

 # The example uses Cyrus-SASL v2
 # Set the SASL_PATH to the location of the SASL-Plugins
 # default is /usr/lib/sasl2
 $ENV{'SASL_PATH'} = "/opt/products/sasl/2.1.15/lib/sasl2";

 #
 my $sasl = Authen::SASL->new (
    mechanism => "PLAIN",
    callback => {
      user => \&getusername,
      pass => \&getpassword,
    }
 );

 # Creating the Authen::SASL::XS object
 my $conn = $sasl->client_new("service", "hostname.domain.tld");

 # Client begins always
 sendreply($conn->client_start());

 while ($conn->need_step) {
    sendreply($conn->client_step( &getreply() ) );
 }

 if ($conn->code == 0) {
    print STDERR "Negotiation succeeded.\n";
 } else {
    print STDERR "Negotiation failed.\n";
 }

See t/plain.t for working script.

=head1 TESTING

I tested ASC (server and client) with the following mechanisms:

=over 4

=item GSSAPI

Don't forget to create keytab. Non-root keytabs can be specify through $ENV{'KRB5_KTNAME'} (Heimdal >= 0.6, MIT).

=item KERBEROS_V4

Available since 0.10, you have to add IPLOCALPORT and IPREMOTEPORT to *_new functions.

=item  PLAIN

=back

=head1 SEE ALSO

L<Authen::SASL>

man pages for sasl_* library functions.

=head1 AUTHOR

Originally written by Mark Adamson <mark@nb.net>

Cyrus-SASL 2.x support by Leif Johansson

Glue for server_* and many other structural improvements by Patrick Boettcher <patrick.boettcher@desy.de>

Please report any bugs, or post any suggestions, to the authors.

=head1 THANKS

 - Guillaume Filion for testing the server part and for giving hints about
   some bugs (documentation).
 - Wolfgang Friebel for bother around with rpm building of test releases.

=head1 COPYRIGHT

Copyright (c) 2003-5 Patrick Boettcher, DESY Zeuthen. All rights reserved.
Copyright (c) 2003 Carnegie Mellon University. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
