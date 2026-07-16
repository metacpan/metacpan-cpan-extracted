#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <linux/can.h>
#include <linux/can/raw.h>
#include <net/if.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

static int s ;
static struct sockaddr_can addr;


MODULE = CANBUS		PACKAGE = CANBUS		

void teardown()
  CODE:
  close(s);

void setup(const char *iface)

  CODE:
  // Open a socket
  // s = socket(PF_CAN, SOCK_RAW|SOCK_NONBLOCK, CAN_RAW);
  s = socket(PF_CAN, SOCK_RAW, CAN_RAW);

  // Find the interface index
  struct ifreq ifr;

  strcpy(ifr.ifr_name, iface);
  ioctl(s, SIOCGIFINDEX, &ifr);

  // Bind to the interface

  addr.can_family = AF_CAN;
  addr.can_ifindex = ifr.ifr_ifindex;

  bind(s, (struct sockaddr *)&addr, sizeof(addr));

void send(int id, SV *data) 
  INIT:
  I32 dlc = 0;
  int n ;
  AV *av;


  CODE:
  if ((!SvROK(data)) || (SvTYPE(SvRV(data)) != SVt_PVAV))
      croak("First argument must be an array reference");

  av = (AV *)SvRV(data);
  dlc = av_len(av) + 1 ;


  // Send a frame
  struct can_frame frame;

  for (n = 0; n < dlc; n++) {
    SV **svp = av_fetch(av, n, 0);
    if (svp) {
      frame.data[n] = SvIV(*svp);
    }
  }

  frame.can_id  = id;
  frame.can_dlc = dlc;

  int nb ;
  nb = write(s, &frame, sizeof(frame));
  if (nb != 16) printf("wrote %d bytes not 16\n", nb);


void receive() 
  INIT:
  int nd ;

  PPCODE:

  // Receive a frame
  struct can_frame frame;

  nd = read(s, &frame, sizeof(frame));
  if (nd != 16) printf("read %d bytes not 16\n", nd);
  
  EXTEND(SP, 2);
  PUSHs(sv_2mortal(newSViv(frame.can_id & CAN_SFF_MASK)));
  PUSHs(sv_2mortal(newSViv(frame.can_dlc)));

  EXTEND(SP, frame.can_dlc) ;
  for(int i=0;i<frame.can_dlc;i++) PUSHs(sv_2mortal(newSViv(frame.data[i])));
