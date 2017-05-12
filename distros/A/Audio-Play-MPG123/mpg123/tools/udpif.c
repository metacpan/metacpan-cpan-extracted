/* Demonstration for a VERY VERY simple and UNSECURE remote 
 * interface via UDP .. maybe TCP is a better decision here
 *
 * Change the IP of your MPG123 Server Host if necessary (default is 127.0.0.1)
 *
 * To start the mpg123 server call on the server machine
 *   udpif | mpg123 -R 
 *
 * To control the player try ie (here: play a file)
 *   udpif "PLAY blabla.mp3"
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
  int udp_socket;
  struct sockaddr_in udpaddr;    /* local socket address */
  struct fd_set readmask,readmask1;

  udpaddr.sin_family      = AF_INET;
  udpaddr.sin_addr.s_addr = INADDR_ANY;
  udpaddr.sin_port        = htons(MPG123_UDP);

  if((udp_socket = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
    perror(argv[0]);
    exit(1);
  }

  FD_ZERO(&readmask);
  FD_SET(udp_socket, &readmask);

  if(argc > 1) {
    int ret;
    udpaddr.sin_addr.s_addr = htonl( inet_addr(MPG123_SERVERHOST) );
    ret = sendto(udp_socket,argv[1],strlen(argv[1]),0,(struct sockaddr *) &udpaddr,sizeof(struct sockaddr));

    fprintf(stderr,"%d %lx\n",ret,udpaddr.sin_addr.s_addr);
    return 0;
  }

  if (bind(udp_socket,(struct sockaddr *) &udpaddr, sizeof(struct sockaddr)) ==
- 1) {
     perror("bind");
     exit(1);
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

