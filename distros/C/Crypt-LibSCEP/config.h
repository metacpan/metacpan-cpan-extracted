typedef struct {
char *passin;
char *passwd;
SCEP *handle;
bool cleanup;
} Conf;

typedef struct {
char *so;
char *pin;
char *label;
char *module;
} Engine_conf;