# CMake generated Testfile for 
# Source directory: /home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/src
# Build directory: /home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/build/src
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(secp256k1_noverify_tests "/home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/build/bin/noverify_tests")
set_tests_properties(secp256k1_noverify_tests PROPERTIES  _BACKTRACE_TRIPLES "/home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/src/CMakeLists.txt;90;add_test;/home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/src/CMakeLists.txt;0;")
add_test(secp256k1_tests "/home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/build/bin/tests")
set_tests_properties(secp256k1_tests PROPERTIES  _BACKTRACE_TRIPLES "/home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/src/CMakeLists.txt;95;add_test;/home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/src/CMakeLists.txt;0;")
add_test(secp256k1_exhaustive_tests "/home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/build/bin/exhaustive_tests")
set_tests_properties(secp256k1_exhaustive_tests PROPERTIES  _BACKTRACE_TRIPLES "/home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/src/CMakeLists.txt;104;add_test;/home/bartosz/dox/Perl-Bitcoin/Alien-libsecp256k1/libsecp256k1/src/CMakeLists.txt;0;")
