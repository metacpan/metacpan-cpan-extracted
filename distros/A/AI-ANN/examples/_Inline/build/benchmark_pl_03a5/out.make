/usr/bin/perl /usr/local/share/perl/5.10.1/ExtUtils/xsubpp  -typemap /usr/share/perl/5.10/ExtUtils/typemap   benchmark_pl_03a5.xs > benchmark_pl_03a5.xsc && mv benchmark_pl_03a5.xsc benchmark_pl_03a5.c
cc -c  -I/home/st47/sit-bmelab-labview/EANN/ANN/examples -D_REENTRANT -D_GNU_SOURCE -DDEBIAN -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2 -g   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\" -fPIC "-I/usr/lib/perl/5.10/CORE"   benchmark_pl_03a5.c
benchmark_pl_03a5.xs: In function ‘generate_globals’:
benchmark_pl_03a5.xs:11: error: array subscript is not an integer
benchmark_pl_03a5.xs:12: error: array subscript is not an integer
benchmark_pl_03a5.xs:12: error: invalid type argument of ‘unary *’ (have ‘int’)
make: *** [benchmark_pl_03a5.o] Error 1
