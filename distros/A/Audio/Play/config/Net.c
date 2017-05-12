#include <audio/audiolib.h>
#include <audio/soundlib.h>

int main(argc,argv)
int argc;
char *argv[];
{
 char *error;
 AuServer *svr = AuOpenServer(NULL,0,"",0,"",&error); 
 if (svr)
  {
   AuCloseServer(svr);
   exit(0);
  }
 exit(1);
}
