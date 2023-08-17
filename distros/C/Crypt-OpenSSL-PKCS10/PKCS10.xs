#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>

#include <openssl/asn1.h>
#include <openssl/pem.h>
#include <openssl/x509v3.h>
#include <openssl/err.h>
#include <openssl/rand.h>

#include "ppport.h"

#if OPENSSL_VERSION_NUMBER < 0x10100000L || defined LIBRESSL_VERSION_NUMBER
#define EVP_PKEY_get0_RSA(pkey) ((pkey)->pkey.rsa)
#define EVP_PKEY_get0_DSA(pkey) ((pkey)->pkey.dsa)
#if( !defined OPENSSL_NO_EC || defined LIBRESSL_VERSION_NUMBER)
#define EVP_PKEY_get0_EC_KEY(pkey) ((pkey)->pkey.ec)
#endif
#endif

typedef struct
{
    X509_REQ* req;
    EVP_PKEY *pk;
    RSA **rsa;
    STACK_OF(X509_EXTENSION) *exts;
} pkcs10Data;

typedef struct
{
    RSA* rsa;
    int padding;
    int hashMode;
} Crypt__OpenSSL__RSA; 

#define PACKAGE_NAME "Crypt::OpenSSL::PKCS10"
#define PACKAGE_CROAK(p_message) croak("%s", (p_message))
#define CHECK_NEW(p_var, p_size, p_type) \
  if (New(0, p_var, p_size, p_type) == NULL) \
    { PACKAGE_CROAK("unable to alloc buffer"); }

//int add_ext_raw(STACK_OF(X509_REQUEST) *sk, int nid, unsigned char *value, int length);
//int add_ext(STACK_OF(X509_REQUEST) *sk, int nid, char *value);
X509_NAME *parse_name(char *str, long chtype, int multirdn); 

/*
 * subject is expected to be in the format /type0=value0/type1=value1/type2=...
 * where characters may be escaped by \
 */
X509_NAME *parse_name(char *subject, long chtype, int multirdn)
	{
	size_t buflen = strlen(subject)+1; /* to copy the types and values into. due to escaping, the copy can only become shorter */
	char *buf = OPENSSL_malloc(buflen);
	size_t max_ne = buflen / 2 + 1; /* maximum number of name elements */
	const char **ne_types = OPENSSL_malloc(max_ne * sizeof (char *));
	char **ne_values = OPENSSL_malloc(max_ne * sizeof (char *));
	int *mval = OPENSSL_malloc (max_ne * sizeof (int));

	char *sp = subject, *bp = buf;
	int i, ne_num = 0;

	X509_NAME *n = NULL;

	if (!buf || !ne_types || !ne_values || !mval)
		{
		croak("malloc error\n");
		goto error;
		}	

	if (*subject != '/')
		{
		croak("Subject does not start with '/'.\n");
		goto error;
		}
	sp++; /* skip leading / */

	/* no multivalued RDN by default */
	mval[ne_num] = 0;

	while (*sp)
		{
		/* collect type */
		ne_types[ne_num] = bp;
		while (*sp)
			{
			if (*sp == '\\') /* is there anything to escape in the type...? */
				{
				if (*++sp)
					*bp++ = *sp++;
				else	
					{
					croak("escape character at end of string\n");
					goto error;
					}
				}	
			else if (*sp == '=')
				{
				sp++;
				*bp++ = '\0';
				break;
				}
			else
				*bp++ = *sp++;
			}
		if (!*sp)
			{
			croak("end of string encountered while processing type of subject name element #%d\n", ne_num);
			goto error;
			}
		ne_values[ne_num] = bp;
		while (*sp)
			{
			if (*sp == '\\')
				{
				if (*++sp)
					*bp++ = *sp++;
				else
					{
					croak("escape character at end of string\n");
					goto error;
					}
				}
			else if (*sp == '/')
				{
				sp++;
				/* no multivalued RDN by default */
				mval[ne_num+1] = 0;
				break;
				}
			else if (*sp == '+' && multirdn)
				{
				/* a not escaped + signals a mutlivalued RDN */
				sp++;
				mval[ne_num+1] = -1;
				break;
				}
			else
				*bp++ = *sp++;
			}
		*bp++ = '\0';
		ne_num++;
		}

	if (!(n = X509_NAME_new()))
		goto error;

	for (i = 0; i < ne_num; i++)
		{
		if (!*ne_values[i])
			{
			croak("No value provided for Subject Attribute %s, skipped\n", ne_types[i]);
			continue;
			}

		if (!X509_NAME_add_entry_by_txt(n, ne_types[i], chtype, (unsigned char*)ne_values[i], -1,-1,mval[i]))
			goto error;
		}

	OPENSSL_free(mval);
	OPENSSL_free(ne_values);
	OPENSSL_free(ne_types);
	OPENSSL_free(buf);
	return n;

	error:
	X509_NAME_free(n);
	if (ne_values)
		OPENSSL_free(ne_values);
	if (ne_types)
		OPENSSL_free(ne_types);
	if (buf)
		OPENSSL_free(buf);
    if (mval)
	    OPENSSL_free(mval);
	return NULL;
}

/* Add extension using V3 code: we can set the config file as NULL
 * because we wont reference any other sections.
 */

int add_ext(STACK_OF(X509_EXTENSION) *sk, X509_REQ *req, int nid, char *value)
	{
	X509_EXTENSION *ex;
	X509V3_CTX v3ctx;
	X509V3_set_ctx(&v3ctx, NULL, NULL, req, NULL, 0);
	ex = X509V3_EXT_conf_nid(NULL, &v3ctx, nid, value);
	if (!ex)
		return 0;
	sk_X509_EXTENSION_push(sk, ex);

	return 1;
	}

/*  Add an extention by setting the raw ASN1 octet string.
 */
int add_ext_raw(STACK_OF(X509_EXTENSION) *sk, int nid, char *value, int length)
	{
	X509_EXTENSION *ex;
	ASN1_STRING *asn;

	asn = ASN1_STRING_type_new(V_ASN1_OCTET_STRING);
	ASN1_OCTET_STRING_set(asn, (unsigned char *) value, length);

	ex = X509_EXTENSION_create_by_NID(NULL, nid, 0, asn);
	if (!ex)
		return 0;
	sk_X509_EXTENSION_push(sk, ex);

	return 1;
	}


SV* make_pkcs10_obj(SV* p_proto, X509_REQ* p_req, EVP_PKEY* p_pk, STACK_OF(X509_EXTENSION)* p_exts, RSA **p_rsa)
{
	pkcs10Data* pkcs10;

	CHECK_NEW(pkcs10, 1, pkcs10Data);
	pkcs10->req = p_req;
	pkcs10->pk = p_pk;
	pkcs10->exts = p_exts;
	pkcs10->rsa = p_rsa;

	return sv_bless(
		newRV_noinc(newSViv((IV) pkcs10)),
		(SvROK(p_proto) ? SvSTASH(SvRV(p_proto)) : gv_stashsv(p_proto, 1)));
}

/* stolen from OpenSSL.xs */
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
long bio_write_cb(struct bio_st *bm, int m, const char *ptr, size_t len, int l, long x, int y, size_t *processed) {
#else
long bio_write_cb(struct bio_st *bm, int m, const char *ptr, int len, long x, long y) {
#endif
        if (m == BIO_CB_WRITE) {
                SV *sv = (SV *) BIO_get_callback_arg(bm);
                sv_catpvn(sv, ptr, len);
        }

        if (m == BIO_CB_PUTS) {
                SV *sv = (SV *) BIO_get_callback_arg(bm);
                len = strlen(ptr);
                sv_catpvn(sv, ptr, len);
        }

        return len;
}

static BIO* sv_bio_create(void) {

        SV *sv = newSVpvn("",0);

	/* create an in-memory BIO abstraction and callbacks */
        BIO *bio = BIO_new(BIO_s_mem());

#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        BIO_set_callback_ex(bio, bio_write_cb);
#else
        BIO_set_callback(bio, bio_write_cb);
#endif
        BIO_set_callback_arg(bio, (void *)sv);

        return bio;
}

static BIO *sv_bio_create_file(SV *filename)
{
        STRLEN l;

        return BIO_new_file(SvPV(filename, l), "wb");
}

static SV* sv_bio_final(BIO *bio) {

	SV* sv;

	BIO_flush(bio);
	sv = (SV *)BIO_get_callback_arg(bio);
	BIO_free_all(bio);

	if (!sv) sv = &PL_sv_undef;

	return sv;
}

/*
 * subject is expected to be in the format /type0=value0/type1=value1/type2=...
 * where characters may be escaped by \
 */
static int build_subject(X509_REQ *req, char *subject, unsigned long chtype, int multirdn)
	{
	X509_NAME *n;

	if (!(n = parse_name(subject, chtype, multirdn)))
		return 0;

	if (!X509_REQ_set_subject_name(req, n))
		{
		X509_NAME_free(n);
		return 0;
		}
	X509_NAME_free(n);
	return 1;
}

MODULE = Crypt::OpenSSL::PKCS10		PACKAGE = Crypt::OpenSSL::PKCS10

PROTOTYPES: DISABLE

BOOT:
{
	/*OpenSSL_add_all_algorithms();
        OpenSSL_add_all_ciphers();
        OpenSSL_add_all_digests();
	ERR_load_PEM_strings();
        ERR_load_ASN1_strings();
        ERR_load_crypto_strings();
        ERR_load_X509_strings();
        ERR_load_DSA_strings();
        ERR_load_RSA_strings();*/
	HV *stash = gv_stashpvn("Crypt::OpenSSL::PKCS10", 22, TRUE);

	struct { char *n; I32 v; } Crypt__OpenSSL__PKCS10__const[] = {

	{"NID_key_usage", NID_key_usage},
	{"NID_subject_alt_name", NID_subject_alt_name},
	{"NID_netscape_cert_type", NID_netscape_cert_type},
	{"NID_netscape_comment", NID_netscape_comment},
	{"NID_ext_key_usage", NID_ext_key_usage},
	{"NID_subject_key_identifier", NID_subject_key_identifier},
	{Nullch,0}};

	char *name;
	int i;

	for (i = 0; (name = Crypt__OpenSSL__PKCS10__const[i].n); i++) {
		newCONSTSUB(stash, name, newSViv(Crypt__OpenSSL__PKCS10__const[i].v));
	}
}

SV*
new(class, keylen = 1024)
	SV	*class
	int keylen

	PREINIT:
	X509_REQ *x;
	EVP_PKEY *pk;
    char *classname = SvPVutf8_nolen(class);

	CODE:
	//CRYPTO_mem_ctrl(CRYPTO_MEM_CHECK_ON);
    if (!RAND_status())
        printf("Warning: generating random key material may take a long time\n"
                   "if the system has a poor entropy source\n");

	if ((x=X509_REQ_new()) == NULL)
		croak ("%s - can't create req", classname);
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    pk = EVP_RSA_gen(keylen);
#elif OPENSSL_VERSION_NUMBER <= 0x10000000L
    RSA *rsa;
	if ((pk=EVP_PKEY_new()) == NULL)
		croak ("%s - can't create PKEY", classname);

	rsa=RSA_generate_key(keylen, RSA_F4, NULL, NULL);
	if (!EVP_PKEY_assign_RSA(pk,rsa))
		croak ("%s - EVP_PKEY_assign_RSA", classname);
#else
    RSA *rsa = RSA_new();
    BIGNUM *bne = BN_new();
    if (bne == NULL)
		croak ("%s - BN_new failed", classname);

    if (BN_set_word(bne, RSA_F4) != 1)
		croak ("%s - BN_set_word failed", classname);

	if ((pk=EVP_PKEY_new()) == NULL)
		croak ("%s - can't create PKEY", classname);

    if (!RSA_generate_key_ex(rsa, keylen, bne, NULL))
		croak ("%s - RSA_generate_key_ex failed", classname);

	if (!EVP_PKEY_assign_RSA(pk,rsa))
		croak ("%s - EVP_PKEY_assign_RSA", classname);
#endif
	X509_REQ_set_pubkey(x,pk);
	X509_REQ_set_version(x,0L);
	if (!X509_REQ_sign(x,pk,EVP_sha256()))
		croak ("%s - X509_REQ_sign failed", classname);
	
	RETVAL = make_pkcs10_obj(class, x, pk, NULL, NULL);
  
	OUTPUT:
        RETVAL

void
DESTROY(pkcs10)
	pkcs10Data *pkcs10;

	PREINIT:
	//BIO *bio_err;
	
	PPCODE:
	//bio_err=BIO_new_fp(stderr, BIO_NOCLOSE);
	if (pkcs10->pk)   EVP_PKEY_free(pkcs10->pk); pkcs10->pk = 0;
	if (pkcs10->rsa) *pkcs10->rsa = 0;
	if (pkcs10->req)  X509_REQ_free(pkcs10->req); pkcs10->req = 0;
	Safefree(pkcs10);
	CRYPTO_cleanup_all_ex_data();
	/*CRYPTO_mem_leaks(bio_err);
	BIO_free(bio_err);*/

SV*
_new_from_rsa(class, p_rsa, priv)
	SV	*class
	SV	*p_rsa
	SV  *priv

	PREINIT:
	Crypt__OpenSSL__RSA	*rsa;
	char *keyString;
	STRLEN keylen;
	BIO *bio;
	X509_REQ *x;
	EVP_PKEY *pk;
	char *classname = SvPVutf8_nolen(class);
	
	CODE:

	// Get the private key and save it in memory
	keyString = SvPV(priv, keylen);
	bio = BIO_new_mem_buf(keyString, keylen);
	if (bio == NULL) {
		croak ("Bio is null **** \n");
	}

	// Create the PrivateKey as EVP_PKEY
	pk = PEM_read_bio_PrivateKey(bio, NULL, 0, NULL);
	if (pk == NULL) {
		croak("Failed operation error code %d\n", errno);
	}

	if ((x=X509_REQ_new()) == NULL)
		croak ("%s - can't create req", classname);

	rsa = (Crypt__OpenSSL__RSA	*) SvIV(SvRV(p_rsa));
	X509_REQ_set_pubkey(x,pk);
	X509_REQ_set_version(x,0L);
	if (!X509_REQ_sign(x,pk,EVP_sha256()))
		croak ("%s - X509_REQ_sign", classname);
	
	RETVAL = make_pkcs10_obj(class, x, pk, NULL, &rsa->rsa);

	OUTPUT:
        RETVAL

int
sign(pkcs10)
	pkcs10Data *pkcs10;

	PREINIT:

	CODE:

	RETVAL = X509_REQ_sign(pkcs10->req,pkcs10->pk,EVP_sha256());
	if (!RETVAL)
		croak ("X509_REQ_sign");

	OUTPUT:
	RETVAL

SV*
get_pem_pubkey(pkcs10)
	pkcs10Data *pkcs10;

	PREINIT:
	EVP_PKEY *pkey;
	BIO *bio;
	int type;

	CODE:

	pkey = X509_REQ_get_pubkey(pkcs10->req);
	bio  = sv_bio_create();

	if (pkey == NULL) {

		BIO_free_all(bio);
		EVP_PKEY_free(pkey);
		croak("Public Key is unavailable\n");
	}

	type = EVP_PKEY_base_id(pkey);
	if (type == EVP_PKEY_RSA) {
		PEM_write_bio_PUBKEY(bio, pkey);
	} else if (type == EVP_PKEY_DSA) {
		PEM_write_bio_PUBKEY(bio, pkey);
#ifndef OPENSSL_NO_EC
	} else if ( type == EVP_PKEY_EC ) {
		PEM_write_bio_PUBKEY(bio, pkey);
#endif
	} else {

		BIO_free_all(bio);
		EVP_PKEY_free(pkey);
		croak("Wrong Algorithm type\n");
	}
	EVP_PKEY_free(pkey);

	RETVAL = sv_bio_final(bio);

	OUTPUT:
	RETVAL

char*
pubkey_type(pkcs10)
	pkcs10Data *pkcs10;

    PREINIT:
        EVP_PKEY *pkey;
	int type;

    CODE:
        RETVAL=NULL;
        pkey = X509_REQ_get_pubkey(pkcs10->req);

        if(!pkey)
            XSRETURN_UNDEF;

        type = EVP_PKEY_base_id(pkey);
        if (type == EVP_PKEY_DSA) {
            RETVAL="dsa";

        } else if (type == EVP_PKEY_RSA) {
            RETVAL="rsa";
#ifndef OPENSSL_NO_EC
        } else if ( type == EVP_PKEY_EC ) {
            RETVAL="ec";
#endif
        }

    OUTPUT:
    RETVAL

SV*
get_pem_req(pkcs10,...)
	pkcs10Data *pkcs10;
  
	ALIAS:
	write_pem_req = 1
	PROTOTYPE: $;$

	PREINIT:
	BIO *bio;

	CODE:
	if((ix != 1 && items > 1) || (ix == 1 && items != 2))
		croak("get_pem_req illegal/missing args");
	if(items > 1) {
		bio = sv_bio_create_file(ST(1));
	} else {
		bio = sv_bio_create();
	}

	/* get the certificate back out in a specified format. */

	if(!PEM_write_bio_X509_REQ(bio,pkcs10->req))
		croak ("PEM_write_bio_X509_REQ");

	RETVAL = sv_bio_final(bio);

	OUTPUT:
	RETVAL

SV*
get_pem_pk(pkcs10,...)
	pkcs10Data *pkcs10;

	ALIAS:
	write_pem_pk = 1
	PROTOTYPE: $;$

	PREINIT:
	BIO *bio;

	CODE:
	if((ix != 1 && items > 1) || (ix == 1 && items != 2))
		croak("get_pem_pk illegal/missing args");
	if(items > 1) {
		bio = sv_bio_create_file(ST(1));
	} else {
		bio = sv_bio_create();
	}

    if(!pkcs10->pk)
            croak ("Private key doesn't exist");

	/* get the certificate back out in a specified format. */

	if(!PEM_write_bio_PrivateKey(bio,pkcs10->pk,NULL,NULL,0,NULL,NULL))
		croak ("%s - PEM_write_bio_PrivateKey", (char *) pkcs10->pk);

	RETVAL = sv_bio_final(bio);

	OUTPUT:
	RETVAL

int
set_subject(pkcs10, subj_SV, utf8 = 0)
	pkcs10Data *pkcs10;
	SV* subj_SV;
	int utf8;

	PREINIT:
	char* subj;
	STRLEN subj_length;

	CODE:
	subj = SvPV(subj_SV, subj_length);

	RETVAL = build_subject(pkcs10->req, subj, utf8 ? MBSTRING_UTF8 : MBSTRING_ASC, 0);
	if (!RETVAL)
		croak ("build_subject");

	OUTPUT:
	RETVAL

int
add_ext(pkcs10, nid = NID_key_usage, ext_SV)
	pkcs10Data *pkcs10;
	int nid;
	SV* ext_SV;

	PREINIT:
	char* ext;
	STRLEN ext_length;

	CODE:
	ext = SvPV(ext_SV, ext_length);

	if(!pkcs10->exts)
		pkcs10->exts = sk_X509_EXTENSION_new_null();
	
	RETVAL = add_ext(pkcs10->exts, pkcs10->req, nid, ext);
	if (!RETVAL)
		croak ("add_ext key_usage: %d, ext: %s", nid, ext);

	OUTPUT:
	RETVAL

int
add_custom_ext_raw(pkcs10, oid_SV, ext_SV)
	pkcs10Data *pkcs10;
	SV* oid_SV;
	SV* ext_SV;

	PREINIT:
	char* oid;
	char* ext;
	STRLEN ext_length;
	int nid;

	CODE:
	oid = SvPV(oid_SV, ext_length);
	ext = SvPV(ext_SV, ext_length);
 
  	if(!pkcs10->exts)
		pkcs10->exts = sk_X509_EXTENSION_new_null();

	if ((nid = OBJ_create(oid, oid, oid)) == NID_undef)
        croak ("add_custom_ext: OBJ_create() for OID %s failed", oid);
	RETVAL = add_ext_raw(pkcs10->exts, nid, ext, ext_length);

	if (!RETVAL)
		croak ("add_custom_ext_raw oid: %s, ext: %s", oid, ext);

	OUTPUT:
	RETVAL


int
add_custom_ext(pkcs10, oid_SV, ext_SV)
	pkcs10Data *pkcs10;
	SV* oid_SV;
	SV* ext_SV;

	PREINIT:
	char* oid;
	char* ext;
	STRLEN ext_length;
	int nid;

	CODE:
	oid = SvPV(oid_SV, ext_length);
	ext = SvPV(ext_SV, ext_length);

	if(!pkcs10->exts)
		pkcs10->exts = sk_X509_EXTENSION_new_null();

	if ((nid = OBJ_create(oid, oid, oid)) == NID_undef)
        croak ("add_custom_ext_raw: OBJ_create() for OID %s failed", oid);
	X509V3_EXT_add_alias(nid, NID_netscape_comment);
	RETVAL = add_ext(pkcs10->exts, pkcs10->req, nid, ext);

	if (!RETVAL)
		croak ("add_custom_ext oid: %s, ext: %s", oid, ext);

	OUTPUT:
	  RETVAL

int
add_ext_final(pkcs10)
	pkcs10Data *pkcs10;

	CODE:
	if(pkcs10->exts) {
	RETVAL = X509_REQ_add_extensions(pkcs10->req, pkcs10->exts);
  
	if (!RETVAL)
		croak ("X509_REQ_add_extensions");

	if(pkcs10->exts)
		sk_X509_EXTENSION_pop_free(pkcs10->exts, X509_EXTENSION_free);
	} else {
		RETVAL = 0;
	}

	OUTPUT:
	RETVAL

SV*
new_from_file(class, filename_SV)
  SV* class;
  SV* filename_SV;

  PREINIT:
  char* filename;
  STRLEN filename_length;
  FILE* fp;
  X509_REQ *req;

  CODE:
  filename = SvPV(filename_SV, filename_length);
  fp = fopen(filename, "r");
  if (fp == NULL) {
          croak ("Cannot open file '%s'", filename);
  }
  req = PEM_read_X509_REQ (fp, NULL, NULL, NULL);
  fclose(fp);

  RETVAL = make_pkcs10_obj(class, req, NULL, NULL, NULL);

  OUTPUT:
        RETVAL


SV*
accessor(pkcs10)
  pkcs10Data *pkcs10;

  ALIAS:
  subject = 1
  keyinfo = 2


  PREINIT:
  BIO *bio;
  X509_NAME *name;
  EVP_PKEY *key;

  CODE:

  bio = sv_bio_create();

  if (pkcs10->req != NULL) {
    if (ix == 1) {
      name = X509_REQ_get_subject_name(pkcs10->req);
      X509_NAME_print_ex(bio, name, 0, XN_FLAG_SEP_CPLUS_SPC);
    } else if (ix == 2 ) {
      key = X509_REQ_get_pubkey(pkcs10->req);
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
      EVP_PKEY_print_public(bio, key, 0, NULL);
#else
      RSA_print(bio, EVP_PKEY_get1_RSA(key), 0);
#endif
    }
  }

  RETVAL = sv_bio_final(bio);

  OUTPUT:
        RETVAL
