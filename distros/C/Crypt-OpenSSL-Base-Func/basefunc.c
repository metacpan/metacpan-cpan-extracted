EVP_PKEY* evp_pkey_from_point_hex(EC_GROUP* group, char* point_hex, BN_CTX* ctx)  {
    EC_KEY* ec_key = EC_KEY_new();
    EC_KEY_set_group(ec_key, group);

    EC_POINT* ec_pub_point = EC_POINT_new(group);
    ec_pub_point = EC_POINT_hex2point(group, point_hex, ec_pub_point, ctx);
    EC_KEY_set_public_key(ec_key, ec_pub_point);

    EVP_PKEY *pkey = EVP_PKEY_new();
    EVP_PKEY_assign_EC_KEY(pkey, ec_key);

    return pkey;
}

EVP_PKEY* evp_pkey_from_priv_hex(EC_GROUP* group, char* priv_hex)  {
    EC_KEY* ec_key = EC_KEY_new();
    EC_KEY_set_group(ec_key, group);
    EC_KEY_set_asn1_flag(ec_key, OPENSSL_EC_NAMED_CURVE);

    BIGNUM *priv_bn = BN_new();
    BN_hex2bn(&priv_bn, priv_hex);
    EC_KEY_set_private_key(ec_key, (const BIGNUM *) priv_bn);

    EC_POINT* ec_pub_point = EC_POINT_new(group);
    EC_POINT_mul(group, ec_pub_point, priv_bn, NULL, NULL, NULL);
    EC_KEY_set_public_key(ec_key, ec_pub_point);

    EVP_PKEY *pkey = EVP_PKEY_new();
    EVP_PKEY_assign_EC_KEY(pkey, ec_key);

    return pkey;
}

int pem_write_evp_pkey(char* dst_fname, EVP_PKEY* pkey, int is_priv)  {
    BIO *out;
    out = BIO_new_file(dst_fname, "w+");

    if(is_priv==1){
        PEM_write_bio_PrivateKey(out, pkey, NULL, NULL, 0, NULL, NULL);
    }else{
        PEM_write_bio_PUBKEY(out, pkey);
    }

    BIO_flush(out);

    return 1;
}

char* pem_read_priv_hex(char* keyfile) {

    FILE *inf = fopen(keyfile, "r");
    EVP_PKEY *pkey = NULL;
    pkey = PEM_read_PrivateKey(inf, NULL, NULL, NULL);

    EC_KEY *ec_key = EVP_PKEY_get1_EC_KEY(pkey);
    const BIGNUM *priv_bn = EC_KEY_get0_private_key(ec_key);
    char *priv_hex = BN_bn2hex(priv_bn);
    return priv_hex;
}

char* pem_read_pub_hex(char* keyfile, int point_compress_t) {

    FILE *inf = fopen(keyfile, "r");
    EVP_PKEY *pkey = NULL;
    pkey = PEM_read_PUBKEY(inf, NULL, NULL, NULL);

    EC_KEY *ec_key = EVP_PKEY_get1_EC_KEY(pkey);
    const EC_POINT *ec_point = EC_KEY_get0_public_key(ec_key);

    const EC_GROUP *group = EC_KEY_get0_group(ec_key);
    BN_CTX *ctx = BN_CTX_new();
    char *pub_hex = EC_POINT_point2hex(group, ec_point, point_compress_t, ctx);

    return pub_hex;
}


EVP_PKEY* pem_read_pkey(char* keyfile, int is_priv) {

    FILE *inf = fopen(keyfile, "r");

    EVP_PKEY *pkey = NULL;

    if(is_priv){
        pkey = PEM_read_PrivateKey(inf, NULL, NULL, NULL);
    }else{
        pkey = PEM_read_PUBKEY(inf, NULL, NULL, NULL);
    }

    return pkey;
}

int ecdh_pkey_raw(EVP_PKEY *pkey_priv, EVP_PKEY *pkey_peer_pub, unsigned char **z)
{
    size_t zlen;

    EVP_PKEY_CTX *ctx;
    ctx = EVP_PKEY_CTX_new(pkey_priv, NULL);

    EVP_PKEY_derive_init(ctx);

    EVP_PKEY_derive_set_peer(ctx, pkey_peer_pub);

    EVP_PKEY_derive(ctx, NULL, &zlen);

    *z = OPENSSL_malloc(zlen);

    EVP_PKEY_derive(ctx, *z, &zlen);

    return (int) zlen;
}

int aead_encrypt_raw(unsigned char *cipher_name, 
        unsigned char *plaintext, int plaintext_len,
                unsigned char *aad, int aad_len,
                unsigned char *key,
                unsigned char *iv, int iv_len,
                unsigned char **ciphertext_ref,
                unsigned char *tag, int tag_len)
{
    EVP_CIPHER_CTX *ctx;

    int len;
    int ciphertext_len;

    unsigned char *ciphertext = *ciphertext_ref;

    if(!(ctx = EVP_CIPHER_CTX_new()))
        return -1;

    const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);
    if(1 != EVP_EncryptInit_ex(ctx, cipher, NULL, NULL, NULL))
        return -1;

    if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL))
        return -1;

    if(1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv))
        return -1;

    if(1 != EVP_EncryptUpdate(ctx, NULL, &len, aad, aad_len))
        return -1;

    if(1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len))
        return -1;
    ciphertext_len = len;

    if(1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len))
        return -1;
    ciphertext_len += len;

    if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, tag_len, tag))
        return -1;

    EVP_CIPHER_CTX_free(ctx);

    return ciphertext_len;
}

int aead_decrypt_raw(
        unsigned char *cipher_name, 
        unsigned char *ciphertext, int ciphertext_len,
                unsigned char *aad, int aad_len,
                unsigned char *tag, int tag_len, 
                unsigned char *key,
                unsigned char *iv, int iv_len,
                unsigned char **plaintext_ref)
{
    EVP_CIPHER_CTX *ctx;
    int len;
    int plaintext_len;
    int ret;

    unsigned char *plaintext = *plaintext_ref;

    if(!(ctx = EVP_CIPHER_CTX_new()))
        return -1;

    const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);
    if(!EVP_DecryptInit_ex(ctx, cipher, NULL, NULL, NULL))
        return -1;

    if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL))
        return -1;

    if(!EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv))
        return -1;

    if(!EVP_DecryptUpdate(ctx, NULL, &len, aad, aad_len))
        return -1;

    if(!EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len))
        return -1;
    plaintext_len = len;

    if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, tag_len, tag))
        return -1;

    ret = EVP_DecryptFinal_ex(ctx, plaintext + len, &len);

    EVP_CIPHER_CTX_free(ctx);

    if(ret > 0) {
        plaintext_len += len;
        return plaintext_len;
    } else {
        return -1;
    }
}

/*unsigned char* hex2bin(const char *hexstr) {*/

    /*size_t hexstrLen = strlen(hexstr);*/
    /*size_t bytesLen = hexstrLen / 2;*/
    /*unsigned char* binstr = (unsigned char*) malloc(bytesLen);*/

    /*BIGNUM *a = BN_new();*/
    /*BN_hex2bn(&a, hexstr);*/
    /*BN_bn2bin(a, binstr);*/

    /*return binstr;*/
/*}*/

unsigned char* hex2bin(const char* hexstr, size_t* size)
{
    size_t hexstrLen = strlen(hexstr);
    size_t bytesLen = hexstrLen / 2;

    unsigned char* bytes = (unsigned char*) malloc(bytesLen);

    int count = 0;
    const char* pos = hexstr;

    for(count = 0; count < bytesLen; count++) {
        sscanf(pos, "%2hhx", &bytes[count]);
        pos += 2;
    }

    if( size != NULL )
        *size = bytesLen;

    return bytes;
}

char *bin2hex(const unsigned char *bin, size_t len)
{
	char   *out;
	size_t  i;

	if (bin == NULL || len == 0)
		return NULL;

	out = malloc(len*2+1);
	for (i=0; i<len; i++) {
		out[i*2]   = "0123456789ABCDEF"[bin[i] >> 4];
		out[i*2+1] = "0123456789ABCDEF"[bin[i] & 0x0F];
	}
	out[len*2] = '\0';

	return out;
}
