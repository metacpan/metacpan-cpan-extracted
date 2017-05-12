/*
* Project       OpenPec
* file name:    SMimeEngine.xs
* Version:      0.0.6
*
* DESCRIPTION
* Interfaccia verso la lib crypto di openssl.
*
* PROBLEMI
* - Se da Perl chiamo init con undef sul parametro other_cert il codice XS
* mi restituisce Segmentation Fault
* - while(1) di init ha un memory leak poi mi restituisce errori dopo aver
* funz correttamente per un po
* probabilmente c'e da liberare ancora qualcosa, la free_init non basta
*
* Developer:
* Fanton Flavio - flavio.fanton@staff.aruba.it
* Di Vizio Luca - luca.divizio@staff.aruba.it
* Gaggini Lorenzo - lorenzo.gaggini@staff.aruba.it
* Thanks to Emanuele Tomasi - et@libersoft.it
*
* History [++date++ - ++author++]:
* creation: 21/03/2007 - Fanton Flavio
* modification:
*
*  - 25/03/2010 - Di Vizio Luca
*       Supporto per SSM, bug fix 64 bit, port to openssl 1.0
*  - 13/08/2013 - Gaggini Lorenzo
*       Funzione digest per calcolo hash
*  - 02/12/2013 - Tomasi Emanuele
*       Fixata la compilazione con openssl 0.9.8
*       Eliminati i warning del compilatore
*
*  Copyright (C) 2006-2013  EXENTRICA s.r.l.,  All Rights Reserved.
*   via Roma 43 - 57126 Livorno (LI) - Italy
*   via Giuntini, 25 / int. 9 - 56023 Navacchio (PI) - Italy
*   tel. +39 050 754 703 - fax +39 050 754 707
*   www.exentrica.it   info@exentrica.it
*
*   This program is free software; you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation; either version 2 of the License, or
*   (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, write to the Free Software
*   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*
*   www.openpec.org - info@openpec.org
*   www.exentrica.it - info@exentrica.it
*/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <inttypes.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <fcntl.h>

#include <openssl/ssl.h>
#include <openssl/engine.h>
#include <openssl/err.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/pem.h>
#include <openssl/ui.h>
#include <openssl/pkcs7.h>
#include <openssl/stack.h>
#include <openssl/safestack.h>
#include <openssl/opensslv.h>
#include <openssl/ossl_typ.h>
#include <openssl/evp.h>

#define ERRSTR_MAXLINE 100
#define MAX_CERTS 10
#define DIGEST_BUFF_SIZE 4096

static X509_STORE *store;
static char *ca_dir;
static char errstring[ERRSTR_MAXLINE];
extern char errstr[ERRSTR_MAXLINE];

static UI_METHOD *ui_method;
static ENGINE *eng;
static X509 *signer;
static EVP_PKEY *pkey = NULL;
static STACK_OF(X509) *other4sign = NULL;
static int init_status = 0;

typedef struct INFOCERT {
     char *issuer;
     char *subject;
     char *serial;
     char *startdate;
     char *enddate;
     char *v3_email;
} INFOCERT;


int SSL_library_init(void);
void free_init();
int save_certs(char *, STACK_OF(X509) *);
/*****************************************/

static void
destroy_ui_method(){
    if(ui_method){
        UI_destroy_method(ui_method);
        ui_method = NULL;
    }
}

static int
verify_callback(int ok, X509_STORE_CTX *stor){
    strcpy(errstring,"");

    if (!ok)
        sprintf(errstring, "Error: %s",X509_verify_cert_error_string(stor->error));
    return ok;
}

int (*sign)(char *fname, char *outfname);
int sign_old(char *fname, char *outfname);

static X509_STORE *
create_store(void){
    X509_STORE *mystore;
    X509_LOOKUP *lookup;

    if (!(mystore = X509_STORE_new())){
        sprintf(errstring, "Error creating X509_STORE_CTX object");
        goto err;
    }
    X509_STORE_set_verify_cb_func(mystore, verify_callback);
    if (X509_STORE_load_locations(mystore, NULL, ca_dir) != 1){
        sprintf(errstring, "Error loading the CA file or directory");
        goto err;
    }
    if (X509_STORE_set_default_paths(mystore) != 1){
        sprintf(errstring, "Error loading the system-wide CA certificates");
        goto err;
    }
    if (!(lookup = X509_STORE_add_lookup(mystore, X509_LOOKUP_file()))){
        sprintf(errstring, "Error creating X509_LOOKUP object");
        goto err;
    }

    return mystore;
    err:
    return NULL;
}


/*
 * Restituisce la stringa descrittiva dell'errore
 */
char *
getErrStr(){
    return errstring;
}


/*
* load_cert: certificate load
*
* RETURN X509 obj se ok, 0 altrimenti
*/
static X509 *
load_cert(char *cname){
    BIO *fbio;
    X509 *x = NULL;

    fbio = BIO_new_file(cname, "rb");
    if(!fbio) {
        //ERR_print_errors_fp(stdout);
        return 0;
    }

    x = PEM_read_bio_X509_AUX(fbio, NULL, NULL, NULL);

    BIO_free(fbio);

    return x;
}


/*
* load_engine: engine load
*
* return ENGINE se ok, 0 altrimenti
*/
static ENGINE *
load_engine(char *eng, char *libpath) {
    ENGINE *e;

    ENGINE_load_builtin_engines();

    e = ENGINE_by_id(eng);
    if(!e) {
        //ERR_print_errors_fp(stdout);
        return 0;
    }

    //  if(!ENGINE_ctrl_cmd_string(e, "SO_PATH", lib, 0)) {
    //    ENGINE_free(e);
    //    return 0;
    //  }

    //if(!ENGINE_ctrl_cmd_string(e,
    //                 "SO_PATH",
    //                libpath, 0)) {
    //    ENGINE_free(e);
    //    return 0;
    //}

    //if(!ENGINE_ctrl_cmd_string(e,
    //                 "THREAD_LOCKING",
    //                 "1", 0)) {
    //    //ERR_print_errors_fp(stdout);
    //    ENGINE_free(e);
    //    return 0;
    //}

    //if(!ENGINE_ctrl_cmd_string(e,
    //                 "FORK_CHECK",
    //                 "1", 0)) {
    //    //ERR_print_errors_fp(stdout);
    //    ENGINE_free(e);
    //    return 0;
    //}

    if(!ENGINE_init(e)) {
        //ERR_print_errors_fp(stdout);
        ENGINE_free(e);
        return 0;
    }

    if(!ENGINE_set_default(e, ENGINE_METHOD_ALL)) {
        //ERR_print_errors_fp(stdout);
        ENGINE_free(e);
        return 0;
    }

    ENGINE_free(e);

    return e;
}


/*
 * Inizializzazione:
 * imposta il certificato di root e il path dove ricercare eventuali certificati
 * per la verifica della catena
 *
 * return 0 se ok, 1 altrimenti e imposta la var errstring
 */
int
init(   char *cert_dir,
        char *cert_file,
        char *key_file,
        char **other_cert,
        int other_cert_num,
        char *engine_name,
        char *libeng_file){
    DIR *dd;

    strcpy(errstring,"");

    if(init_status){
//        free_init();
//        ENGINE_finish(eng);
//        ENGINE_free(eng);
//        ENGINE_cleanup();
//
//        init_status = 0;
        return 0;
    }else{
        SSL_library_init();
        OpenSSL_add_all_algorithms();
        ERR_load_crypto_strings();
    }

    // ca path existence check
    if( (dd = opendir(cert_dir)) == NULL ){
        sprintf(errstring, "Error to access to CA path: %s", cert_dir);
        destroy_ui_method();
        return 1;
    }
    closedir(dd);
    ca_dir = cert_dir;

    if (!(store = create_store())){
        destroy_ui_method();
        sprintf(errstring, "Error setting up X509_STORE object");
        return 1;
    }

    // load signer certificate
    (signer) = load_cert(cert_file);
    if(!(signer)) {
        destroy_ui_method();
        sprintf(errstring, "Error to load certificate file: %s", cert_file);
        return 1;
    }

    // load certs to add to SMIME schema during the sign process
    if(other_cert_num && other_cert_num <= MAX_CERTS){
        int i;
        other4sign = sk_X509_new_null();

        for(i=0; i<other_cert_num; i++){
            X509 *tmp;
            FILE *fp;
            if (!(fp = fopen(other_cert[i], "r")) || !(tmp = PEM_read_X509(fp, NULL, NULL, NULL))){
                destroy_ui_method();
                sprintf(errstring, "Error reading chain certificate");
                return 1;
            }
            sk_X509_push(other4sign, tmp);
            fclose(fp);
        }
    }

    sign = &sign_old;
    if( engine_name && strcmp(engine_name,"openssl") != 0 ) {
       // LOAD ENGINE HW
        eng = load_engine(engine_name, libeng_file);
        if(!(eng)) {
            destroy_ui_method();
            sprintf(errstring, "Error to load engine: %s (%s)", engine_name, libeng_file);
            return 1;
        }

        if( !(pkey = ENGINE_load_private_key(eng, key_file, ui_method, NULL)) ){
            destroy_ui_method();
            ENGINE_cleanup();
            sprintf(errstring, "Error to load private key file: %s", key_file);
            return 1;
        }
     } else {
        FILE *fp;
        if (!(fp = fopen(key_file, "r")) ||
            !(pkey = PEM_read_PrivateKey(fp, NULL, NULL, NULL))){

            destroy_ui_method();
            sprintf(errstring, "Error to access to key file: %s", key_file);
            return 1;
        }
       close((int)(uintptr_t)fp);
     }

    init_status = 1;
    return 0;
}



/*
 * sign: sign the file "fname"
 *
 *  FIRMA
 *  /usr/local/bin/openssl smime -sign -signer /home/flazan/SMIME/CERTS/cert.pem -certfile /home/flazan/SMIME/CERTS/CnipaCA2.crt -inkey /home/flazan/SMIME/CERTS/key.pem -in /home/flazan/SMIME/MAIL/mail.txt -out /home/flazan/SMIME/MAIL/mail.txt.signed
 *
 * 1. path mail to sign (input)
 * 2. path mail signed (output)
 *
 * return 0 se ok, 1 altrimenti e imposta la var errstring
 */
int
sign_old(char *fname, char *outfname){
    BIO *biom, *out;
    PKCS7 *r;
    //STACK_OF(X509) *other = NULL;
    strcpy(errstring,"");

    if(!init_status){
        sprintf(errstring, "init must be run correctly");
        return 1;
    }


    biom = BIO_new_file(fname, "r");
    if(!biom) {
        sprintf(errstring, "Error to access to file: %s", fname);
        return 1;
    }

    //r = PKCS7_sign(signer, pkey, other, biom, PKCS7_DETACHED);
    r = PKCS7_sign(signer, pkey, other4sign, biom, PKCS7_DETACHED);
    if(!r) {
        ERR_print_errors_fp(stdout);
        sprintf(errstring, "Error to sign file %s", fname);
        BIO_free(biom);
        return 1;
    }
    if(BIO_reset(biom) != 0) {
        //ERR_print_errors_fp(stdout);
        sprintf(errstring, "Error to free BIO object");
        BIO_free(biom);
        return 1;
    }

    out = BIO_new_file(outfname, "w+");
    if(out) {
        SMIME_write_PKCS7(out, r, biom, PKCS7_DETACHED);
    } else {
        //ERR_print_errors_fp(stdout);
        sprintf(errstring, "Error to write signed file %s", outfname);
        BIO_free(biom);
        return 1;
    }

    BIO_free(out);
    BIO_free(biom);
    PKCS7_free(r);

    if(eng){ENGINE_cleanup();}

    return 0;
}

/*
 * Verifica un messaggio SMIME
 * (il path dove trovare la catena dei cert e' in var globale)
 *
 *  VERIFICA
 *  - verifica la catena
 *  /usr/local/bin/openssl smime -verify -signer /home/flazan/SMIME/CERTS/cert.pem -CApath /home/flazan/SMIME/CERTS/ -in /home/flazan/SMIME/MAIL/mail.txt.signed
 *  - non verifica la catena
 *  /usr/local/bin/openssl smime -verify -signer /home/flazan/SMIME/CERTS/cert.pem -CApath /home/flazan/SMIME/CERTS/ -in /home/flazan/SMIME/MAIL/mail.txt.signed -noverify
 *
 * 1. path file msg SMIME da verificare
 * 2. path file certs signer
 * 3. boolean: se true non verifica la catena, false altrimenti
 *
 * return 0 se ok, diverso da 0 altrimenti e imposta la var errstring
 */
int
verify (char *smime_file, char *signer_file, int noverify){
    BIO *bio_mail, *bio_pkcs7;
    PKCS7 *pkcs7;
    int flag;
    int out;

    strcpy(errstring,"");

    if(!init_status){
        sprintf(errstring, "init must be run correctly");
        return 1;
    }

    if(noverify){
        flag = 32;
    }else{
        flag = 0;
    }

    bio_mail = BIO_new_file(smime_file, "r");
    if (!(pkcs7 = SMIME_read_PKCS7(bio_mail, &bio_pkcs7))){
        sprintf(errstring, "Error to access to mail file: %s", smime_file);
        goto err;
    }

    if ( (out = PKCS7_verify(pkcs7, NULL, store, bio_pkcs7, NULL, flag) ) != 1){
        sprintf(errstring, "Verify failed, %d", out);
        PKCS7_free(pkcs7);
        goto err;
    }

    // save the signer certs
    if(signer_file){
        STACK_OF(X509) *signers;
        signers = PKCS7_get0_signers(pkcs7, NULL, flag);
        if(!save_certs(signer_file, signers)) {
            sprintf(errstring, "Error writing signers to %s", signer_file);
            goto err;
        }
        sk_X509_free(signers);
    }

    sprintf(errstring, "Verify Ok");

    PKCS7_free(pkcs7);
    BIO_free_all(bio_mail);
    BIO_free_all(bio_pkcs7);
    return 0;

    err:
    BIO_free_all(bio_mail);
    BIO_free_all(bio_pkcs7);
    return 1;
}

/*
 * Get cert data
 *
 * 1. path file cert
 * 2. srtuct INFOCERT to get output
 *
 * 1. issuer
 * 2. subject
 * 3. serial
 * 4. startdate
 * 5. enddate
 * 6. v3_email
 *
 * INFOCERT se ok, null altrimenti e imposta la var errstring
 */
int
getCertInfo(char *file_cert, INFOCERT *x509_out){
    FILE *fp;
    X509 *cert;
    char *tmp;
    int n;
    BIO *outmem = BIO_new(BIO_s_mem());
    STACK_OF(OPENSSL_STRING) *emlst;

    strcpy(errstring,"");

    /*
    char *issuer;
    char *subject;
    char *serial;
    char *startdate;
    char *enddate;
    char *v3_email;
    */

    /* read the signer certificate */
    if (!(fp = fopen(file_cert, "r")) ||
        !(cert = PEM_read_X509(fp, NULL, NULL, NULL))){

        sprintf(errstring, "Error reading CA certificate in %s", file_cert);
        goto err;
    }
    fclose(fp);

    // issuer
    X509_NAME_print_ex(outmem, X509_get_issuer_name(cert), 0,0);
    n = BIO_get_mem_data(outmem, &tmp);
    x509_out->issuer = malloc (n+1);
    x509_out->issuer[n]='\0';
    memcpy(x509_out->issuer,tmp,n);
    BIO_free(outmem);
    outmem = NULL;

    // subject
    outmem = BIO_new(BIO_s_mem());
    X509_NAME_print_ex(outmem, X509_get_subject_name(cert), 0,0);
    n = BIO_get_mem_data(outmem, &tmp);
    x509_out->subject = malloc (n+1);
    x509_out->subject[n]='\0';
    memcpy(x509_out->subject,tmp,n);
    BIO_free(outmem);
    outmem = NULL;

    // serial
    outmem = BIO_new(BIO_s_mem());
    i2a_ASN1_INTEGER(outmem, cert->cert_info->serialNumber);
    n = BIO_get_mem_data(outmem, &tmp);
    x509_out->serial = malloc (n+1);
    x509_out->serial[n]='\0';
    memcpy(x509_out->serial,tmp,n);
    BIO_free(outmem);
    outmem = NULL;

    // startdate
    outmem = BIO_new(BIO_s_mem());
    ASN1_TIME_print(outmem, X509_get_notBefore(cert));
    n = BIO_get_mem_data(outmem, &tmp);
    x509_out->startdate = malloc (n+1);
    x509_out->startdate[n]='\0';
    memcpy(x509_out->startdate,tmp,n);
    BIO_free(outmem);
    outmem= NULL;

    // enddate
    outmem = BIO_new(BIO_s_mem());
    ASN1_TIME_print(outmem, X509_get_notAfter(cert));
    n = BIO_get_mem_data(outmem, &tmp);
    x509_out->enddate = malloc (n+1);
    x509_out->enddate[n]='\0';
    memcpy(x509_out->enddate,tmp,n);
    BIO_free(outmem);
    outmem = NULL;

    emlst = X509_get1_email(cert);
    if(sk_num((STACK_OF(OPENSSL_STRING) *)emlst)>0){
      /* prendo solo il primo */
      n = strlen(sk_value((STACK_OF(OPENSSL_STRING) *)emlst, 0) );
      x509_out->v3_email = malloc (n+1);
      x509_out->v3_email[n] = '\0';
      memcpy(x509_out->v3_email,sk_value((STACK_OF(OPENSSL_STRING) *)emlst, 0),n);
      X509_email_free((STACK_OF(OPENSSL_STRING) *)emlst);
    }else{
      x509_out->v3_email = malloc (1);
      x509_out->v3_email[0] = '\0';
    }
    X509_free(cert);

    return 0;

    err:
    return 1;
}


/*
 * Get FINGERPRINT
 * ( openssl x509 -in "/home/flazan/SMIME/mycert.pem" -fingerprint -sha1 -noout )
 *
 * - ESEMPIO di chiamata
 *  int main(int argc, char **argv){
 *      int out;
 *      char *str;
 *      str = (char *) malloc (40);
 *
 *      out = getFingerprint("/home/flazan/SMIME/mycert.pem", "mdc2", &str);
 *      if(!out){
 *          printf("%d) fingerprint: %s\n", k, str);
 *      }else{
 *          printf("Errore: %s\n", getErrStr());
 *      }
 *      free(&str);
 *  }
 *
 * 1. path file cert
 * 2. hash schema (md2/md5/sha1)
 * 3. param to out
 *
 * 0 se ok, 1 altrimenti e imposta la var errstring
 */
int
getFingerprint (char *filecert, char *hschema, char **strOut) {
    X509 *c = NULL;
    const EVP_MD *digest = NULL;
    char *strTmp;
    unsigned int n;
    unsigned char md[EVP_MAX_MD_SIZE];
    int j;

    strcpy(errstring,"");

    c = load_cert(filecert);

    if(!(c)) {
        sprintf(errstring, "Error to load certificate: %s", filecert);
        return 1;
    }

    #ifndef OPENSSL_NO_SHA
    if( !strcmp(hschema,"sha1") ){
        digest = EVP_sha1();
    }
    #endif
    #ifndef OPENSSL_NO_MD5
    if( !strcmp(hschema,"md5") ){
        digest = EVP_md5();
    }
    #endif
    #ifndef OPENSSL_NO_MD2
    if( !strcmp(hschema,"md2") ){
        digest = EVP_md2();
    }
    #endif
    if(!digest){
        sprintf(errstring, "Unknown schema: %s", hschema);
        X509_free(c);
        return 1;
    }

    if (!X509_digest(c,digest,md,&n)){
      sprintf(errstring, "out of memory");
      X509_free(c);
      return 1;
    }
    X509_free(c);

    *strOut = (char *) malloc (sizeof(md)+20);
    strTmp = (char *) malloc (4);
    **strOut = (char )(uintptr_t) NULL;
    *strTmp = (char )(uintptr_t) NULL;
    for (j=0; j<(int)n; j++){
      sprintf(strTmp,"%02X%c",md[j],(j+1 == (int)n)?'\0':':');
      *strOut = strcat(*strOut, strTmp);
    }
    free(strTmp);

    return 0;
}

void
free_infocert(INFOCERT *x){
        free(x->issuer);
        free(x->subject);
        free(x->serial);
        free(x->startdate);
        free(x->enddate);
        free(x->v3_email);
}

void
free_init(){
    X509_free(signer);
    sk_X509_pop_free(other4sign, X509_free);
    X509_STORE_free(store);
    EVP_PKEY_free(pkey);
    destroy_ui_method();
}

int
save_certs(char *signerfile, STACK_OF(X509) *signers){
        int i;
        BIO *tmp;
        if(!signerfile) return 1;
        tmp = BIO_new_file(signerfile, "w");
        if(!tmp) return 0;
        for(i = 0; i < sk_X509_num(signers); i++)
                PEM_write_bio_X509(tmp, sk_X509_value(signers, i));
        BIO_free(tmp);
        return 1;
}

/*
 * Restiruisce gli estremi di openssl
 *
 * Parametri
 * 0 - versione (es. OpenSSL 0.9.7i 14 Oct 2005)
 * 2 - prametri di compilazione (es. compiler: gcc -DOPENSSL_THREADS ...)
 * 3 - data compilazione (es. built on: Mon Dec  3 16:44:16 CET 2007)
 * 4 - piattaforma (es. platform: debug-linux-pentium)
 * 5 - path di installazione (es. OPENSSLDIR: \"/usr/local/openssl\")
 *
 */
int
ossl_param(int param, char **strOut){
    *strOut = (char *) SSLeay_version(param);
    return 1;
}

int
load_privk(char *prk, char *ncert){
    strcpy(errstring,"");

    if(pkey){
        EVP_PKEY_free(pkey);
    }
    if(signer){
        X509_free(signer);
    }

    // load key
    if( eng ){
        // ENGINE HW
        if( !(pkey = ENGINE_load_private_key(eng, prk, ui_method, NULL)) ){
            destroy_ui_method();
            ENGINE_cleanup();
            sprintf(errstring, "Error to load private key file: %s", prk);
            return 1;
        }
    }else{
        // ENGINE SW
        FILE *fp;
        if (!(fp = fopen(prk, "r")) ||
            !(pkey = PEM_read_PrivateKey(fp, NULL, NULL, NULL))){

            destroy_ui_method();
            sprintf(errstring, "Error to access to key file: %s", prk);
            return 1;
        }
        close((int)(uintptr_t)fp);
    }

    //load cert
    // load signer certificate
    (signer) = load_cert(ncert);
    if(!(signer)) {
        destroy_ui_method();
        sprintf(errstring, "Error to load certificate file: %s", ncert);
        return 1;
    }

    return 0;

}

/*
 * Return a selected type digest of input file
 *
 * 1 - input file path
 * 2 - hash type
 * 3 - calculated hash
 *
 * o se ok, 1 altrimenti e popola errstr
 */

int
digest(char *fname, char *dname, char **digestOut){

    const EVP_MD *dtype;
    EVP_MD_CTX *mdctx;
    int i, data_count;
    unsigned int dtype_len;
    FILE *fp;
    char *data;
    unsigned char digest_str[EVP_MAX_MD_SIZE];
    char* digestStart;
    strcpy(errstring,"");

    // initialize hash context and retrieve digest type by name
    OpenSSL_add_all_digests();
    if(!(dtype = EVP_get_digestbyname(dname))) {
        sprintf(errstring, "Unknown message digest: %s", dname);
        return 1;
    }

    // retrieve data to hash
    if (!(fp = fopen(fname, "r"))) {
        sprintf(errstring, "Error to open file to hash: %s", fname);
        return 1;
    }

    data = malloc(DIGEST_BUFF_SIZE);

    // hash calculation
    mdctx = EVP_MD_CTX_create();
    EVP_DigestInit_ex(mdctx, dtype, NULL);
    while ((data_count = fread(data,1,DIGEST_BUFF_SIZE,fp)) == DIGEST_BUFF_SIZE)
        EVP_DigestUpdate(mdctx, data, data_count);
    EVP_DigestUpdate(mdctx, data, data_count);
    EVP_DigestFinal_ex(mdctx, digest_str, &dtype_len);

    // clean
    EVP_MD_CTX_destroy(mdctx);
    fclose(fp);
    free(data);

    //output
    *digestOut = malloc(sizeof(char*) * dtype_len);
    digestStart = *digestOut;
    for(i = 0; i < dtype_len; i++)
    {
        sprintf(*digestOut, "%02x", digest_str[i]);
        (*digestOut)+=2;
    }

    *digestOut = digestStart;

    return 0;
}

/*********************************/

MODULE = Crypt::SMimeEngine             PACKAGE = Crypt::SMimeEngine

SV *
getErrStr()
    CODE:
        RETVAL = newSVpv(getErrStr(),0);
    OUTPUT:
        RETVAL

SV *
getCertInfo(file_cert)
        char *file_cert;
    INIT:
        int i;
        struct INFOCERT x509;
    CODE:
        i = getCertInfo(file_cert, &x509);
        if(i == 0){
            HV * rh;
            SV **tmp;
            rh = (HV *)sv_2mortal((SV *)newHV());

            tmp = hv_store(rh, "issuer", 6, newSVpv(x509.issuer, 0), 0);
            tmp = hv_store(rh, "subject", 7, newSVpv(x509.subject,0), 0);
            tmp = hv_store(rh, "serial", 6, newSVpv(x509.serial,0), 0);
            tmp = hv_store(rh, "startdate", 9, newSVpv(x509.startdate,0), 0);
            tmp = hv_store(rh, "enddate", 7, newSVpv(x509.enddate,0), 0);
            tmp = hv_store(rh, "v3_email", 8, newSVpv(x509.v3_email,0), 0);

            if (tmp == NULL)
              ;

            free_infocert(&x509);

            RETVAL = newRV((SV *)rh);
        }else{
            XSRETURN_UNDEF;
        }
    OUTPUT:
            RETVAL

int
verify(smime, signer_file, noverify)
        char *smime;
        char *signer_file;
        int noverify;
    CODE:
        RETVAL = verify(smime, signer_file, noverify);
    OUTPUT:
        RETVAL

int
sign(fname, outfname)
        char *fname;
        char *outfname;
    CODE:
        RETVAL = sign(fname, outfname);
    OUTPUT:
        RETVAL

SV *
getFingerprint(filecert, hschema)
        char *filecert;
        char *hschema;
    INIT:
        char *strOut;
        int intOut;
    CODE:
        intOut = getFingerprint(filecert, hschema, &strOut);
        if(intOut == 0){
            RETVAL = newSVpv(strOut,0);
            free(strOut);
        }else{
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

SV *
ossl_param(par)
        int par;
    INIT:
        char *strOut;
    CODE:
        ossl_param(par, &strOut);
        RETVAL = newSVpv(strOut,0);
        free(strOut);
    OUTPUT:
        RETVAL

int
initialize(cert_dir, cert_file, key_file, other_cert, engine_name, libeng_file)
        char * cert_dir
        char * cert_file
        char * key_file
        SV * other_cert
        char * engine_name
        char * libeng_file
    CODE:
        I32 num_other_cert = 0;
        int i;
        char * other_cert_tmp[num_other_cert];

        num_other_cert = av_len((AV *)SvRV(other_cert))+1;
        for(i=0;i<num_other_cert;i++){
            STRLEN l;
            other_cert_tmp[i] = SvPV(*av_fetch((AV *)SvRV(other_cert),i,0),l);
        }
        RETVAL = init(cert_dir, cert_file, key_file, other_cert_tmp, num_other_cert, engine_name, libeng_file);
    OUTPUT:
        RETVAL

int
load_privk(privk, newcert)
        char *privk;
        char *newcert;
    CODE:
        RETVAL = load_privk(privk, newcert);
    OUTPUT:
        RETVAL

SV *
digest(fname, dname)
        char * fname
        char * dname
    INIT:
        char* digestOut;
        int intOut;
    CODE:
        intOut = digest(fname, dname, &digestOut);
        if (intOut == 0){
            RETVAL = newSVpv(digestOut,0);
            free(digestOut);
        }else{
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL
