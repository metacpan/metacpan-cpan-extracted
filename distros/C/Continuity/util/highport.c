
/*

  Turns CGI hits back into HTTP hits to transparently proxy hits on a
  main Webserver into hits on a high-port application process with its
  own Webserver.  More generally, it adds proxying capabilities to Webserver
  such as thttpd that lack the feature natively.

  This version is incomplete with regards to the headers it sends.  It's
  also woefully lacking in the options department.

  There's dead code that should be removed.

  There are probably better versions of this same thing floating around.

  Scott Walters, 200604, scott@slowass.net

 */

#include <unistd.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

extern int errno;
int s;
int errlog;

int
main(int argc, char *argv[]) {

    int port;
    char buf[8192];
    struct sockaddr_in peer;
    fd_set rfds, efds;
    struct timeval tv;
    int err;
    int errlen = sizeof(err);
    int line_skipped = 0;
    int zero_bytes_in_row = 0;
    int zero_bytes_in_row_in = 0;
    char * query_string;

    // http://cgi-spec.golux.com/draft-coar-cgi-v11-03.html
    if(argc < 2) exit(1);
    port = atoi(argv[1]);

    peer.sin_family       = AF_INET;
    peer.sin_addr.s_addr  = inet_addr("127.0.0.1");
    peer.sin_port         = htons(port);

    s = socket( AF_INET, SOCK_STREAM, 0 );
    if(!s) exit(2);

    // errlog = open("/tmp/highport.log", O_WRONLY|O_CREAT);

    if ( connect( s, ( struct sockaddr * )&peer, sizeof( peer ) ) ) {
        perror("socket connect failed");
        exit(4);
    }

    // synthesize a basic HTTP request line and then synthesize headers
    query_string = (char *)getenv("QUERY_STRING"); 
    snprintf(buf, sizeof(buf), "%s %s%s%s HTTP/1.0\r\n\000", getenv("REQUEST_METHOD"), getenv("SCRIPT_NAME"), query_string ? "?" : "", query_string ? query_string : "");
    up(buf, strlen(buf));
    if(getenv("HTTP_REFERER")) { snprintf(buf, sizeof(buf), "Referer: %s\r\n", getenv("HTTP_REFERER")); up(buf, strlen(buf)); }
    if(getenv("AUTH_TYPE")) { snprintf(buf, sizeof(buf), "Authorization: %s\r\n", getenv("AUTH_TYPE")); up(buf, strlen(buf)); }
    if(getenv("CONTENT_LENGTH")) { snprintf(buf, sizeof(buf), "Content-Length: %s\r\n", getenv("CONTENT_LENGTH")); up(buf, strlen(buf)); }
    if(getenv("CONTENT_TYPE")) { snprintf(buf, sizeof(buf), "Content-Type: %s\r\n", getenv("CONTENT_TYPE")); up(buf, strlen(buf)); }
    if(getenv("REMOTE_ADDR")) { snprintf(buf, sizeof(buf), "Remote-Address: %s\r\n", getenv("REMOTE_ADDR")); up(buf, strlen(buf)); } // ad-hoc for our puroses, since peeraddr will always return 127.0.0.1 or the server's IP otherwise
    if(getenv("HTTP_USER_AGENT")) { snprintf(buf, sizeof(buf), "User-Agent: %s\r\n", getenv("HTTP_USER_AGENT")); up(buf, strlen(buf)); }
    if(getenv("HTTP_COOKIE")) { snprintf(buf, sizeof(buf), "Cookie: %s\r\n", getenv("HTTP_COOKIE")); up(buf, strlen(buf)); }
    up("\r\n", 2); // that's that

    // read-loop

    FD_ZERO(&rfds); FD_ZERO(&efds);

    while(1) {

        // if input from browser is waiting, read and relay it
        if(FD_ISSET(0, &rfds)) {
            int bytes;
            bytes = read(0, buf, sizeof(buf));
            if(bytes == -1 && errno != EINTR && errno != EAGAIN) { perror("copy to webserver"); exit(0); }
            if(bytes > 0) {
                zero_bytes_in_row_in = 0;
                up(buf, bytes);
            } else {
                zero_bytes_in_row_in++;
                // printf("0 bytes read from socket\n");  // this is the normal EOF condition -- exit successfully
                // exit(0);
            }
        }

        // if input from server is waiting, read and relay it
        if(FD_ISSET(s, &rfds)) {
            int bytes;
            bytes = read(s, buf, sizeof(buf));
            if(bytes == -1 && errno != EINTR && errno != EAGAIN) { perror("copy from webserver"); exit(0); }
            if(bytes > 0) {
                zero_bytes_in_row = 0;
                if(! line_skipped) {
                   // skip the first line, which contains something like 'HTTP/1.0 200 OK'
                   int off;
                   for(off=0; off+2<bytes && buf[off] != '\r'; off++); 
                   off++;
                   if(buf[off] == '\n') off++;
                   write(0, buf+off, bytes-off);
                   if(errlog) { write(errlog, "in:  ", 5); write(errlog, buf+off, bytes-off); }
                   line_skipped = 1;
                } else {
                   write(1, buf, bytes);
                   if(errlog) { write(errlog, "in:  ", 5); write(errlog, buf, bytes); }
                }
            } else {
                // printf("0 bytes read from socket\n");  // this is the normal EOF condition -- exit successfully
                zero_bytes_in_row++;
                if(zero_bytes_in_row > 10) exit(0);
            }
        }

        // set-up select, select, and loop
        if(zero_bytes_in_row_in < 10) { FD_SET(0, &rfds); FD_SET(0, &efds); } else { FD_CLR(0, &rfds); }
        FD_SET(s, &rfds); FD_SET(s, &efds);
        tv.tv_sec = 5; tv.tv_usec = 0;
        select(s+1, &rfds, 0, 0, &tv);

        // debugging... this isn't strictly necessary
        //if( FD_ISSET(s, &efds) || FD_ISSET(0, &efds) ) {
        //    perror("error condition on fh");
        //    exit(4);
        //}

        // debugging... this isn't strictly necessary
        getsockopt( s, SOL_SOCKET, SO_ERROR, &err, &errlen);
        if(err) {
            errno = err;
            perror("error condition on socket");
        }
  
    }

    close(s);
    exit(0);

}

int
up(char text[], int bytes) {
    int ret = write(s, text, bytes);
    if(errlog) { write(errlog, "out: ", 5); write(errlog, text, bytes); }
    return ret;
}


     //   { "AUTH_TYPE", "Authorization" },
    //    { "CONTENT_LENGTH", "Content-Length" },
    //    { "CONTENT_TYPE", "Content-Type" },
    //    { "HTTP_REFERRER", "Referer" },    // obeserved in the wild
    //    { "REMOTE_ADDR", "Remote-Address" }, // made up this HTTP header to cope with peeraddr being 127.0.0.1
    //    { "HTTP_USER_AGENT", "User-Agent" }, // observed in the wild
        // GATEWAY_INTERFACE -- part of initial request
        // PATH_INFO
        // PATH_TRANSLATED
        // GATEWAY_INTERFACE=CGI/1.1
        // QUERY_STRING -- part of initial request
        // REMOTE_HOST
        // REMOTE_IDENT
        // REMOTE_USER is dervied from the HTTP auth information... not sure how this is done
        // REQUEST_METHOD -- part of initial request
        // SCRIPT_NAME=/projects/brainerd/test.cgi
        // SERVER_NAME=slowass.net
        // SERVER_PORT=80
        // SERVER_PROTOCOL=HTTP/1.0
        // SERVER_SOFTWARE=Apache/1.3.6 (Unix)
        // the following are merely observed from Apache:
        // HTTP_ACCEPT_CHARSET=iso-8859-1,*,utf-8
        // DOCUMENT_ROOT=/usr/home/httpd/html
        // SERVER_SIGNATURE=
        // HTTP_ACCEPT=image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*
        // SCRIPT_FILENAME=/usr/home/httpd/html/projects/brainerd/test.cgi
        // HTTP_HOST=slowass.net
        // REQUEST_URI=/projects/brainerd/test.cgi
        // HTTP_CONNECTION=Keep-Alive
        // HTTP_ACCEPT_LANGUAGE=en
        // HTTP_ACCEPT_ENCODING=gzip
        // SERVER_ADMIN=phaedrus@endless.org
    //};


