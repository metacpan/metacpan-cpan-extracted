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
