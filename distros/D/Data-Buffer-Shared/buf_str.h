/* buf_str.h -- fixed-length string shared buffer
 * For Str, elem_size is dynamic (set at create time).
 * We define BUF_ELEM_SIZE as a special value and handle it in the template. */
#define BUF_PREFIX       buf_str
#define BUF_ELEM_TYPE    char
#define BUF_ELEM_SIZE    0  /* placeholder — actual size from header at runtime */
#define BUF_VARIANT_ID   11
#define BUF_IS_FIXEDSTR
#include "buf_generic.h"
