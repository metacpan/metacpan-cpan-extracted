#ifndef mhfs_cl_h
#define mhfs_cl_h

typedef enum {
    MHFS_CL_SUCCESS = 0,
    MHFS_CL_ERROR = 1,
    MHFS_CL_NEED_MORE_DATA = 2,
} mhfs_cl_error;

#endif /* mhfs_cl_h */

#if defined(MHFSCL_IMPLEMENTATION)
#ifndef mhfs_cl_c
#define mhfs_cl_c

#endif  /* mhfs_cl_c */
#endif  /* MHFSCL_IMPLEMENTATION */