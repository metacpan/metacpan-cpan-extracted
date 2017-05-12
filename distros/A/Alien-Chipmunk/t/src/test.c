#include <chipmunk.h>
#include <stdio.h>

int main(int argc, const char *argv[])
{
    cpVect gravity = cpv(0, -100);

    cpSpace *space = cpSpaceNew();
    cpSpaceSetGravity(space, gravity);

    cpSpaceFree(space);

    return 0;
}

