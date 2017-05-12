/usr/bin/perl /usr/local/share/perl/5.10.1/ExtUtils/xsubpp  -typemap /usr/share/perl/5.10/ExtUtils/typemap   Neuron_6185.xs > Neuron_6185.xsc && mv Neuron_6185.xsc Neuron_6185.c
cc -c  -I/home/st47/sit-bmelab-labview/EANN/ANN/t -D_REENTRANT -D_GNU_SOURCE -DDEBIAN -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2 -g   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\" -fPIC "-I/usr/lib/perl/5.10/CORE"   Neuron_6185.c
Neuron_6185.xs: In function ‘_execute_internals’:
Neuron_6185.xs:21: error: redefinition of ‘v1’
Neuron_6185.xs:9: note: previous definition of ‘v1’ was here
Neuron_6185.xs:22: error: redefinition of ‘v2’
Neuron_6185.xs:10: note: previous definition of ‘v2’ was here
make: *** [Neuron_6185.o] Error 1
