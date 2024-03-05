#include <time.h>
#include <stdio.h>
#include <stdlib.h>
 
int main(int argc, char *argv[]) {
   char   *format;
   char   outstr[200];
   time_t t;
   struct tm *tmp;
 
   format = argv[1];
   if (argc > 2) {
      t   = (time_t) atoll(argv[2]);
   } else {
      t   = time(NULL);
   }

   tmp = localtime(&t);
   if (tmp == NULL) {
       perror("localtime");
       exit(EXIT_FAILURE);
   }

   if (strftime(outstr, sizeof(outstr), argv[1], tmp) == 0) {
       fprintf(stderr, "strftime returned 0");
       exit(EXIT_FAILURE);
   }

   printf("%s\n", outstr);
   exit(EXIT_SUCCESS);
}

