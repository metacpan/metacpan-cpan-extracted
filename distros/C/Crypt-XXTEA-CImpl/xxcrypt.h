#ifndef XXCRYPT_H
#define XXCRYPT_H

unsigned c_long2str(unsigned* v, unsigned lv, unsigned w, char** buf);
unsigned c_str2long(char* s, unsigned ls, unsigned w, unsigned** res);
unsigned c_xxtea_encrypt(char* str, unsigned lstr, char* key, unsigned lkey, char** res);
unsigned c_xxtea_decrypt(char* str, unsigned lstr, char* key, unsigned lkey, char** res);

#endif
