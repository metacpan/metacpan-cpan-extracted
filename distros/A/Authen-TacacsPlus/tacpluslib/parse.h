/* 
   Copyright (c) 1995-1996 by Cisco systems, Inc.

   Permission to use, copy, modify, and distribute this software for
   any purpose and without fee is hereby granted, provided that this
   copyright and permission notice appear on all copies of the
   software and supporting documentation, the name of Cisco Systems,
   Inc. not be used in advertising or publicity pertaining to
   distribution of the program without specific prior permission, and
   notice be given in supporting documentation that modification,
   copying and distribution is by permission of Cisco Systems, Inc.

   Cisco Systems, Inc. makes no representations about the suitability
   of this software for any purpose.  THIS SOFTWARE IS PROVIDED ``AS
   IS'' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
   WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
   FITNESS FOR A PARTICULAR PURPOSE.
*/

/* Keywords & values */

#define S_eof             99
#define S_unknown         101
#define S_separator       104
#define S_string          106
#define S_openbra         107
#define S_closebra        108
#define S_svc_dflt        109

#define S_key             1
#define S_user            2
#define S_group           3
#define S_host            4
#define S_accounting      5
#define S_name            7
#define S_login           8
#define S_member          9
#define S_expires         10
#define S_cleartext       11
#define S_message         12
#define S_arap            13
#define S_chap            14
#define S_after		  15
#define S_pap             16
#define S_svc             17
#define S_before          18
#define S_default         19
#define S_access          20
#define S_deny            21
#define S_permit          22
#define S_exec            23
#define S_protocol        24
#define S_optional        25
#define S_ip              26
#define S_ipx             27
#define S_slip            28
#define S_ppp             29
#define S_file            30
#define S_skey            31
#define S_authorization   32
#define S_authentication  33
#define S_cmd             34
#define S_attr            35
#define S_lcp		  36
#define S_global	  37
#define S_des		  38
#define S_opap            39
#ifdef MAXSESS
#define S_maxsess	  40
#endif
