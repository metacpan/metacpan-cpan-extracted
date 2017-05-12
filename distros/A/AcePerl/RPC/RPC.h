#ifndef ACEPERL_H
#define ACEPERL_H

#define STATUS_WAITING 0
#define STATUS_PENDING 1
#define STATUS_ERROR  -1
#define ACE_PARSE      3

typedef struct AceDB {
  ace_handle*    database;
  unsigned char* answer;
  int            length;
  int            encoring;
  int            status;
  int            errcode;
} AceDB;

#endif
