// NOTICE:  Copyright 1991-2010, Phillip Paul Fuchs, golfed by KS
// gcc -o perm perm.c ; ./perm

#define N 10
#include <stdio.h>

void disp(int *a) {
  int x=0; while( x < N ) { printf("%d",a[x]); if (++x<N) printf(" "); }
  printf("\n");
}

void main(void) {
   int a[N], p[N+1], i, j, tmp;       // target array, index control array, i, j, tmp
   for( i=0; i<N; i++ ) a[i]=p[i]=i;
   p[N] = N;                          // p[N] > 0 controls iteration and the index boundary for i
   i = 1;                             // setup first swap points to be 1 and 0 respectively (i & j)
   disp(a);
   while( i<N ) {
      p[i]--;
      j = 0;
      do {tmp=a[j]; a[j]=a[i]; a[i]=tmp; } while (++j < --i); // reverse array from j to i
      for(i=1;!p[i];i++) p[i]=i;
      disp(a);
   }
}
