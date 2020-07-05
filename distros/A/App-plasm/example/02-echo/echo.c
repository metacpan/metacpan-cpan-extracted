#include <stdio.h>

int
main(int argc, char *argv[])
{
  int i,n;
  for(i=1; i<argc; i++)
  {
    if(i != 1)
      putchar(' ');
    for(n=0; argv[i][n] != '\0'; n++)
      putchar(argv[i][n]);
  }
  if(argc > 1)
    putchar('\n');
}
