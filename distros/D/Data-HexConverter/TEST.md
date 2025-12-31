
Manually run a test script with custom library paths:

PERL5LIB=./lib LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./blib/arch/auto/Data/HexConverter perl t/01-roundtrip.t

Benchmark test:  ./benchmark.sh


