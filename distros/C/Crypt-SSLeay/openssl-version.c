#include <stdio.h>
#include <openssl/opensslv.h>

int main(void) {
    puts(OPENSSL_VERSION_TEXT);
    printf("%8lx\n", OPENSSL_VERSION_NUMBER);
    return 0;
}
