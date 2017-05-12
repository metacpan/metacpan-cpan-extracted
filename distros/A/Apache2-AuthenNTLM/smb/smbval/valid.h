#ifndef _VALID_H_
#define _VALID_H_
/* SMB User verification function */

#define NTV_NO_ERROR 0
#define NTV_SERVER_ERROR 1
#define NTV_PROTOCOL_ERROR 2
#define NTV_LOGON_ERROR 3

int Valid_User(char *username,char *password,char *server, char *backup, char *domain);
void *Valid_User_Connect(char *server,char *backup, char *domain, char *nonce) ;
int Valid_User_Auth(void *handle, char *username,char *password,int precrypt, char * domain) ;
void Valid_User_Disconnect(void *handle) ;

#endif
