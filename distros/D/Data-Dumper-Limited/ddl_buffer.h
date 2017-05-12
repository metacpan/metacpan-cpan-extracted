#ifndef DDL_BUFFER_H_
#define DDL_BUFFER_H_

#include "ddl_enc.h"

#define BUFFER_GROWTH_FACTOR 1.5

/* buffer operations */
#define BUF_POS_OFS(enc) ((enc)->pos - (enc)->buf_start)
#define BUF_SPACE(enc) ((enc)->buf_end - (enc)->pos)
#define BUF_SIZE(enc) ((enc)->buf_end - (enc)->buf_start)
#define BUF_NEED_GROW(enc, minlen) ((size_t)BUF_SPACE(enc) <= minlen)
#define BUF_NEED_GROW_TOTAL(enc, minlen) ((size_t)BUF_SIZE(enc) <= minlen)

inline void
ddl_buf_grow_nocheck(pTHX_ ddl_encoder_t *enc, size_t minlen)
{
  const size_t cur_size = BUF_SIZE(enc);
  const size_t new_size = 100 + MAX(minlen, (size_t)(cur_size * BUFFER_GROWTH_FACTOR));
  const size_t old_offset = BUF_POS_OFS(enc);
  Renew(enc->buf_start, new_size, char);
  enc->pos = enc->buf_start + old_offset;
  enc->buf_end = (char *)(enc->buf_start + new_size);
}

#define BUF_SIZE_ASSERT(enc, minlen) \
  STMT_START { \
    if (BUF_NEED_GROW(enc, minlen)) \
      ddl_buf_grow_nocheck(aTHX_ (enc), (BUF_SIZE(enc) + minlen)); \
  } STMT_END

#define BUF_SIZE_ASSERT_TOTAL(enc, minlen) \
  STMT_START { \
    if (BUF_NEED_GROW_TOTAL(enc, minlen)) \
      ddl_buf_grow_nocheck(aTHX_ (enc), (minlen)); \
  } STMT_END

inline void
ddl_buf_cat_str_int(pTHX_ ddl_encoder_t *enc, const char *str, size_t len)
{
  BUF_SIZE_ASSERT(enc, len);
  Copy(str, enc->pos, len, char);
  enc->pos += len;
}
#define ddl_buf_cat_str(enc, str, len) ddl_buf_cat_str_int(aTHX_ enc, str, len)
#define ddl_buf_cat_str_s(enc, str) ddl_buf_cat_str(enc, ("" str), strlen("" str))

inline void
ddl_buf_cat_str_nocheck_int(pTHX_ ddl_encoder_t *enc, const char *str, size_t len)
{
  Copy(str, enc->pos, len, char);
  enc->pos += len;
}
#define ddl_buf_cat_str_nocheck(enc, str, len) ddl_buf_cat_str_nocheck_int(aTHX_ enc, str, len)
#define ddl_buf_cat_str_s_nocheck(enc, str) ddl_buf_cat_str_nocheck(enc, ("" str), strlen("" str))

inline void
ddl_buf_cat_char_int(pTHX_ ddl_encoder_t *enc, const char c)
{
  BUF_SIZE_ASSERT(enc, 1);
  *enc->pos++ = c;
}
#define ddl_buf_cat_char(enc, c) ddl_buf_cat_char_int(aTHX_ enc, c)

inline void
ddl_buf_cat_char_nocheck_int(pTHX_ ddl_encoder_t *enc, const char c)
{
  *enc->pos++ = c;
}
#define ddl_buf_cat_char_nocheck(enc, c) ddl_buf_cat_char_nocheck_int(aTHX_ enc, c)


#endif
