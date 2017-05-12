#include <stdlib.h>
#include <string.h>

#include "types.h"
#include "http_util.h"

/* ------------------------------------------------------- */

/* split URL into parts */

static int
parse_url(struct global * registry, char *p, int i) {
    char *url = (char *) malloc((strlen(p)+1) * sizeof(char));
    char *port, *tok, *tok2;

    /* first, get a copy of url */
    strcpy(url, p);

    /* remove http:// prefix if it exists */
    if (strlen(url) > 7 && strncmp(url, "http://", 7) == 0)
	url += 7;

#ifdef AB_DEBUG
    printf("AB_DEBUG: parse_url() - stage 1\n");
#endif

    /* first, extract the hostname and port */
    tok = strtok(url, "/");

#ifdef AB_DEBUG
    printf("AB_DEBUG: parse_url() - stage 2\n");
#endif

    /* the remaining part of url is just the uri */
    tok2 = strtok(NULL, "");

#ifdef AB_DEBUG
    printf("AB_DEBUG: parse_url() - stage 3\n");
#endif

    registry->hostname[i] = (char *) malloc((strlen(tok)+1) * sizeof(char));
    strcpy(registry->hostname[i], strtok(tok, ":"));
    if ((port = strtok(NULL, "")) != NULL)
	registry->port[i] = atoi(port);

#ifdef AB_DEBUG
    printf("AB_DEBUG: parse_url() - stage 4\n");
#endif

    /* if there is no uri, url was of the form http://host.name - assume / */
    if (tok2 == NULL) {
	registry->path[i] = "/";
	return 0;
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: parse_url() - stage 5\n");
#endif

    /* need to allocate memory for uri */
    registry->path[i] = (char *) malloc((strlen(tok2)+2) * sizeof(char));

    /* only add leading / if not proxy request */
    if (strncmp(tok2, "http://", 7) != 0) {
	strcpy(registry->path[i], "/");
	strcat(registry->path[i], tok2);
    } else
	strcpy(registry->path[i], tok2);

    return 0;
}


/* --------------------------------------------------------- */

/* extract cookies from response_data (Set-Cookie: headers) and save to auto_cookies */

static void
allocate_auto_cookie_memory(struct global * registry, struct connection * c) {
#ifdef AB_DEBUG
    printf("AB_DEBUG: start of allocate_auto_cookie_memory(): run %d, thread %d\n", c->run, c->thread);
#endif

    if (registry->auto_cookies[c->run] == NULL) {
        registry->auto_cookies[c->run] = (char **) calloc(registry->repeats[c->run], sizeof(char *));
#ifdef AB_DEBUG
        printf("AB_DEBUG: allocate_auto_cookie_memory() - stage 1: run %d, thread %d\n", c->run, c->thread);
#endif
    }
        
    if (registry->auto_cookies[c->run][c->thread] == NULL) {
        registry->auto_cookies[c->run][c->thread] = (char *) calloc(CBUFFSIZE, sizeof(char));
#ifdef AB_DEBUG
        printf("AB_DEBUG: allocate_auto_cookie_memory() - stage 2: run %d, thread %d\n", c->run, c->thread);
#endif
    }
}

static void
extract_cookies_from_response(struct global * registry, struct connection * c) {
    char * set_cookie_hdr, * eoh;

#ifdef AB_DEBUG
    printf("AB_DEBUG: start of extract_cookies_from_response()\n");
#endif
    if (registry->failed[c->url] > 0)
        return;

    allocate_auto_cookie_memory(registry, c);

#ifdef AB_DEBUG
    printf("AB_DEBUG: extract_cookies_from_response() - stage 1; run %d, thread %d\n", c->run, c->thread);
#endif

    if (! c->response_headers) return;

    set_cookie_hdr = strstr(c->response_headers, "\r\nSet-Cookie: ");
    while (set_cookie_hdr) {
        remove_existing_cookie_from_auto_cookies(registry, c, set_cookie_hdr);

#ifdef AB_DEBUG
        printf("AB_DEBUG: extract_cookies_from_response() - stage 2.1; run %d, thread %d, postdata[%d] = %s\n", c->run, c->thread, c->url, registry->postdata[c->url]);
#endif

        eoh = strstr(set_cookie_hdr+2, "\r\n");
        if (! strnstr(set_cookie_hdr, "=; Expires=", eoh - set_cookie_hdr)) // hack: do not set expired headers
            // drop the "Set-" from beginning to just append "Cookie: ....\r\n"
            strncat(registry->auto_cookies[c->run][c->thread], set_cookie_hdr + 6, eoh - set_cookie_hdr - 4);

#ifdef AB_DEBUG
        printf("AB_DEBUG: extract_cookies_from_response() - stage 2.2; run %d, thread %d, auto_cookies[%d][%d] = %s\n", c->run, c->thread, c->run, c->url, registry->auto_cookies[c->run][c->thread]);
#endif

        set_cookie_hdr = strstr(set_cookie_hdr+1, "\r\nSet-Cookie: ");
    }
}

/* remove existing cookies from registry->auto_cookies[..][..] which will be set again by extract_cookies_from_response() */

static void
remove_existing_cookie_from_auto_cookies(struct global * registry, struct connection * c, char * set_cookie_hdr) {
    char *existing_cookie, *end_of_existing_cookie, *cookie_name, *new_auto_cookies, *eoh;

#ifdef AB_DEBUG
    printf("AB_DEBUG: start of remove_existing_cookie_from_auto_cookies(), postdata[%d] = %s\n", c->url, registry->postdata[c->url]);
#endif
    // first need to find the name of cookie on current "Set-Cookie: " header line
    cookie_name = (char *) calloc(CBUFFSIZE, sizeof(char));
    strcat(cookie_name, "Cookie: ");
    eoh = strstr(set_cookie_hdr+14, "\r\n");
    strncat(cookie_name, set_cookie_hdr+14, strnstr(set_cookie_hdr+14, "=", eoh-(set_cookie_hdr+14)) - (set_cookie_hdr+14));

#ifdef AB_DEBUG
    printf("AB_DEBUG: remove_existing_cookie_from_auto_cookies() - stage 1\n");
#endif

    existing_cookie = strstr(registry->auto_cookies[c->run][c->thread], cookie_name);

#ifdef AB_DEBUG
    printf("AB_DEBUG: remove_existing_cookie_from_auto_cookies() - stage 1.1\n");
#endif
    if (existing_cookie) {
        new_auto_cookies = (char *) calloc(CBUFFSIZE, sizeof(char));

#ifdef AB_DEBUG
        printf("AB_DEBUG: remove_existing_cookie_from_auto_cookies() - stage 2.1\n");
#endif

        strncpy(new_auto_cookies, registry->auto_cookies[c->run][c->thread], existing_cookie - registry->auto_cookies[c->run][c->thread]);
        end_of_existing_cookie = strstr(existing_cookie, "\r\n");
        strcat(new_auto_cookies, end_of_existing_cookie+2);

#ifdef AB_DEBUG
        printf("AB_DEBUG: remove_existing_cookie_from_auto_cookies() - stage 2.2\n");
#endif

        // overwrite auto_cookies with new version with existing_cookie removed
        strcpy(registry->auto_cookies[c->run][c->thread], new_auto_cookies);
        free(new_auto_cookies);

#ifdef AB_DEBUG
        printf("AB_DEBUG: remove_existing_cookie_from_auto_cookies() - stage 2.3, auto_cookies[%d][%d] = %s\n", c->url, c->thread, registry->auto_cookies[c->url][c->thread]);
#endif
    }
#ifdef AB_DEBUG
    printf("AB_DEBUG: remove_existing_cookie_from_auto_cookies() - stage 3, cookie_name = %s\n", cookie_name);
#endif

    free(cookie_name);

#ifdef AB_DEBUG
    printf("AB_DEBUG: end of remove_existing_cookie_from_auto_cookies(), postdata[%d] = %s\n", c->url, registry->postdata[c->url]);
#endif
}
