#include "xx.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

xx_reader_t R;

#define DEBUG(M, ...) fprintf(stderr, "%-24.24s %5d:    ", __FILE__, __LINE__); fprintf(stderr, M, __VA_ARGS__);
//#define DEBUG

#define XNZ(X) if(rc=(X)) { fprintf(stderr, "test: Code %d at line %d\n", rc, __LINE__); exit(-1); }
#define ASSERT(X) if(!(X)) { fprintf(stderr, "test: assert failed at line %d: '%s'\n", __LINE__, #X); exit(-1); }

void t1a(char *k, char *v) {
  int kl, vl, vallen, rc;
  char *val;

  kl = strlen(k);
  vl = strlen(v);
  DEBUG("getting '%s'\n", k);
  XNZ( xx_get(&R, k, kl, &val, &vallen) )
  ASSERT(vl == vallen)
  ASSERT(0 == memcmp(v, val, vallen))
}

void t1b(char *k) {
  int kl, vallen;
  char *val;

  kl = strlen(k);
  DEBUG("getting bad val '%s'\n", k);
  ASSERT(XX_ENXKEY == xx_get(&R, k, kl, &val, &vallen) )
}

void t1() {
    int rc;
    XNZ( xx_open(&R, "small.dat") )
    t1a("bob", "blue");
    t1a("oscar", "orange");
    t1a("ralph", "red");

    t1b("ralphx");
    t1b("ralp");
    t1b("abc");
    t1b("abd");
    XNZ( xx_close(&R) )
}

void t2() {
    int rc;
    uint keylen, vallen;
    char *key, *val;

    XNZ( xx_open(&R, "ff.1k") )
    XNZ( xx_iterate_init(&R) )
    while(1) {
        rc = xx_iterate_next(&R, &key, &keylen, &val, &vallen);
        if(rc == XX_DONE) {
            XNZ( xx_close(&R) )
            return;
        }
        XNZ(rc);
        printf("iterate: %u, %u\n", keylen, vallen);
        printf("iterate: '%*.*s' -> '%*.*s'\n", keylen, keylen, key, vallen, vallen, val);
    }
}

void t3() {
    uint n;
    int rc;

    XNZ( xx_open(&R, "ff.1k") )
    XNZ( xx_get_num_keys(&R, &n) )
    printf("nkeys=%u\n", n);
    XNZ( xx_close(&R) )
}

void t4() {
    uint n, keylen, vallen;
    int rc;
    char *val;

    XNZ( xx_open(&R, "ff.1k") )
    XNZ( xx_get(&R, "Ameslan", (uint)7, &val, &vallen) )
    XNZ( xx_close(&R) )
}

//c: t 116
//c: � 195
//c: � 179

void t5() {
    uint n, keylen, vallen;
    int rc;
    char *val;
    char key[] = "Bart\xc3\xb3k9'";

    XNZ( xx_open(&R, "ff.bad") )
    XNZ( xx_get(&R, key, strlen(key), &val, &vallen) )
    XNZ( xx_close(&R) )
}
    


int main(int argc, char **argv) {
    t4();
}
