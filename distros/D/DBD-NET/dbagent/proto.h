#define NET_CONNECTDB (1)
#define NET_PREPARE (2)
#define NET_FETCH (3)
#define NET_CLOSE (4)
#define NET_FREE (5)
#define NET_GETDBS (6)

typedef struct {
	int req;
	int len;
} REQ;

typedef struct {
	int req;
	int len;
	char dat[32*1024];
} REQD;

typedef struct {
	int res;
} RES;

#define RES_OK (1)
#define RES_ERR (0)

typedef struct {
	char login_name[16];
	char passwd[16];
	char dbname[16];
} CONNECT_REQ;

typedef struct {
	int cursorn;
	int descn;
} PREPARE_REP;

typedef struct {
	int cursorn;
} FETCH_REQ;

typedef struct {
	int	descn;
	int tcolen;
	int nrow, datan;
} FETCH_REP;

typedef struct {
	int cursorn;
} CLOSE_REQ;
