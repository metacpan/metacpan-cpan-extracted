typedef signed char __int8_t;
typedef unsigned char __uint8_t;
typedef signed short int __int16_t;
typedef unsigned short int __uint16_t;
typedef signed int __int32_t;
typedef unsigned int __uint32_t;

__extension__ typedef signed long long int __int64_t;
__extension__ typedef unsigned long long int __uint64_t;

typedef __quad_t *__qaddr_t;

typedef __u_quad_t __dev_t;		 
typedef __u_int __uid_t;		 
typedef __u_int __gid_t;		 
typedef __u_long __ino_t;		 
typedef __u_int __mode_t;		 
typedef __u_int __nlink_t; 		 
typedef long int __off_t;		 
typedef __quad_t __loff_t;		 
typedef int __pid_t;			 
typedef int __ssize_t;			 
typedef long int __rlim_t;		 
typedef __quad_t __rlim64_t;		 
typedef __u_int __id_t;			 

typedef struct
  {
    int __val[2];
  } __fsid_t;				 

 
typedef int __daddr_t;			 
typedef char *__caddr_t;
typedef long int __time_t;
typedef long int __swblk_t;		 

typedef long int __clock_t;

 
typedef unsigned long int __fd_mask;

 


 




 
typedef struct
  {
     





    __fd_mask __fds_bits[1024  / (8 * sizeof (__fd_mask)) ];


  } __fd_set;


typedef int __key_t;

 
typedef unsigned short int __ipc_pid_t;


 

 
typedef __u_long __blkcnt_t;
typedef __u_quad_t __blkcnt64_t;

 
typedef long int __fsblkcnt_t;
typedef __quad_t __fsblkcnt64_t;

 
typedef __u_long __fsfilcnt_t;
typedef __u_quad_t __fsfilcnt64_t;

 
typedef __u_long __ino64_t;

 
typedef __loff_t __off64_t;

 
typedef int __t_scalar_t;
typedef unsigned int __t_uscalar_t;

 
typedef int __intptr_t;


 





# 30 "/usr/include/sys/types.h" 2 3



typedef __u_char u_char;
typedef __u_short u_short;
typedef __u_int u_int;
typedef __u_long u_long;
typedef __quad_t quad_t;
typedef __u_quad_t u_quad_t;
typedef __fsid_t fsid_t;


typedef __loff_t loff_t;



typedef __ino_t ino_t;










typedef __dev_t dev_t;




typedef __gid_t gid_t;




typedef __mode_t mode_t;




typedef __nlink_t nlink_t;




typedef __uid_t uid_t;





typedef __off_t off_t;











typedef __pid_t pid_t;




typedef __id_t id_t;



typedef __ssize_t ssize_t;




typedef __daddr_t daddr_t;
typedef __caddr_t caddr_t;



typedef __key_t key_t;






# 1 "/usr/include/time.h" 1 3
 

















 














# 51 "/usr/include/time.h" 3



# 62 "/usr/include/time.h" 3








 
typedef __time_t time_t;





# 89 "/usr/include/time.h" 3




# 279 "/usr/include/time.h" 3



# 121 "/usr/include/sys/types.h" 2 3



# 1 "/usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stddef.h" 1 3






 


# 19 "/usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stddef.h" 3



 


 





 


# 61 "/usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stddef.h" 3


 





 


















 





 

 

# 131 "/usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stddef.h" 3


 

 


# 188 "/usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stddef.h" 3





 




 

# 271 "/usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stddef.h" 3


# 283 "/usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stddef.h" 3


 

 

# 317 "/usr/lib/gcc-lib/i386-redhat-linux/egcs-2.91.66/include/stddef.h" 3




 





















# 124 "/usr/include/sys/types.h" 2 3



 
typedef unsigned long int ulong;
typedef unsigned short int ushort;
typedef unsigned int uint;


 

# 158 "/usr/include/sys/types.h" 3


 







typedef int int8_t __attribute__ ((__mode__ (  __QI__ ))) ;
typedef int int16_t __attribute__ ((__mode__ (  __HI__ ))) ;
typedef int int32_t __attribute__ ((__mode__ (  __SI__ ))) ;
typedef int int64_t __attribute__ ((__mode__ (  __DI__ ))) ;


typedef unsigned int u_int8_t __attribute__ ((__mode__ (  __QI__ ))) ;
typedef unsigned int u_int16_t __attribute__ ((__mode__ (  __HI__ ))) ;
typedef unsigned int u_int32_t __attribute__ ((__mode__ (  __SI__ ))) ;
typedef unsigned int u_int64_t __attribute__ ((__mode__ (  __DI__ ))) ;

typedef int register_t __attribute__ ((__mode__ (__word__)));


 






 
# 1 "/usr/include/endian.h" 1 3
 






















 









 
# 1 "/usr/include/bits/endian.h" 1 3
 






# 35 "/usr/include/endian.h" 2 3


 













# 190 "/usr/include/sys/types.h" 2 3


 
# 1 "/usr/include/sys/select.h" 1 3
 


















 






 


 
# 1 "/usr/include/bits/select.h" 1 3
 

























# 37 "/usr/include/bits/select.h" 3












# 57 "/usr/include/bits/select.h" 3

# 73 "/usr/include/bits/select.h" 3

# 31 "/usr/include/sys/select.h" 2 3


 
# 1 "/usr/include/bits/sigset.h" 1 3
 





















typedef int __sig_atomic_t;

 


typedef struct
  {
    unsigned long int __val[(1024 / (8 * sizeof (unsigned long int))) ];
  } __sigset_t;




 





# 125 "/usr/include/bits/sigset.h" 3

# 34 "/usr/include/sys/select.h" 2 3


 

# 1 "/usr/include/time.h" 1 3
 

















 














# 51 "/usr/include/time.h" 3



# 62 "/usr/include/time.h" 3



# 73 "/usr/include/time.h" 3








 

struct timespec
  {
    long int tv_sec;		 
    long int tv_nsec;		 
  };





# 279 "/usr/include/time.h" 3



# 38 "/usr/include/sys/select.h" 2 3


 

 



struct timeval;

typedef __fd_mask fd_mask;

 
typedef __fd_set fd_set;

 



 




 






 




extern int __select  (int __nfds, __fd_set *__readfds,
			  __fd_set *__writefds, __fd_set *__exceptfds,
			  struct timeval *__timeout)    ;
