static int parse_url(struct global * registry, char *p, int i);
static void extract_cookies_from_response(struct global * registry, struct connection * c);
static void remove_existing_cookie_from_auto_cookies(struct global * registry, struct connection * c, char * set_cookie_hdr);
