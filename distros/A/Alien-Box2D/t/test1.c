#include <Box2D/Box2D.h>
#include <stdio.h>

int main()
{
  printf("b2_version is %d.%d.%d\n", b2_version.major, b2_version.minor, b2_version.revision);
  printf("b2IsValid(1.5)=%d\n", b2IsValid(1.5));

  return 0;
}
