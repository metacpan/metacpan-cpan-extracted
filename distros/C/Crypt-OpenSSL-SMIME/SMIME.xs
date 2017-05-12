#include <stdio.h>
#include <string.h>
#include <openssl/crypto.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/pkcs12.h>
#include <openssl/x509.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define SMIME_OP	0x10
#define SMIME_ENCRYPT	(1 | SMIME_OP)
#define SMIME_DECRYPT	2
#define SMIME_SIGN	(3 | SMIME_OP)
#define SMIME_VERIFY	4
#define SMIME_PK7OUT	5

#define FORMAT_UNDEF    0
#define FORMAT_ASN1     1
#define FORMAT_TEXT     2
#define FORMAT_PEM      3
#define FORMAT_NETSCAPE 4
#define FORMAT_PKCS12   5
#define FORMAT_SMIME    6

#define NETSCAPE_CERT_HDR	"certificate"
#define APP_PASS_LEN	1024

SV** value;
int i;
int len;
char *copy_value;
char *pass_for_signer_key;
HV *lang_hash;
SV *hash_value;

#define string_from_hash(hash, key, klen, result) \
	value = hv_fetch(hash, key, klen, 0); \
	if (value == NULL)	{ \
		warn("Crypt::OpenSSL::SMIME: unable to get value for key '%s'", key); \
	} else {\
		copy_value = SvPV(*value, len); \
		result = (char*)safemalloc( ++len); \
		strncpy( result, copy_value, len); \
	} \

typedef struct {
	char *From;
    char *rootCA;
    char *rcpt_cert_file;
    char *signerfile;
    char *signer_key_file;
    char *pass_for_root_CA;
    char *pass_for_signer_key;
	char *outfile;
    int flags;
    X509 *cert;
	X509 *signer;
	BIO *bio_err;
	EVP_CIPHER *cipher;
    char *inmode;
	char *outmode;
	X509_STORE *store;
	EVP_PKEY *key;
	STACK_OF(X509) *encerts;
	STACK_OF(X509) *other;
	PKCS7 *p7;
	BIO *in;
	BIO *tmp_in;
	BIO *out;
	int FAILED;
} openssl_smime_struct;


X509_STORE *loadRootCA(char *CAfile)
{
	X509_STORE *store;
	X509_LOOKUP *lookup;
	if(!(store = X509_STORE_new())) goto end;
    /* storing cert from file into store */
	lookup=X509_STORE_add_lookup(store,X509_LOOKUP_file());
	if (lookup == NULL) goto end;
	if(!X509_LOOKUP_load_file(lookup,CAfile,X509_FILETYPE_PEM)) {
			fprintf(stderr, "Crypt::OpenSSL::SMIME: Error loading file %s\n", CAfile);
			goto end;
	}
    
	lookup=X509_STORE_add_lookup(store,X509_LOOKUP_hash_dir());
    
    X509_LOOKUP_add_dir(lookup,NULL,X509_FILETYPE_DEFAULT);
    
	ERR_clear_error();
	return store;
	end:
	X509_STORE_free(store);
	return NULL;
}

int yasp_pass_cb(char *buf, int size, int rwflag, void *u)
{
	int len;
	len = strlen(pass_for_signer_key);

	if (len <= 0) return 0;

	memcpy(buf, pass_for_signer_key, len);
	return len;
}

EVP_PKEY *load_key(BIO *err, char *file, int format, char *pass, openssl_smime_struct *self )
	{
	BIO *key=NULL;
	EVP_PKEY *pkey=NULL;

	if (file == NULL)
		{
		fprintf(stderr, "Crypt::OpenSSL::SMIME: no keyfile specified\n");
		goto end;
		}
	key=BIO_new(BIO_s_file());
	if (key == NULL)
		{
		goto end;
		}
	if (BIO_read_filename(key,file) <= 0)
		{
		perror(file);
		goto end;
		}
	if (format == FORMAT_ASN1)
		{
		pkey=d2i_PrivateKey_bio(key, NULL);
		}
	else if (format == FORMAT_PEM)
		{
		//Fucking callback :(
		len = strlen(self->pass_for_signer_key);
		pass_for_signer_key = (char*)safemalloc( ++len ); \
		strncpy( pass_for_signer_key, self->pass_for_signer_key, len); \
		pkey=PEM_read_bio_PrivateKey(key,NULL,yasp_pass_cb,NULL);
		safefree( (char*)pass_for_signer_key );
		}
	else if (format == FORMAT_PKCS12)
		{
		PKCS12 *p12 = d2i_PKCS12_bio(key, NULL);

		PKCS12_parse(p12, pass, &pkey, NULL, NULL);
		PKCS12_free(p12);
		p12 = NULL;
		}
	else
		{
		fprintf(stderr, "Crypt::OpenSSL::SMIME: bad input format specified for key\n");
		goto end;
		}
 end:
	if (key != NULL) BIO_free(key);
	if (pkey == NULL)
		fprintf(stderr, "Crypt::OpenSSL::SMIME: unable to load Private Key\n");
	return(pkey);
}

/* we read only in PEM format !!!! */

X509 *load_cert(BIO *err, char *file, int format)
	{
	BUF_MEM *buf=NULL;
	X509 *x=NULL;
	BIO *cert;

	if ((cert=BIO_new(BIO_s_file())) == NULL)
		{
		goto end;
		}

	if (file == NULL)
		BIO_set_fp(cert,stdin,BIO_NOCLOSE);
	else
		{
		if (BIO_read_filename(cert,file) <= 0)
			{
			perror(file);
			goto end;
			}
		}

	if (format == FORMAT_PEM)
		x=PEM_read_bio_X509_AUX(cert,NULL,NULL,NULL);
	else if (format == FORMAT_PKCS12)
		{
		PKCS12 *p12 = d2i_PKCS12_bio(cert, NULL);

		PKCS12_parse(p12, NULL, NULL, &x, NULL);
		PKCS12_free(p12);
		p12 = NULL;
		}
	else	{
		fprintf(stderr, "Crypt::OpenSSL::SMIME: bad input format specified for input cert\n");
		goto end;
		}
end:
	if (x == NULL)
		{
		fprintf(stderr, "Crypt::OpenSSL::SMIME: unable to load certificate\n");
		}

	if (cert != NULL) BIO_free(cert);
	if (buf != NULL) BUF_MEM_free(buf);
	return(x);
}

MODULE = Crypt::OpenSSL::SMIME        PACKAGE = Crypt::OpenSSL::SMIME

# Make sure that we have at least xsubpp version 1.922. 
REQUIRE: 1.922

openssl_smime_struct *
new(CLASS, hashref, ... )
		char *CLASS
		SV* hashref
    PREINIT: 
		HV *hash;
    CODE:
		hash = (HV *) SvRV(hashref);
		RETVAL = (openssl_smime_struct*)safemalloc( sizeof( openssl_smime_struct ) );
		if ( RETVAL == NULL ) {
			warn("Crypt::OpenSSL::SMIME: unable to malloc openssl_smime_struct");
			XSRETURN_UNDEF;
		}
		string_from_hash(hash, "From", 4, RETVAL->From);
		string_from_hash(hash, "rootCA", 6, RETVAL->rootCA);
		string_from_hash(hash, "signerfile", 10, RETVAL->signerfile);
		string_from_hash(hash, "signer_key_file", 15, RETVAL->signer_key_file);
		string_from_hash(hash, "pass_for_root_CA", 16, RETVAL->pass_for_root_CA);
		string_from_hash(hash, "pass_for_signer_key", 19, RETVAL->pass_for_signer_key);
		string_from_hash(hash, "outfile", 7, RETVAL->outfile);

		RETVAL->inmode = "r";
		RETVAL->outmode = "w+";
		RETVAL->flags = PKCS7_DETACHED;

		SSLeay_add_all_algorithms();
		RETVAL->cipher = EVP_des_ede3_cbc();
		RETVAL->store = loadRootCA(RETVAL->rootCA);
		RETVAL->other = NULL;
	    RETVAL->FAILED = 0;

		if(!(RETVAL->signer = load_cert(RETVAL->bio_err,RETVAL->signerfile,FORMAT_PEM))) {
			fprintf(stderr, "Crypt::OpenSSL::SMIME: Can't read signer certificate file %s\n", RETVAL->signerfile);
			RETVAL->FAILED = 1;
		} else {		
			if(!(RETVAL->key = load_key(RETVAL->bio_err,RETVAL->signer_key_file, FORMAT_PEM, NULL, RETVAL))) {
				fprintf(stderr, "Crypt::OpenSSL::SMIME: Can't read sender certificate file %s\n", RETVAL->signer_key_file);
				RETVAL->FAILED = 1;
			}
		}

	OUTPUT:
	    RETVAL

# Perl doesn't know how to destroy an ex1_struct because it isn't
#   a Perl type (i.e  HV,AV,SV).  So we supply a destructor that knows
#   how to destroy an ex1_struct. 

void
DESTROY(self, ... )
	    openssl_smime_struct *self
    CODE:
		X509_free(self->signer);
		EVP_PKEY_free(self->key);
		X509_STORE_free(self->store);
	    BIO_free(self->in) ;

		safefree( (char*)self->From );
		safefree( (char*)self->rootCA );
		safefree( (char*)self->signerfile );
		safefree( (char*)self->signer_key_file );
		safefree( (char*)self->pass_for_root_CA );
		safefree( (char*)self->pass_for_signer_key );
		safefree( (char*)self->outfile );
		safefree( (char*)self );

int
failed( self, ... )
	    openssl_smime_struct *self
    CODE:
		RETVAL = self->FAILED;

	OUTPUT:
	    RETVAL

int
loadDataFile( self, filename, ...  )
	    openssl_smime_struct *self
		char* filename
    CODE:
		if (!(self->in = BIO_new_file(filename, self->inmode))) {
			fprintf(stderr, "Crypt::OpenSSL::SMIME: Can't open input file %s\n", filename);
			RETVAL = 0;
		} else { 
			self->tmp_in = self->in;
			RETVAL = 1 ;
		}
    OUTPUT:
	    RETVAL


int
encryptData( self, rcpt_cert_file, rcpt, subject, ... )
	    openssl_smime_struct *self
		char* rcpt_cert_file
		char* rcpt
		char* subject
    CODE:
		RETVAL = 0;

        if (strlen(rcpt_cert_file) < 1) {
			rcpt_cert_file = "Cert/max.crt";
        }
        if (strlen(rcpt) < 1) {
			rcpt = "max@yasp.com";
        }
        if (strlen(subject) < 1) {
			subject = "Encrypted message";
        }

		BIO_reset(self->in);
		self->p7 = PKCS7_sign(self->signer, self->key, NULL, self->in, self->flags);

		if (BIO_reset(self->in) != 0 && (self->flags & PKCS7_DETACHED)) {
			fprintf(stderr, "Crypt::OpenSSL::SMIME: Can't rewind input file\n");
		}
			
		if (!(self->out = BIO_new_file(self->outfile, self->outmode))) {
			fprintf(stderr, "Crypt::OpenSSL::SMIME: Can't open output file %s\n", self->outfile);
		}

	    BIO_printf(self->out, "To: %s\n", rcpt);
	    BIO_printf(self->out, "From: %s\n", self->From);
	    BIO_printf(self->out, "Subject: %s\n", subject);

		SMIME_write_PKCS7(self->out, self->p7, self->in, self->flags);
		PKCS7_free(self->p7);

		self->encerts = sk_X509_new_null();
	    BIO_reset(self->out) ;
		if(!(self->cert = load_cert(self->bio_err,rcpt_cert_file,FORMAT_PEM))) {
			fprintf(stderr, "Crypt::OpenSSL::SMIME: Can't read recipient certificate file %s\n", rcpt_cert_file);
		}
		sk_X509_push(self->encerts, self->cert);

		self->flags &= PKCS7_BINARY; 

	    if (!(self->tmp_in = BIO_new_file(self->outfile, self->inmode))) {
			fprintf(stderr, "Crypt::OpenSSL::SMIME: Can't open input file %s\n", self->outfile);
		}
    
		self->p7 = PKCS7_encrypt(self->encerts, self->tmp_in, self->cipher, self->flags);
		BIO_reset(self->out);
	    BIO_printf(self->out, "To: %s\n", rcpt);
		BIO_printf(self->out, "From: %s\n", self->From);
		BIO_printf(self->out, "Subject: %s\n", subject);

		SMIME_write_PKCS7(self->out, self->p7, self->tmp_in, self->flags);
	  	PKCS7_free(self->p7);

		sk_X509_pop_free(self->other, X509_free);
		X509_free(self->cert);
		BIO_free(self->tmp_in);
		BIO_free(self->out);

		RETVAL = 1;

	OUTPUT:
	    RETVAL

