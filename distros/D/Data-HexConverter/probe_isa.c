// gcc -O3 -Wall -Wextra -mavx512bw -mavx512vl -o probe_isa probe_isa.c 
#include <stdio.h>
#include <immintrin.h>
int main(){
  unsigned a,b,c,d; int sse2=0,avx=0,avx2=0,avx512bw=0,avx512vl=0; 
  __asm__ __volatile__("cpuid":"=a"(a),"=b"(b),"=c"(c),"=d"(d):"a"(1),"c"(0));
  sse2 = !!(d & (1u<<26));
  int osxsave = !!(c & (1u<<27));
  unsigned long long xcr0=0; if(osxsave){ unsigned eax,edx; __asm__ __volatile__(".byte 0x0f,0x01,0xd0":"=a"(eax),"=d"(edx):"c"(0)); xcr0=((unsigned long long)edx<<32)|eax; }
  int os_avx = osxsave && ((xcr0 & 0x6)==0x6); avx = os_avx && !!(c & (1u<<28));
  __asm__ __volatile__("cpuid":"=a"(a),"=b"(b),"=c"(c),"=d"(d):"a"(7),"c"(0));
  avx2 = avx && !!(b & (1u<<5));
  int os_avx512 = osxsave && ((xcr0 & 0xE0)==0xE0);
  avx512bw = os_avx512 && !!(b & (1u<<30));
  avx512vl = os_avx512 && !!(b & (1u<<31));
  printf("FEATURES:"); if(sse2)printf(" sse2"); if(avx)printf(" avx"); if(avx2)printf(" avx2"); if(avx512bw)printf(" avx512bw"); if(avx512vl)printf(" avx512vl"); printf("\n"); return 0; }
