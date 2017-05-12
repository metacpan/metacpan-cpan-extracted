/usr/bin/perl /usr/local/share/perl/5.10.1/ExtUtils/xsubpp  -typemap /usr/share/perl/5.10/ExtUtils/typemap   benchmark_pl_b832.xs > benchmark_pl_b832.xsc && mv benchmark_pl_b832.xsc benchmark_pl_b832.c
cc -c  -I/home/st47/sit-bmelab-labview/EANN/ANN/examples -D_REENTRANT -D_GNU_SOURCE -DDEBIAN -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2 -g   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\" -fPIC "-I/usr/lib/perl/5.10/CORE"   benchmark_pl_b832.c
benchmark_pl_b832.xs:5: fatal error: libm/math.h: No such file or directory
compilation terminated.
make: *** [benchmark_pl_b832.o] Error 1
