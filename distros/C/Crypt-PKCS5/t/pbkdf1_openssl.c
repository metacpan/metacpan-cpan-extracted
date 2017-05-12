#include <openssl/evp.h>
#include <openssl/objects.h>

#include <stdio.h>
#include <string.h>

typedef struct {
    int type;
    int block_size;
    int key_len;
    int iv_len;
    void (*enc_init)();
    void (*dec_init)();
    void (*do_cipher)();
} my_cipher_t;

void print_hex(const char *label, unsigned char *buff, size_t l)
{
    printf("%s", label);
    while (l > 0) {
        printf("%02x", *buff);
        buff++;
        l--;
    }
    printf("\n");
}

int main(int argc, char *argv[])
{
    unsigned char salt[8] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
    unsigned char data[] = "Hello World!";
    unsigned char key[16];
    unsigned char iv[16];
    EVP_CIPHER *c;
    int i = 1;
    my_cipher_t type;
    type.key_len = 16;
    type.iv_len = 0;

    OpenSSL_add_all_algorithms();
    memset(key, 0, sizeof(key));
    memset(iv, 0, sizeof(iv));
    EVP_BytesToKey((EVP_CIPHER *)&type, EVP_md5(), salt, data, strlen((char *)data), i, key, iv);

    print_hex("P: ", data, sizeof(data)-1);
    print_hex("S: ", salt, sizeof(salt));
    printf("c: %d\n", i);
    printf("dkLen: %d\n", type.key_len);
    print_hex("DK: ", key, sizeof(key));
//    print_hex("iv: ", iv, sizeof(iv));

    return 0;
}
