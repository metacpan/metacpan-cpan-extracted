#ifndef AWXS_H
#define AWXS_H 1


typedef struct {
	awAdapter * adapter;
	awAdapterHandle * handle;  /* for handles passed in callbacks */
	BrokerError err;
	char * errMsg;
	char Warn;
	unsigned char callback;
	unsigned char firstCB;
} xsAdapter;


typedef struct {
	awAdapterEventType * adapterET;
	BrokerError err;
	char * errMsg;
	char Warn;
	unsigned char callback;
} xsAdapterEventType;


typedef struct {
	char * license_string;
} xsAdapterLicense;


typedef struct {
	int beQuiet;
	awaBool doPrintf;
	short maxMessageSize;
} xsAdapterLog;


typedef struct {
	awAdapterHandle * handle;
	unsigned char eventsAddOk;
	unsigned char finishOk;
} xsAdapterReplies;


typedef struct {
	awAdapter * adapter;
	awAdapterHandle * handle;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsAdapterUtil;


typedef struct {
	BrokerClient client;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerClient;


typedef struct {
	BrokerConnectionDescriptor desc;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerConnectionDescriptor;


typedef struct {
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerError;


typedef struct {
	BrokerEvent event;
	unsigned char deleteOk;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerEvent;


typedef struct {
	BrokerFilter filter;
	char * event_type_name;
	char * filter_string;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerFilter;


typedef struct {
	BrokerFormatToken * tokens;
	BrokerEvent * event;
	char * format_string;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerFormat;


typedef struct {
	BrokerTypeDef type_def;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerTypeDef;


typedef struct {
	BrokerClient * client;
	BrokerError err;
	char * errMsg;
	char Warn;
} xsBrokerTypeDefCache;


typedef struct {
	SV * self;
	SV * data;
	int id;
	char * method;
} xsCallBackStruct;


#endif /* AWXS_H */
