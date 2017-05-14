
#include "bitpay.h"

static int createNewKey(EC_GROUP *group, EC_KEY *eckey);
static int createDataWithHexString(char *inputString, uint8_t **result);
static int base58encode(char *input, char *base58encode);
static int digestOfBytes(uint8_t *message, char **output, char *type, int inLength);
static int toHexString(char *input, int inLength, char **output);

int generatePem(char **pem) {
    int returnError = NOERROR;
    char * errorMessage = "";
    char *pemholder = calloc(240, sizeof(char));
    EC_KEY *eckey = NULL;
    BIO *out = NULL;

    if ((out = BIO_new(BIO_s_mem())) == NULL) {
        returnError = ERROR;
        errorMessage = "Error in BIO_new(BIO_s_mem())";
        goto clearVariables;
    }
    
    BUF_MEM *buf = NULL;
    EC_GROUP *group = NULL;
    
    if ((group = EC_GROUP_new_by_curve_name(NID_secp256k1)) == NULL) {
        returnError = ERROR;
        errorMessage = "Error in EC_GROUP_new_by_curve_name(NID_secp256k1))";
        goto clearVariables;
    }

    if (((eckey = EC_KEY_new()) == NULL) ||
        ((buf = BUF_MEM_new()) == NULL)) {
        returnError = ERROR;
        errorMessage = "Error in EC_KEY_new())";
        goto clearVariables;
    };

    if (createNewKey(group, eckey) == ERROR) {
        returnError = ERROR;
        errorMessage = "createNewKey(group, eckey)";
        goto clearVariables;
    }

    if (PEM_write_bio_ECPrivateKey(out, eckey, NULL, NULL, 0, NULL, NULL) == 0) {
        printf("PEM_write_bio_ECPrivateKey error");
    }

    BIO_get_mem_ptr(out, &buf);

    memcpy(pemholder, buf->data, 224);
    if (buf->data[218] == '\n') {
        pemholder[219] = '\0';
        memcpy(*pem, pemholder, 220);
    } else if ( buf->data[219] == '\n') {
        pemholder[220] = '\0';       
        memcpy(*pem, pemholder, 221);
    } else if ( buf->data[221] == '\n') {
        pemholder[222] = '\0';       
        memcpy(*pem, pemholder, 223);
    } else if (buf->data[222] == '\n') {
        pemholder[223] = '\0';
        memcpy(*pem, pemholder, 224);
    } else {
        returnError = ERROR;
        errorMessage = "invalid PEM generated";
        goto clearVariables;
    }

    goto clearVariables;

clearVariables:
    if (group != NULL)
        EC_GROUP_clear_free(group);
    if (pemholder != NULL) 
        free(pemholder);
    if (eckey != NULL)
        EC_KEY_free(eckey);
    if (out != NULL)
        BIO_free_all(out);
    if (errorMessage[0] != '\0')
        printf("Error: %s\n", errorMessage);

    return returnError;
};

static int createNewKey(EC_GROUP *group, EC_KEY *eckey) {

    int asn1Flag = OPENSSL_EC_NAMED_CURVE;
    int form = POINT_CONVERSION_UNCOMPRESSED;

    EC_GROUP_set_asn1_flag(group, asn1Flag);
    EC_GROUP_set_point_conversion_form(group, form);
    int setGroupError = EC_KEY_set_group(eckey, group);

    int resultFromKeyGen = EC_KEY_generate_key(eckey);

    if (resultFromKeyGen != 1 || setGroupError != 1){
        return ERROR;
    }

    return NOERROR;
}

int generateSinFromPem(char *pem, char **sin) {
    
    char *pub =     calloc(67, sizeof(char));

    u_int8_t *outBytesPub = calloc(SHA256_STRING, sizeof(u_int8_t));
    u_int8_t *outBytesOfStep1 = calloc(SHA256_STRING, sizeof(u_int8_t));
    u_int8_t *outBytesOfStep3 = calloc(RIPEMD_AND_PADDING_STRING, sizeof(u_int8_t));
    u_int8_t *outBytesOfStep4a = calloc(SHA256_STRING, sizeof(u_int8_t));

    char *step1 =   calloc(SHA256_HEX_STRING, sizeof(char));
    char *step2 =   calloc(RIPEMD_HEX_STRING, sizeof(char));
    char *step3 =   calloc(RIPEMD_AND_PADDING_HEX_STRING, sizeof(char));
    char *step4a =  calloc(SHA256_HEX_STRING, sizeof(char));
    char *step4b =  calloc(SHA256_HEX_STRING, sizeof(char));
    char *step5 =   calloc(CHECKSUM_STRING, sizeof(char));
    char *step6 =   calloc(RIPEMD_AND_PADDING_HEX + CHECKSUM_STRING, sizeof(char));

    char *base58OfStep6 = calloc(SIN_STRING, sizeof(char));

    getPublicKeyFromPem(pem, &pub);
    pub[66] = '\0';

    createDataWithHexString(pub, &outBytesPub);
    digestOfBytes(outBytesPub, &step1, "sha256", SHA256_STRING);
    step1[64] = '\0';

    createDataWithHexString(step1, &outBytesOfStep1);
    digestOfBytes(outBytesOfStep1, &step2, "ripemd160", SHA256_DIGEST_LENGTH);
    step2[40] = '\0';
   
    memcpy(step3, "0F02", 4);
    memcpy(step3+4, step2, RIPEMD_HEX);
    step3[44] = '\0';

    createDataWithHexString(step3, &outBytesOfStep3);
    digestOfBytes(outBytesOfStep3, &step4a, "sha256", RIPEMD_AND_PADDING);
    step4a[64] = '\0';

    createDataWithHexString(step4a, &outBytesOfStep4a);
    digestOfBytes(outBytesOfStep4a, &step4b, "sha256", SHA256_DIGEST_LENGTH);
    step4b[64] = '\0';

    memcpy(step5, step4b, CHECKSUM);
    
    sprintf(step6, "%s%s", step3, step5);
    step6[RIPEMD_AND_PADDING_HEX + CHECKSUM] = '\0';

    base58encode(step6, base58OfStep6);
    base58OfStep6[SIN] = '\0'; 
    memcpy(*sin, base58OfStep6, SIN_STRING);

    free(pub);  
    free(step1);
    free(step2);
    free(step3);
    free(step4a);
    free(step4b);
    free(step5);
    free(step6);
    free(base58OfStep6);

    free(outBytesPub);
    free(outBytesOfStep1);
    free(outBytesOfStep3);
    free(outBytesOfStep4a);
    return NOERROR;
}

int getPublicKeyFromPem(char *pemstring, char **pubkey) {

    EC_KEY *eckey = NULL;
    EC_KEY *key = NULL;
    EC_POINT *pub_key = NULL;
    BIO *in = NULL;
    const EC_GROUP *group = NULL;
    char *hexPoint = NULL;
    char xval[65] = "";
    char yval[65] = "";
    char *oddNumbers = "13579BDF";

    BIGNUM start;
    const BIGNUM *res;
    BN_CTX *ctx;

    BN_init(&start);
    ctx = BN_CTX_new();

    res = &start;

    const char *cPem = pemstring;
    in = BIO_new(BIO_s_mem());
    BIO_puts(in, cPem);
    key = PEM_read_bio_ECPrivateKey(in, NULL, NULL, NULL);
    res = EC_KEY_get0_private_key(key);
    eckey = EC_KEY_new_by_curve_name(NID_secp256k1);
    group = EC_KEY_get0_group(eckey);
    pub_key = EC_POINT_new(group);

    EC_KEY_set_private_key(eckey, res);

    if (!EC_POINT_mul(group, pub_key, res, NULL, NULL, ctx)) {
        return ERROR;
    }

    EC_KEY_set_public_key(eckey, pub_key);

    hexPoint = EC_POINT_point2hex(group, pub_key, 4, ctx);

    char *hexPointxInit = hexPoint + 2;
    memcpy(xval, hexPointxInit, 64);

    char *hexPointyInit = hexPoint + 66;
    memcpy(yval, hexPointyInit, 64);

    char *lastY = hexPoint + 129;
    hexPoint[130] = '\0';

    char *buildCompPub = calloc(67, sizeof(char));

    if (strstr(oddNumbers, lastY) != NULL) {
        sprintf(buildCompPub, "03%s", xval);
        buildCompPub[66] = '\0';
        memcpy(*pubkey, buildCompPub, 67);
    } else {
        sprintf(buildCompPub, "02%s", xval);
        buildCompPub[66] = '\0';
        memcpy(*pubkey, buildCompPub, 67);
    }

    free(buildCompPub);
    BN_CTX_free(ctx);
    EC_KEY_free(eckey);
    EC_KEY_free(key);
    EC_POINT_free(pub_key);
    BIO_free(in);

    return NOERROR;
};

static int createDataWithHexString(char *inputString, uint8_t **result) {

    int i, o = 0;
    uint8_t outByte = 0;

    int inLength = strlen(inputString);

    uint8_t *outBytes = malloc(sizeof(uint8_t) * ((inLength / 2) + 1));

    for (i = 0; i < inLength; i++) {
        uint8_t c = inputString[i];
        int8_t value = -1;

        if      (c >= '0' && c <= '9') value =      (c - '0');
        else if (c >= 'A' && c <= 'F') value = 10 + (c - 'A');
        else if (c >= 'a' && c <= 'f') value = 10 + (c - 'a');

        if (value >= 0) {
            if (i % 2 == 1) {
                outBytes[o++] = (outByte << 4) | value;
                outByte = 0;
            } else {
                outByte = value;
            }

        } else {
            if (o != 0) break;
        }
    }

    memcpy(*result, outBytes, inLength/2);

    free(outBytes);

    return NOERROR;
}

static int base58encode(char *input, char *base58encode) {
    BIGNUM *bnfromhex = BN_new();
    BN_hex2bn(&bnfromhex, input);
    char *codeString = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    char buildString[35];
    int lengthofstring = 0;
    int startat = 34;

    while(BN_is_zero(bnfromhex) != 1){
      int rem = BN_mod_word(bnfromhex, 58);
      buildString[startat] = codeString[rem];
      BN_div_word(bnfromhex, 58);
      lengthofstring++;
      startat--;
    }
    startat ++;
    
    int j = 0;
    int i;
    for (i = startat; i < lengthofstring; i++) {
      base58encode[j] = buildString[i];
      j++;
    }

    BN_free(bnfromhex);

    return NOERROR;
}

static int digestOfBytes(uint8_t *message, char **output, char *type, int inLength) {
    EVP_MD_CTX *mdctx;
    const EVP_MD *md;
    unsigned char md_value[EVP_MAX_MD_SIZE];
    unsigned int md_len, i;

    OpenSSL_add_all_digests();

    md = EVP_get_digestbyname(type);
    mdctx = EVP_MD_CTX_create();
    EVP_DigestInit_ex(mdctx, md, NULL);
    EVP_DigestUpdate(mdctx, message, inLength);
    EVP_DigestFinal_ex(mdctx, md_value, &md_len);
    EVP_MD_CTX_destroy(mdctx);

    char *digest = calloc((md_len*2) + 1, sizeof(char));
    for(i = 0; i < md_len; i++){
      sprintf(&digest[2*i], "%02x", md_value[i]);
    };
    digest[md_len * 2] = '\0';
    memcpy(*output, digest, strlen(digest));
    free(digest);
    /* Call this once before exit. */
    //EVP_cleanup();
    return 0;
}

static int toHexString(char *input, int inLength, char **output) {
    
    uint8_t *byteData = (uint8_t*)malloc(inLength);
    memcpy(byteData, input, inLength);

    unsigned int i;
    char *digest = calloc((inLength*2) + 1, sizeof(char));

    for (i = 0; i < inLength; i++) {
        sprintf(&digest[2*i], "%02x", byteData[i]);
    }

    memcpy(*output, digest, strlen(digest));
    free(digest);
    return NOERROR;
}

int signMessageWithPem(char *message, char *pem, char **signature) {

    unsigned int meslen = strlen(message);
    unsigned char *messagebytes = calloc(meslen, sizeof(unsigned char));
    int derSigLen = 0;
    int i = 0;
    memcpy(messagebytes, message, meslen);

    EC_KEY *key = NULL;
    BIO *in = NULL;
    unsigned char *buffer = NULL;

    char *sha256ofMsg = calloc(SHA256_HEX_STRING, sizeof(char));
    unsigned char *outBytesOfsha256ofMsg = calloc(SHA256_STRING, sizeof(unsigned char));

    digestOfBytes(messagebytes, &sha256ofMsg, "sha256", meslen);
    sha256ofMsg[64] = '\0';
    createDataWithHexString(sha256ofMsg, &outBytesOfsha256ofMsg);
    
    in = BIO_new(BIO_s_mem());
    BIO_puts(in, pem);
    key = PEM_read_bio_ECPrivateKey(in, NULL, NULL, NULL);
    
    if(key == NULL){
       return ERROR;
    } 
    while(derSigLen < 70 && i < 10){
        i++;
        ECDSA_SIG *sig = ECDSA_do_sign((const unsigned char*)outBytesOfsha256ofMsg, SHA256_DIGEST_LENGTH, key);
        
        int verify = ECDSA_do_verify((const unsigned char*)outBytesOfsha256ofMsg, SHA256_DIGEST_LENGTH, sig, key);
        
        if(verify != 1) {
            return ERROR;
        }

        int buflen = ECDSA_size(key);
        buffer = OPENSSL_malloc(buflen);

        derSigLen = i2d_ECDSA_SIG(sig, &buffer);
    }
    if(i == 10)
        return ERROR;
    char *hexData = calloc(derSigLen, sizeof(char));
    memcpy(hexData, buffer-derSigLen, derSigLen);

    char *hexString = calloc(derSigLen*2+1, sizeof(char));

    toHexString(hexData, derSigLen, &hexString);
    hexString[derSigLen * 2] = '\0';
    
    memcpy(*signature, hexString, (derSigLen*2)+ 1);

    EC_KEY_free(key);

    BIO_free_all(in);
    free(sha256ofMsg);
    free(outBytesOfsha256ofMsg);
    free(hexData);
    free(hexString);

    return NOERROR;
}
