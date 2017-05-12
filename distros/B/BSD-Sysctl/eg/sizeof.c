/* sizeof.c - Display the size of various data structures of
 * opaque sysctl results.
 *
 * Copyright (C) 2006 David Landgren, all rights reserved
 */

#include <sys/param.h>
#include <sys/types.h>
#include <sys/mbuf.h>         /* struct mbstat */
#include <sys/timex.h>        /* struct ntptimeval */
#include <sys/devicestat.h>   /* struct devstat */
#include <sys/mount.h>        /* struct xvfsconf */
#include <arpa/inet.h>        /* struct icmpstat prerequisite */
#include <netinet/in_systm.h> /* struct icmpstat prerequisite */
#include <netinet/ip.h>       /* struct icmpstat prerequisite */
#include <netinet/ip_icmp.h>  /* struct icmpstat prerequisite */
#include <netinet/icmp_var.h> /* struct icmpstat */
#include <netinet/igmp_var.h> /* struct igmpstat */
#include <netinet/tcp_var.h>  /* struct tcpstat */
#include <netinet/in.h>       /* struct udpstat prerequisite */
#include <netinet/ip_var.h>   /* struct udpstat prerequisite */
#include <netinet/udp.h>      /* struct udpstat prerequisite */
#include <netinet/udp_var.h>  /* struct udpstat */
#ifdef NEVER
#include <sys/socket.h>       /* struct xinpcb */
#include <netinet/in_pcb.h>   /* struct xinpcb */
#endif
#include <netinet6/raw_ip6.h> /* struct rip6stat */
#include <machine/bootinfo.h> /* struct bootinfo */

int
main(int argc, char **argv) {
    printf( "sizeof(int) = %d\n", sizeof(int) );
    printf( "sizeof(struct mbstat) = %d\n", sizeof(struct mbstat) );
    printf( "sizeof(struct ntptimeval) = %d\n", sizeof(struct ntptimeval) );
    printf( "sizeof(struct timespec) = %d\n", sizeof(struct timespec) );
    printf( "sizeof(struct devstat) = %d\n", sizeof(struct devstat) );
    printf( "sizeof(struct xvfsconf) = %d\n", sizeof(struct xvfsconf) );
    printf( "%f\n", 252.0/36.0 );
    printf( "sizeof(struct icmpstat) = %d\n", sizeof(struct icmpstat) );
    printf( "sizeof(struct igmpstat) = %d\n", sizeof(struct igmpstat) );
    printf( "sizeof(struct tcpstat) = %d\n", sizeof(struct tcpstat) );
    printf( "sizeof(struct udpstat) = %d\n", sizeof(struct udpstat) );
    /* printf( "sizeof(struct xinpcb) = %d\n", sizeof(struct xinpcb) ); */
    printf( "sizeof(struct rip6stat) = %d\n", sizeof(struct rip6stat) );
    printf( "sizeof(struct bootinfo) = %d\n", sizeof(struct bootinfo) );
    return 0;
}
