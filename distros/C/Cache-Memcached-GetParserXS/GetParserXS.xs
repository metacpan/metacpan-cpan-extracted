#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define DEST     0  /* destination hashref we're writing into */
#define NSLEN    1  /* length of namespace to ignore on keys */
#define ON_ITEM  2
#define BUF      3  /* read buffer */
#define STATE    4  /* 0 = waiting for a line, N = reading N bytes */
#define OFFSET   5  /* offsets to read into buffers */
#define FLAGS    6
#define KEY      7  /* current key we're parsing (without the namespace prefix) */
#define FINISHED 8  /* hashref of keys and flags to be finalized at any time */

#define DEBUG    0

#include "const-c.inc"

int get_nslen (AV* self) {
  SV** svp = av_fetch(self, NSLEN, 0);
  if (svp)
    return SvIV((SV*) *svp);
  return 0;
}

inline void set_key (AV* self, const char *key, int len) {
  av_store(self, KEY, newSVpv(key, len));
}

inline SV *get_key_sv (AV* self) {
  SV** svp = av_fetch(self, KEY, 0);
  if (svp)
    return (SV*) *svp;
  return 0;
}

inline SV *get_on_item (AV* self) {
  SV** svp = av_fetch(self, ON_ITEM, 0);
  if (svp)
    return (SV*) *svp;
  return 0;
}

inline SV *get_offset_sv (AV* self) {
  SV** svp = av_fetch(self, OFFSET, 0);
  if (svp)
    return (SV*) *svp;

  *svp = newSViv(0);
  av_store(self, OFFSET, *svp);
  return (SV*) *svp;
}

inline void clear_on_item (AV* self) {
  SV** svp = av_store(self, ON_ITEM, newSV(0) );
}

inline void set_flags (AV* self, int flags) {
  av_store(self, FLAGS, newSViv(flags));
}

inline void set_offset (AV* self, int offset) {
  av_store(self, OFFSET, newSViv(offset));
}

inline void set_state (AV* self, int state) {
  av_store(self, STATE, newSViv(state));
}

inline HV* get_dest (AV* self) {
  SV** svp = av_fetch(self, DEST, 0);
  if (svp)
    return (HV*) SvRV(*svp);
  return 0;
}

inline HV* get_finished (AV* self) {
  SV** svp = av_fetch(self, FINISHED, 0);
  if (svp)
    return (HV*) SvRV(*svp);
  return 0;
}

inline IV get_state (AV* self) {
  SV** svp = av_fetch(self, STATE, 0);
  if (svp)
    return SvIV((SV*) *svp);
  return 0;
}

inline SV* get_buffer (AV* self) {
  SV** svp = av_fetch(self, BUF, 0);
  if (svp)
    return *svp;
  return 0;
}

/* returns an answer, but also unsets ON_ITEM */
int final_answer (AV* self, int ans) {
//  av_store(self, ON_ITEM, newSV(0));
  return ans;
}

int parse_buffer (SV* selfref) {
  AV* self = (AV*) SvRV(selfref);
  HV* ret = get_dest(self);
  SV* bufsv = get_buffer(self);
  STRLEN len;
  char* buf;
  unsigned int itemlen;
  unsigned int flags;
  int scanned;
  int nslen = get_nslen(self);
  SV* on_item = get_on_item(self);
  register signed char c;
  char *key;
  register char *p;
  int key_len, barelen;
  int state, copy, new_p;
  char *barekey;

  HV* finished = get_finished(self);

  if (DEBUG)
    printf("get_buffer (nslen = %d)...\n", nslen);

  while (1) {
    int rv;
    buf = SvPV(bufsv, len);
    p = buf;

    if (DEBUG) {
      char first_line[1000];
      int i;
      char *end;
      for (i = 0, end = buf; *end && *end != '\n' && i++ < 900; end++)
              ;
      end += 10;
      strncpy (first_line, buf, end - buf + 1);
      first_line[end - buf + 1] = '\0';
      printf("GOT buf (len=%d)\nFirst line: %s\n", len, first_line);
    }

    if ((c = *p++) == 'V') {
      if (*p++ != 'A' || *p++ != 'L' || *p++ != 'U' || *p++ != 'E' || *p++ != ' ') {
        if (DEBUG)
          puts ("ERROR: Illegal command beginning with V");
        goto recover_from_partial_line;
      }

      // Parsing VALUE %s<key> %u<flags> %u<bytes>

      for (key = p; *p++ > ' ';)
        ;
      key_len = p - key - 1;
      if (*(p - 1) != ' ') {
        if (DEBUG)
          printf ("ERROR: key not space-terminated: key %s, char %c\n", key, *(p - 1));
        goto recover_from_partial_line;
      }
      // Note that key just points into the buffer and is not null-terminated
      // yet.  Leave it that way in case we're dealing with a partial line.

      // Get flags and itemlen as integers.  Note invalid characters 
      // are not caught and will result in strange numbers.

      for (flags = 0; (c = *p++ - '0') >= 0; flags = flags * 10 + c)
        ;
      if (c != (signed char)' ' - '0') {
        if (DEBUG)
          puts ("ERROR: Flags not space terminated");
        goto recover_from_partial_line;
      }


      for (itemlen = 0; (c = *p++ - '0') >= 0; itemlen = itemlen * 10 + c)
        ;
      if (c != (signed char)'\r' - '0' || *p++ != '\n') {
        if (DEBUG)
          puts ("ERROR: byte count not CRLF-terminated");
        goto recover_from_partial_line;
      }


      // p is left at the start of the value data.

      new_p = p - buf;
      state = itemlen + 2;      /* 2 to include reading final \r\n, a different \r\n */
      copy  = len - new_p > state ? state : len - new_p;
      barekey = key + nslen;
      barelen = key_len - nslen;

      if (DEBUG) {
        char temp_key[256];
        strncpy (temp_key, key, key_len);
        temp_key[key_len] = '\0';
        printf("key=[%s], state=%d, copy=%d\n", key, state, copy);
      }

      if (copy) {
        *(key + key_len) = '\0';        // Null-terminate the key in-buffer
        hv_store(ret, barekey, barelen, newSVpv(buf + new_p, copy), 0);
        buf[new_p + copy - 1] = '\0';

        if (DEBUG)
          printf("doing store:  len=%d key=[%s] of data [%c]\n",
                 strlen(barekey), barekey, *(buf + new_p));
      }

      /* delete the stuff we used */
      sv_chop(bufsv, buf + new_p + copy);

      if (copy == state) {
        hv_store(finished, barekey, barelen, newSViv(flags), 0);

        set_offset(self, 0);
        set_state(self, 0);
        continue;
      } else {
        /* don't have it all... but buffer is now empty */
        hv_store(finished, barekey, barelen, newSViv(flags), 0);
        set_offset(self, copy);
        set_flags(self, flags);
        set_key(self, barekey, barelen);
        set_state(self, state);

        if (DEBUG)
          printf("don't have it all.... have '%d' of '%d'\n",
                 copy, state);
        return 0; /* return saying '0', not done */
      }
    }

    else if (c == 'E') {

      // Parsing END

      if (*p++ == 'N' && *p++ == 'D' && *p++ == '\r' && *p == '\n')
        return final_answer(self, 1);
    }
    // Just fall through if after 'E' was not "ND\r\n"

    else
      ;         // Unknown command: not 'E' or 'V' at [0]


    /* # if we're here probably means we only have a partial VALUE
       # or END line in the buffer. Could happen with multi-get,
       # though probably very rarely. Exit the loop and let it read
       # more.

       # but first, make sure subsequent reads don't destroy our
       # partial VALUE/END line.
    */

  recover_from_partial_line:
    set_offset(self, len);
    return 0;
  }
}

MODULE = Cache::Memcached::GetParserXS      PACKAGE = Cache::Memcached::GetParserXS

INCLUDE: const-xs.inc

int
parse_buffer ( self )
    SV *self


