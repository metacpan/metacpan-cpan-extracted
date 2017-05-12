#ifndef BEOS
#define ab_close(s) close(s)
#define ab_read(a,b,c) read(a,b,c)
#define ab_write(a,b,c) write(a,b,c)
#else
#define ab_close(s) closesocket(s)
#define ab_read(a,b,c) recv(a,b,c,0)
#define ab_write(a,b,c) send(a,b,c,0)
#endif

static void nonblock(int fd);

static void start_connect(struct global * registry, struct connection * c);
static void read_connection(struct global * registry, struct connection * c);
static void close_connection(struct global * registry, struct connection * c);

static void write_request(struct global * registry, struct connection * c);
static int reset_request(struct global * registry, struct connection * c);
static int schedule_next_request(struct global * registry, struct connection * c);
static int schedule_request_in_next_run(struct global * registry, struct connection * c);
