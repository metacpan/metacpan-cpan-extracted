#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_CLA ERR_TRANS PORT_COM1 PORT_COM2 PORT_COM3 PORT_COM4 PORT_LPT1
     PORT_LPT2 */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case '1':
    if (memEQ(name, "PORT_COM1", 9)) {
    /*                       ^      */
#ifdef PORT_COM1
      *iv_return = PORT_COM1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PORT_LPT1", 9)) {
    /*                       ^      */
#ifdef PORT_LPT1
      *iv_return = PORT_LPT1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "PORT_COM2", 9)) {
    /*                       ^      */
#ifdef PORT_COM2
      *iv_return = PORT_COM2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PORT_LPT2", 9)) {
    /*                       ^      */
#ifdef PORT_LPT2
      *iv_return = PORT_LPT2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "PORT_COM3", 9)) {
    /*                       ^      */
#ifdef PORT_COM3
      *iv_return = PORT_COM3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "PORT_COM4", 9)) {
    /*                       ^      */
#ifdef PORT_COM4
      *iv_return = PORT_COM4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "CTBCS_CLA", 9)) {
    /*                       ^      */
#ifdef CTBCS_CLA
      *iv_return = CTBCS_CLA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "ERR_TRANS", 9)) {
    /*                       ^      */
#ifdef ERR_TRANS
      *iv_return = ERR_TRANS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_SW1_OK CTBCS_SW2_OK PORT_Printer */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case '1':
    if (memEQ(name, "CTBCS_SW1_OK", 12)) {
    /*                       ^          */
#ifdef CTBCS_SW1_OK
      *iv_return = CTBCS_SW1_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "CTBCS_SW2_OK", 12)) {
    /*                       ^          */
#ifdef CTBCS_SW2_OK
      *iv_return = CTBCS_SW2_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "PORT_Printer", 12)) {
    /*                       ^          */
#ifdef PORT_Printer
      *iv_return = PORT_Printer;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_INS_EJECT CTBCS_INS_RESET CTBCS_P1_KEYPAD */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'A':
    if (memEQ(name, "CTBCS_P1_KEYPAD", 15)) {
    /*                            ^        */
#ifdef CTBCS_P1_KEYPAD
      *iv_return = CTBCS_P1_KEYPAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CTBCS_INS_EJECT", 15)) {
    /*                            ^        */
#ifdef CTBCS_INS_EJECT
      *iv_return = CTBCS_INS_EJECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CTBCS_INS_RESET", 15)) {
    /*                            ^        */
#ifdef CTBCS_INS_RESET
      *iv_return = CTBCS_INS_RESET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_P1_CT_KERNEL CTBCS_SW1_EJECT_OK CTBCS_SW2_EJECT_OK */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case '1':
    if (memEQ(name, "CTBCS_SW1_EJECT_OK", 18)) {
    /*                       ^                */
#ifdef CTBCS_SW1_EJECT_OK
      *iv_return = CTBCS_SW1_EJECT_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "CTBCS_SW2_EJECT_OK", 18)) {
    /*                       ^                */
#ifdef CTBCS_SW2_EJECT_OK
      *iv_return = CTBCS_SW2_EJECT_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "CTBCS_P1_CT_KERNEL", 18)) {
    /*                       ^                */
#ifdef CTBCS_P1_CT_KERNEL
      *iv_return = CTBCS_P1_CT_KERNEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_P1_INTERFACE1 CTBCS_P1_INTERFACE2 CTBCS_P1_INTERFACE3
     CTBCS_P1_INTERFACE4 CTBCS_P1_INTERFACE5 CTBCS_P1_INTERFACE6
     CTBCS_P1_INTERFACE7 CTBCS_P1_INTERFACE8 CTBCS_P1_INTERFACE9
     CTBCS_P2_STATUS_ICC CTBCS_SW1_ICC_ERROR CTBCS_SW1_WRONG_CLA
     CTBCS_SW1_WRONG_INS CTBCS_SW2_ICC_ERROR CTBCS_SW2_WRONG_CLA
     CTBCS_SW2_WRONG_INS */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case '1':
    if (memEQ(name, "CTBCS_P1_INTERFACE1", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P1_INTERFACE1
      *iv_return = CTBCS_P1_INTERFACE1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "CTBCS_P1_INTERFACE2", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P1_INTERFACE2
      *iv_return = CTBCS_P1_INTERFACE2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "CTBCS_P1_INTERFACE3", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P1_INTERFACE3
      *iv_return = CTBCS_P1_INTERFACE3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "CTBCS_P1_INTERFACE4", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P1_INTERFACE4
      *iv_return = CTBCS_P1_INTERFACE4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "CTBCS_P1_INTERFACE5", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P1_INTERFACE5
      *iv_return = CTBCS_P1_INTERFACE5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "CTBCS_P1_INTERFACE6", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P1_INTERFACE6
      *iv_return = CTBCS_P1_INTERFACE6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "CTBCS_P1_INTERFACE7", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P1_INTERFACE7
      *iv_return = CTBCS_P1_INTERFACE7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "CTBCS_P1_INTERFACE8", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P1_INTERFACE8
      *iv_return = CTBCS_P1_INTERFACE8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '9':
    if (memEQ(name, "CTBCS_P1_INTERFACE9", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P1_INTERFACE9
      *iv_return = CTBCS_P1_INTERFACE9;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "CTBCS_SW1_WRONG_CLA", 19)) {
    /*                                 ^       */
#ifdef CTBCS_SW1_WRONG_CLA
      *iv_return = CTBCS_SW1_WRONG_CLA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_WRONG_CLA", 19)) {
    /*                                 ^       */
#ifdef CTBCS_SW2_WRONG_CLA
      *iv_return = CTBCS_SW2_WRONG_CLA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CTBCS_P2_STATUS_ICC", 19)) {
    /*                                 ^       */
#ifdef CTBCS_P2_STATUS_ICC
      *iv_return = CTBCS_P2_STATUS_ICC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CTBCS_SW1_ICC_ERROR", 19)) {
    /*                                 ^       */
#ifdef CTBCS_SW1_ICC_ERROR
      *iv_return = CTBCS_SW1_ICC_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_ICC_ERROR", 19)) {
    /*                                 ^       */
#ifdef CTBCS_SW2_ICC_ERROR
      *iv_return = CTBCS_SW2_ICC_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CTBCS_SW1_WRONG_INS", 19)) {
    /*                                 ^       */
#ifdef CTBCS_SW1_WRONG_INS
      *iv_return = CTBCS_SW1_WRONG_INS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_WRONG_INS", 19)) {
    /*                                 ^       */
#ifdef CTBCS_SW2_WRONG_INS
      *iv_return = CTBCS_SW2_WRONG_INS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_P1_INTERFACE10 CTBCS_P1_INTERFACE11 CTBCS_P1_INTERFACE12
     CTBCS_P1_INTERFACE13 CTBCS_P1_INTERFACE14 */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case '0':
    if (memEQ(name, "CTBCS_P1_INTERFACE10", 20)) {
    /*                                  ^       */
#ifdef CTBCS_P1_INTERFACE10
      *iv_return = CTBCS_P1_INTERFACE10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "CTBCS_P1_INTERFACE11", 20)) {
    /*                                  ^       */
#ifdef CTBCS_P1_INTERFACE11
      *iv_return = CTBCS_P1_INTERFACE11;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "CTBCS_P1_INTERFACE12", 20)) {
    /*                                  ^       */
#ifdef CTBCS_P1_INTERFACE12
      *iv_return = CTBCS_P1_INTERFACE12;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "CTBCS_P1_INTERFACE13", 20)) {
    /*                                  ^       */
#ifdef CTBCS_P1_INTERFACE13
      *iv_return = CTBCS_P1_INTERFACE13;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "CTBCS_P1_INTERFACE14", 20)) {
    /*                                  ^       */
#ifdef CTBCS_P1_INTERFACE14
      *iv_return = CTBCS_P1_INTERFACE14;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_SW1_RESET_CT_OK CTBCS_SW1_RESET_ERROR CTBCS_SW1_WRONG_PARAM
     CTBCS_SW2_RESET_CT_OK CTBCS_SW2_RESET_ERROR CTBCS_SW2_WRONG_PARAM */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'K':
    if (memEQ(name, "CTBCS_SW1_RESET_CT_OK", 21)) {
    /*                                   ^       */
#ifdef CTBCS_SW1_RESET_CT_OK
      *iv_return = CTBCS_SW1_RESET_CT_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_RESET_CT_OK", 21)) {
    /*                                   ^       */
#ifdef CTBCS_SW2_RESET_CT_OK
      *iv_return = CTBCS_SW2_RESET_CT_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CTBCS_SW1_WRONG_PARAM", 21)) {
    /*                                   ^       */
#ifdef CTBCS_SW1_WRONG_PARAM
      *iv_return = CTBCS_SW1_WRONG_PARAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_WRONG_PARAM", 21)) {
    /*                                   ^       */
#ifdef CTBCS_SW2_WRONG_PARAM
      *iv_return = CTBCS_SW2_WRONG_PARAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CTBCS_SW1_RESET_ERROR", 21)) {
    /*                                   ^       */
#ifdef CTBCS_SW1_RESET_ERROR
      *iv_return = CTBCS_SW1_RESET_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_RESET_ERROR", 21)) {
    /*                                   ^       */
#ifdef CTBCS_SW2_RESET_ERROR
      *iv_return = CTBCS_SW2_RESET_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_DATA_STATUS_CARD CTBCS_MIN_COMMAND_SIZE CTBCS_P2_RESET_GET_ATR
     CTBCS_P2_RESET_NO_RESP CTBCS_SW1_WRONG_LENGTH CTBCS_SW2_WRONG_LENGTH */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
  case 'D':
    if (memEQ(name, "CTBCS_DATA_STATUS_CARD", 22)) {
    /*                                    ^       */
#ifdef CTBCS_DATA_STATUS_CARD
      *iv_return = CTBCS_DATA_STATUS_CARD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CTBCS_MIN_COMMAND_SIZE", 22)) {
    /*                                    ^       */
#ifdef CTBCS_MIN_COMMAND_SIZE
      *iv_return = CTBCS_MIN_COMMAND_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CTBCS_SW1_WRONG_LENGTH", 22)) {
    /*                                    ^       */
#ifdef CTBCS_SW1_WRONG_LENGTH
      *iv_return = CTBCS_SW1_WRONG_LENGTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_WRONG_LENGTH", 22)) {
    /*                                    ^       */
#ifdef CTBCS_SW2_WRONG_LENGTH
      *iv_return = CTBCS_SW2_WRONG_LENGTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "CTBCS_P2_RESET_NO_RESP", 22)) {
    /*                                    ^       */
#ifdef CTBCS_P2_RESET_NO_RESP
      *iv_return = CTBCS_P2_RESET_NO_RESP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CTBCS_P2_RESET_GET_ATR", 22)) {
    /*                                    ^       */
#ifdef CTBCS_P2_RESET_GET_ATR
      *iv_return = CTBCS_P2_RESET_GET_ATR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_MIN_RESPONSE_SIZE CTBCS_P2_RESET_GET_HIST CTBCS_SW1_EJECT_REMOVED
     CTBCS_SW1_REQUEST_ERROR CTBCS_SW1_RESET_SYNC_OK CTBCS_SW2_EJECT_REMOVED
     CTBCS_SW2_REQUEST_ERROR CTBCS_SW2_RESET_SYNC_OK */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'C':
    if (memEQ(name, "CTBCS_SW1_RESET_SYNC_OK", 23)) {
    /*                                  ^          */
#ifdef CTBCS_SW1_RESET_SYNC_OK
      *iv_return = CTBCS_SW1_RESET_SYNC_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_RESET_SYNC_OK", 23)) {
    /*                                  ^          */
#ifdef CTBCS_SW2_RESET_SYNC_OK
      *iv_return = CTBCS_SW2_RESET_SYNC_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CTBCS_P2_RESET_GET_HIST", 23)) {
    /*                                  ^          */
#ifdef CTBCS_P2_RESET_GET_HIST
      *iv_return = CTBCS_P2_RESET_GET_HIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CTBCS_SW1_EJECT_REMOVED", 23)) {
    /*                                  ^          */
#ifdef CTBCS_SW1_EJECT_REMOVED
      *iv_return = CTBCS_SW1_EJECT_REMOVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_EJECT_REMOVED", 23)) {
    /*                                  ^          */
#ifdef CTBCS_SW2_EJECT_REMOVED
      *iv_return = CTBCS_SW2_EJECT_REMOVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CTBCS_SW1_REQUEST_ERROR", 23)) {
    /*                                  ^          */
#ifdef CTBCS_SW1_REQUEST_ERROR
      *iv_return = CTBCS_SW1_REQUEST_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_REQUEST_ERROR", 23)) {
    /*                                  ^          */
#ifdef CTBCS_SW2_REQUEST_ERROR
      *iv_return = CTBCS_SW2_REQUEST_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CTBCS_MIN_RESPONSE_SIZE", 23)) {
    /*                                  ^          */
#ifdef CTBCS_MIN_RESPONSE_SIZE
      *iv_return = CTBCS_MIN_RESPONSE_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_DATA_STATUS_NOCARD CTBCS_P2_REQUEST_GET_ATR CTBCS_P2_REQUEST_NO_RESP
     CTBCS_SW1_RESET_ASYNC_OK CTBCS_SW2_RESET_ASYNC_OK */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'O':
    if (memEQ(name, "CTBCS_SW1_RESET_ASYNC_OK", 24)) {
    /*                                     ^        */
#ifdef CTBCS_SW1_RESET_ASYNC_OK
      *iv_return = CTBCS_SW1_RESET_ASYNC_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_RESET_ASYNC_OK", 24)) {
    /*                                     ^        */
#ifdef CTBCS_SW2_RESET_ASYNC_OK
      *iv_return = CTBCS_SW2_RESET_ASYNC_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CTBCS_DATA_STATUS_NOCARD", 24)) {
    /*                                     ^        */
#ifdef CTBCS_DATA_STATUS_NOCARD
      *iv_return = CTBCS_DATA_STATUS_NOCARD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CTBCS_P2_REQUEST_NO_RESP", 24)) {
    /*                                     ^        */
#ifdef CTBCS_P2_REQUEST_NO_RESP
      *iv_return = CTBCS_P2_REQUEST_NO_RESP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CTBCS_P2_REQUEST_GET_ATR", 24)) {
    /*                                     ^        */
#ifdef CTBCS_P2_REQUEST_GET_ATR
      *iv_return = CTBCS_P2_REQUEST_GET_ATR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_P2_REQUEST_GET_HIST CTBCS_SW1_REQUEST_NO_CARD
     CTBCS_SW1_REQUEST_SYNC_OK CTBCS_SW2_REQUEST_NO_CARD
     CTBCS_SW2_REQUEST_SYNC_OK */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'O':
    if (memEQ(name, "CTBCS_SW1_REQUEST_SYNC_OK", 25)) {
    /*                                      ^        */
#ifdef CTBCS_SW1_REQUEST_SYNC_OK
      *iv_return = CTBCS_SW1_REQUEST_SYNC_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_REQUEST_SYNC_OK", 25)) {
    /*                                      ^        */
#ifdef CTBCS_SW2_REQUEST_SYNC_OK
      *iv_return = CTBCS_SW2_REQUEST_SYNC_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CTBCS_SW1_REQUEST_NO_CARD", 25)) {
    /*                                      ^        */
#ifdef CTBCS_SW1_REQUEST_NO_CARD
      *iv_return = CTBCS_SW1_REQUEST_NO_CARD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_REQUEST_NO_CARD", 25)) {
    /*                                      ^        */
#ifdef CTBCS_SW2_REQUEST_NO_CARD
      *iv_return = CTBCS_SW2_REQUEST_NO_CARD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CTBCS_P2_REQUEST_GET_HIST", 25)) {
    /*                                      ^        */
#ifdef CTBCS_P2_REQUEST_GET_HIST
      *iv_return = CTBCS_P2_REQUEST_GET_HIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_29 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_SW1_COMMAND_NOT_ALLOWED CTBCS_SW1_REQUEST_TIMER_ERROR
     CTBCS_SW2_COMMAND_NOT_ALLOWED CTBCS_SW2_REQUEST_TIMER_ERROR */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case '1':
    if (memEQ(name, "CTBCS_SW1_COMMAND_NOT_ALLOWED", 29)) {
    /*                       ^                           */
#ifdef CTBCS_SW1_COMMAND_NOT_ALLOWED
      *iv_return = CTBCS_SW1_COMMAND_NOT_ALLOWED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW1_REQUEST_TIMER_ERROR", 29)) {
    /*                       ^                           */
#ifdef CTBCS_SW1_REQUEST_TIMER_ERROR
      *iv_return = CTBCS_SW1_REQUEST_TIMER_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "CTBCS_SW2_COMMAND_NOT_ALLOWED", 29)) {
    /*                       ^                           */
#ifdef CTBCS_SW2_COMMAND_NOT_ALLOWED
      *iv_return = CTBCS_SW2_COMMAND_NOT_ALLOWED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CTBCS_SW2_REQUEST_TIMER_ERROR", 29)) {
    /*                       ^                           */
#ifdef CTBCS_SW2_REQUEST_TIMER_ERROR
      *iv_return = CTBCS_SW2_REQUEST_TIMER_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_30 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CTBCS_DATA_STATUS_CARD_CONNECT CTBCS_SW1_REQUEST_CARD_PRESENT
     CTBCS_SW2_REQUEST_CARD_PRESENT */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case '1':
    if (memEQ(name, "CTBCS_SW1_REQUEST_CARD_PRESENT", 30)) {
    /*                       ^                            */
#ifdef CTBCS_SW1_REQUEST_CARD_PRESENT
      *iv_return = CTBCS_SW1_REQUEST_CARD_PRESENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "CTBCS_SW2_REQUEST_CARD_PRESENT", 30)) {
    /*                       ^                            */
#ifdef CTBCS_SW2_REQUEST_CARD_PRESENT
      *iv_return = CTBCS_SW2_REQUEST_CARD_PRESENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CTBCS_DATA_STATUS_CARD_CONNECT", 30)) {
    /*                       ^                            */
#ifdef CTBCS_DATA_STATUS_CARD_CONNECT
      *iv_return = CTBCS_DATA_STATUS_CARD_CONNECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/client/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(CT CTBCS_CLA CTBCS_DATA_STATUS_CARD
	       CTBCS_DATA_STATUS_CARD_CONNECT CTBCS_DATA_STATUS_NOCARD
	       CTBCS_INS_EJECT CTBCS_INS_REQUEST CTBCS_INS_RESET
	       CTBCS_INS_STATUS CTBCS_MIN_COMMAND_SIZE CTBCS_MIN_RESPONSE_SIZE
	       CTBCS_P1_CT_KERNEL CTBCS_P1_DISPLAY CTBCS_P1_INTERFACE1
	       CTBCS_P1_INTERFACE10 CTBCS_P1_INTERFACE11 CTBCS_P1_INTERFACE12
	       CTBCS_P1_INTERFACE13 CTBCS_P1_INTERFACE14 CTBCS_P1_INTERFACE2
	       CTBCS_P1_INTERFACE3 CTBCS_P1_INTERFACE4 CTBCS_P1_INTERFACE5
	       CTBCS_P1_INTERFACE6 CTBCS_P1_INTERFACE7 CTBCS_P1_INTERFACE8
	       CTBCS_P1_INTERFACE9 CTBCS_P1_KEYPAD CTBCS_P2_REQUEST_GET_ATR
	       CTBCS_P2_REQUEST_GET_HIST CTBCS_P2_REQUEST_NO_RESP
	       CTBCS_P2_RESET_GET_ATR CTBCS_P2_RESET_GET_HIST
	       CTBCS_P2_RESET_NO_RESP CTBCS_P2_STATUS_ICC
	       CTBCS_P2_STATUS_MANUFACTURER CTBCS_SW1_COMMAND_NOT_ALLOWED
	       CTBCS_SW1_EJECT_NOT_REMOVED CTBCS_SW1_EJECT_OK
	       CTBCS_SW1_EJECT_REMOVED CTBCS_SW1_ICC_ERROR CTBCS_SW1_OK
	       CTBCS_SW1_REQUEST_ASYNC_OK CTBCS_SW1_REQUEST_CARD_PRESENT
	       CTBCS_SW1_REQUEST_ERROR CTBCS_SW1_REQUEST_NO_CARD
	       CTBCS_SW1_REQUEST_SYNC_OK CTBCS_SW1_REQUEST_TIMER_ERROR
	       CTBCS_SW1_RESET_ASYNC_OK CTBCS_SW1_RESET_CT_OK
	       CTBCS_SW1_RESET_ERROR CTBCS_SW1_RESET_SYNC_OK
	       CTBCS_SW1_WRONG_CLA CTBCS_SW1_WRONG_INS CTBCS_SW1_WRONG_LENGTH
	       CTBCS_SW1_WRONG_PARAM CTBCS_SW2_COMMAND_NOT_ALLOWED
	       CTBCS_SW2_EJECT_NOT_REMOVED CTBCS_SW2_EJECT_OK
	       CTBCS_SW2_EJECT_REMOVED CTBCS_SW2_ICC_ERROR CTBCS_SW2_OK
	       CTBCS_SW2_REQUEST_ASYNC_OK CTBCS_SW2_REQUEST_CARD_PRESENT
	       CTBCS_SW2_REQUEST_ERROR CTBCS_SW2_REQUEST_NO_CARD
	       CTBCS_SW2_REQUEST_SYNC_OK CTBCS_SW2_REQUEST_TIMER_ERROR
	       CTBCS_SW2_RESET_ASYNC_OK CTBCS_SW2_RESET_CT_OK
	       CTBCS_SW2_RESET_ERROR CTBCS_SW2_RESET_SYNC_OK
	       CTBCS_SW2_WRONG_CLA CTBCS_SW2_WRONG_INS CTBCS_SW2_WRONG_LENGTH
	       CTBCS_SW2_WRONG_PARAM ERR_CT ERR_HTSI ERR_INVALID ERR_MEMORY
	       ERR_TRANS HOST MAX_APDULEN OK PORT_COM1 PORT_COM2 PORT_COM3
	       PORT_COM4 PORT_LPT1 PORT_LPT2 PORT_Modem PORT_Printer));

print constant_types(); # macro defs
foreach (C_constant ("Chipcard::CTAPI", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Chipcard::CTAPI", $types);
__END__
   */

  switch (len) {
  case 2:
    /* Names all of length 2.  */
    /* CT OK */
    /* Offset 1 gives the best switch position.  */
    switch (name[1]) {
    case 'K':
      if (name[0] == 'O') {
#ifdef OK
        *iv_return = OK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (name[0] == 'C') {
#ifdef CT
        *iv_return = CT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 4:
    if (memEQ(name, "HOST", 4)) {
#ifdef HOST
      *iv_return = HOST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 6:
    if (memEQ(name, "ERR_CT", 6)) {
#ifdef ERR_CT
      *iv_return = ERR_CT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    if (memEQ(name, "ERR_HTSI", 8)) {
#ifdef ERR_HTSI
      *iv_return = ERR_HTSI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    /* Names all of length 10.  */
    /* ERR_MEMORY PORT_Modem */
    /* Offset 1 gives the best switch position.  */
    switch (name[1]) {
    case 'O':
      if (memEQ(name, "PORT_Modem", 10)) {
      /*                ^               */
#ifdef PORT_Modem
        *iv_return = PORT_Modem;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "ERR_MEMORY", 10)) {
      /*                ^               */
#ifdef ERR_MEMORY
        *iv_return = ERR_MEMORY;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* ERR_INVALID MAX_APDULEN */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'N':
      if (memEQ(name, "ERR_INVALID", 11)) {
      /*                    ^            */
#ifdef ERR_INVALID
        *iv_return = ERR_INVALID;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "MAX_APDULEN", 11)) {
      /*                    ^            */
#ifdef MAX_APDULEN
        *iv_return = MAX_APDULEN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    /* Names all of length 16.  */
    /* CTBCS_INS_STATUS CTBCS_P1_DISPLAY */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'S':
      if (memEQ(name, "CTBCS_P1_DISPLAY", 16)) {
      /*                          ^           */
#ifdef CTBCS_P1_DISPLAY
        *iv_return = CTBCS_P1_DISPLAY;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "CTBCS_INS_STATUS", 16)) {
      /*                          ^           */
#ifdef CTBCS_INS_STATUS
        *iv_return = CTBCS_INS_STATUS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 17:
    if (memEQ(name, "CTBCS_INS_REQUEST", 17)) {
#ifdef CTBCS_INS_REQUEST
      *iv_return = CTBCS_INS_REQUEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    /* Names all of length 26.  */
    /* CTBCS_SW1_REQUEST_ASYNC_OK CTBCS_SW2_REQUEST_ASYNC_OK */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case '1':
      if (memEQ(name, "CTBCS_SW1_REQUEST_ASYNC_OK", 26)) {
      /*                       ^                        */
#ifdef CTBCS_SW1_REQUEST_ASYNC_OK
        *iv_return = CTBCS_SW1_REQUEST_ASYNC_OK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case '2':
      if (memEQ(name, "CTBCS_SW2_REQUEST_ASYNC_OK", 26)) {
      /*                       ^                        */
#ifdef CTBCS_SW2_REQUEST_ASYNC_OK
        *iv_return = CTBCS_SW2_REQUEST_ASYNC_OK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 27:
    /* Names all of length 27.  */
    /* CTBCS_SW1_EJECT_NOT_REMOVED CTBCS_SW2_EJECT_NOT_REMOVED */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case '1':
      if (memEQ(name, "CTBCS_SW1_EJECT_NOT_REMOVED", 27)) {
      /*                       ^                         */
#ifdef CTBCS_SW1_EJECT_NOT_REMOVED
        *iv_return = CTBCS_SW1_EJECT_NOT_REMOVED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case '2':
      if (memEQ(name, "CTBCS_SW2_EJECT_NOT_REMOVED", 27)) {
      /*                       ^                         */
#ifdef CTBCS_SW2_EJECT_NOT_REMOVED
        *iv_return = CTBCS_SW2_EJECT_NOT_REMOVED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 28:
    if (memEQ(name, "CTBCS_P2_STATUS_MANUFACTURER", 28)) {
#ifdef CTBCS_P2_STATUS_MANUFACTURER
      *iv_return = CTBCS_P2_STATUS_MANUFACTURER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 29:
    return constant_29 (aTHX_ name, iv_return);
    break;
  case 30:
    return constant_30 (aTHX_ name, iv_return);
    break;
  }
  return PERL_constant_NOTFOUND;
}

