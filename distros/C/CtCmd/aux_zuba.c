/*************************************************************************
*                                                                        *
* \251 Copyright IBM Corporation 2001, 2004. All rights reserved.           *
*                                                                        *
* This program and the accompanying materials are made available under   *
* the terms of the Common Public License v1.0 which accompanies this     *
* distribution, and is also available at http://www.opensource.org       *
*                                                                        *
* Contributors:                                                          *
*                                                                        *
* William Spurlin - Creation and initial framework                       *
*                                                                        *
*************************************************************************/

#if defined(hp11_pa) || defined(hp10_pa)
#include <unistd.h>
#endif
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#if defined (sun5)
#include <netdb.h>
#endif
#if defined(hp11_pa) || defined(hp10_pa)
#include <sys/param.h>
#endif
#include <sys/types.h>
#define PORTMAP
#include <rpc/rpc.h>


CLIENT *
clntudp_create(
    struct  sockaddr_in  *addr,
    rpcprog_t prognum,
    rpcvers_t versnum,
    struct timeval wait,
    int *fdp)
{
    CLIENT *rv;
    rv = (CLIENT *)NULL;
    return rv;
}



CLIENT *
clntudp_bufcreate(
    struct  sockaddr_in  *addr,
    rpcprog_t prognum,
    rpcvers_t versnum,
    struct timeval wait,
    int *fdp,
    uint_t sendsz,
    uint_t recvsz)
{
    CLIENT *rv;
    rv = (CLIENT *)NULL;
    return rv;
}


CLIENT *
clnttcp_create(
    struct sockaddr_in *addr,
    u_long prognum,
    u_long versnum,
    int *fdp,
    u_int sendsz,
    u_int recvsz)
{
    CLIENT *rv;
    rv = (CLIENT *)NULL;
    return rv;
}
