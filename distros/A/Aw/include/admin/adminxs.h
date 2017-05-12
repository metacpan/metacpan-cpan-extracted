#ifndef AWXS_ADMIN_H
#define AWXS_ADMIN_H 1


typedef struct {
	BrokerLogConfig log_config;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerLogConfig;


typedef struct {
	BrokerAccessControlList acl;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsAccessControlList;


typedef struct {
	BrokerAdminTypeDef type_def;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerAdminTypeDef;


typedef struct {
	BrokerServerClient server_client;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsServerClient;


#endif /* AWXS_ADMIN_H */
