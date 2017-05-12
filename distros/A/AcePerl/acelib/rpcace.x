/* $Id: rpcace.x,v 1.1 2003/01/29 21:33:28 lstein Exp $ */

/*
** This file gets processed by rpcgen to make machine specific 
** rpc library hooks
**
** ace_data is for transfer from client to server
** ace_reponse is the canonical rpcgen union.
*/

/* 
   question:
      set by client: a buffer containing the request

   reponse: 
      set by server: a buffer containing the answer

   encore:
      set by server to: -1 if more data remains to be transmitted
      set by client to: -1 to get the the remainder
                        -2 to abort the running query

** JC I prefer negative values to avoid clashes with error values in 
   askServer return values
   
   clientId:
      set by server on first connection,
             must be retransmitted by client each time.
   magic:
      negotiated between  the client and the server,
             must be retransmitted by client each time.

   cardinal:
      set by server to: number of objects in the active list.

   aceError:
      set by server to: 100 Unrecognised command
	                200 Out of context command
                        300 Invalid command (bad nb of parms etc)
                        400 Syntax error in body of command 
   kBytes:
      set by client to: Desired max size of answer, 
                        NOT strict, server is allowed to return more
                        Server only splits on ace boundaries.
*/

#define HAVE_ENCORE   -1
#define WANT_ENCORE   -1
#define DROP_ENCORE   -2
     /* encore == -3 is used in aceclient && aceserver */
#define ACE_IN        -3

#define RPC_PORT rpc_port  

struct ace_data {
  string   question <>;
  opaque   reponse <> ;
  int      clientId ;
  int      magic ;
  int      cardinal ;
  int      encore ;   
  int      aceError ;
  int      kBytes ;  
  };
 
union ace_reponse switch ( int ernumber) {
case 0:
  ace_data    res_data;
default:
  void;
};

/*
** Please don't change this !!!
*/

program RPC_ACE {
  version RPC_ACE_VERS   {
    ace_reponse  ACE_SERVER(ace_data) = 1;
  } = 1;
} = RPC_PORT ;

/* const RPC_ANYSOCK = rpc_socket;  */

/********* end of file **********/


