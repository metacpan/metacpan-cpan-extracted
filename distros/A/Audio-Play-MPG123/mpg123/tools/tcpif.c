/* Demonstration for a VERY VERY simple and UNSECURE remote 
 * interface via TCP
 *
 * Change the IP of your MPG123 Server Host if necessary (default is 127.0.0.1)
 *
 * To start the mpg123 server call on the server machine 
 *   tcpif 
 *
 * To control the player try ie (here: play a file)
 *   tcpif "PLAY blabla.mp3"
 * Note 'blabla.mp3' must lie on the server side!
 */

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define MPG123_SERVERHOST "127.0.0.1"
#define MPG123_UDP 22123

int main(int argc,char **argv)
{
  int tcp_socket;
  struct sockaddr_in tcpaddr;    /* local socket address */
  struct fd_set readmask,readmask1;
  int p[2];

  if(pipe(p) == -1) {
    perror("pipe");
    exit(1);
  }

  f = fork();

  if(f == 0) {
    close(p[1]);
    close(0); close(1);
    dup(p[0]);
    dup[p[0]);
    execl("mpg123s-mh3","-R",NULL);
    exit(1);
  }
  close(p[0]);

  tcpaddr.sin_family      = AF_INET;
  tcpaddr.sin_addr.s_addr = INADDR_ANY;
  tcpaddr.sin_port        = htons(MPG123_UDP);

  if((udp_socket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
    perror(argv[0]);
    exit(1);
  }

  FD_ZERO(&readmask);
  FD_SET(tcp_socket, &readmask);

  if (bind(tcp_socket,(struct sockaddr *) &udpaddr, sizeof(struct sockaddr)) ==
- 1) {
     perror("bind");
     exit(1);
  }

  for(;;) {
    if(listen(tcp_socket,5) == -1) {
      perror("listen");
      exit(1);
    }
    
  }

  for(;;)
  {
    int numfds,count;
    unsigned char buf[1024];

    readmask1 = readmask;
   
    if ((numfds = select(udp_socket+1,&readmask1,NULL,NULL,NULL)) < 0) {
      if(errno != EINTR) {
        perror("select error");
        exit(1);
      }
      continue;
    }
    
    if(FD_ISSET(udp_socket,&readmask1)) {
      memset(buf,0,1024);
      count =  recv(udp_socket,buf,1023,0);
      fprintf(stdout,"%s\n",buf);
      fflush(stdout);
      fprintf(stderr,"%s\n",buf);
    }
  }

  return 0;
}

