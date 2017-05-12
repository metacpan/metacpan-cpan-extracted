#include "httpd.h"
#include "scoreboard.h"

extern int server_limit, thread_limit;

#define DUMMY_SCOREBOARD

scoreboard *ap_scoreboard_image = NULL;

int ap_exists_scoreboard_image(void)
{
    return 0;
}

void modperl_trace(const char *func, const char *fmt, ...);
void modperl_trace(const char *func, const char *fmt, ...)
{

}


