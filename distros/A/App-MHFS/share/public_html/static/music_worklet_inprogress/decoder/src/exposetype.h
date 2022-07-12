// ExposeType: Expose constants, structs, and unions to js
#pragma once
#include <stddef.h>
#include <assert.h>

typedef enum {
    ET_TT_CONST_IV = 1,
    ET_TT_CONST_CSTRING = 2,
    ET_TT_ST = 3,     // also used for unions
    ET_TT_ST_END = 4, // also used for unions
    ET_TT_UINT64 = 5,
    ET_TT_UINT32 = 6,
    ET_TT_UINT16 = 7,
    ET_TT_UINT8  = 8
} et_type_type;

#define ET_EXPOSE_CONST(XTYPE, X) \
do {\
switch(subItemIndex) {\
case 0: \
return XTYPE; \
break; \
case 1: \
return (uint64_t)#X; \
break; \
case 2: \
return X; \
break; \
} \
} while(0)

#define ET_EXPOSE_CONST_IV(X) \
ET_EXPOSE_CONST(ET_TT_CONST_IV, X)

#define ET_EXPOSE_STRUCT_MEMBER(XTYPE, XSTRUCT, XMEMBER) \
do {\
switch(subItemIndex) {\
case 0: \
return XTYPE; \
break; \
case 1: \
return (uint64_t)#XMEMBER; \
break; \
case 2: \
return offsetof(XSTRUCT, XMEMBER); \
break; \
} \
} while(0)

#define ET_EXPOSE_STRUCT_UINT64(XSTRUCT, XMEMBER) \
ET_EXPOSE_STRUCT_MEMBER(ET_TT_UINT64, XSTRUCT, XMEMBER)

#define ET_EXPOSE_STRUCT_UINT32(XSTRUCT, XMEMBER) \
ET_EXPOSE_STRUCT_MEMBER(ET_TT_UINT32, XSTRUCT, XMEMBER)

#define ET_EXPOSE_STRUCT_UINT16(XSTRUCT, XMEMBER) \
ET_EXPOSE_STRUCT_MEMBER(ET_TT_UINT16, XSTRUCT, XMEMBER)

#define ET_EXPOSE_STRUCT_UINT8(XSTRUCT, XMEMBER) \
ET_EXPOSE_STRUCT_MEMBER(ET_TT_UINT8, XSTRUCT, XMEMBER)

#define ET_EXPOSE_STRUCT_PTR(XSTRUCT, XMEMBER) \
do { \
static_assert(sizeof(void*) == 4, "ptr size bad"); \
ET_EXPOSE_STRUCT_MEMBER(ET_TT_UINT32, XSTRUCT, XMEMBER); \
} while(0)

#define ET_EXPOSE_STRUCT_BEGIN(X) \
do {\
switch(subItemIndex) {\
case 0: \
return ET_TT_ST; \
break; \
case 1: \
return (uint64_t)#X; \
break; \
case 2: \
return sizeof(X); \
break; \
} \
} while(0)

#define ET_EXPOSE_STRUCT_END() \
do {\
switch(subItemIndex) {\
case 0: \
return ET_TT_ST_END; \
break; \
} \
} while(0)
