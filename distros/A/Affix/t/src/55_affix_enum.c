#include "std.h"

enum TV
{
    FOX = 11,
    CNN = 25,
    ESPN = 15,
    HBO = 22,
    MAX = 30,
    NBC = 32
};

int main(void) {
    printf("List of cable stations: \n");
    printf(" FOX: \t%2d\n", FOX);
    printf(" HBO: \t%2d\n", HBO);
    printf(" MAX: \t%2d\n", MAX);
}

DLLEXPORT enum TV TakeEnum(enum TV value) {
    switch (value) {
    case FOX:
        return -FOX;
        /*
        case 'f':
            return offsetof(structure, f);
        case 'd':
            return offsetof(structure, d);
        case 'c':
            return offsetof(structure, c);
        case 'j':
            return offsetof(structure, j);*/
    default:
        break;
    }

    return -1;
}
