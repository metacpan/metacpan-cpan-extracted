use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];

BEGIN {
    unless ( eval { require Socket; Socket->import(qw[:all]); 1 } ) {
        print "1..0 # SKIP Socket module required\n";
        exit 0;
    }
}
#
$|++;
#
my $lib = compile_ok(<<~'END_C');
    #include "std.h"
    //ext: .c

    // Minimal definition to ensure struct layout matches system
    #if defined(_WIN32)
      #include <winsock2.h>
    #else
      #include <netinet/in.h>
    #endif

    // We implement a manual byte swap to verify the data arrived correctly
    // without needing to link against system network libraries (ws2_32.dll etc)
    // which simplifies the test build process.
    DLLEXPORT int get_port_raw(struct sockaddr_in* sa) {
        if (!sa) return -1;
        // Return raw network-byte-order value
        return sa->sin_port;
    }

    DLLEXPORT unsigned long get_addr(struct sockaddr_in* sa) {
        if (!sa) return 0;
        return sa->sin_addr.s_addr;
    }
    END_C
affix $lib, 'get_port_raw', [SockAddr] => UShort;
affix $lib, 'get_addr',     [SockAddr] => ULong;
#
my $port = 8080;
my $ip   = '127.0.0.1';

# Pack using Perl's standard Socket function (Network Byte Order)
my $sa = pack_sockaddr_in( $port, inet_aton($ip) );

# Verify Port
# C returns raw network short (Big Endian).
# unpack('n') converts "Network to Native".
my $raw_port_from_c = get_port_raw($sa);
my $port_back       = unpack 'n', pack 'S', $raw_port_from_c;

# On Little Endian systems (x86), pack('S') puts the bytes in LE.
# But wait, C returned a UShort (number).
# If C read 0x1F90 (8080) from memory as a short on LE, it saw 0x901F (36895).
# Let's just verify round-trip logic via 'n' (Network order).
# Simpler check: Just pack the Perl port into network order and compare values
my $expected_raw_port = unpack 'S', pack( 'n', $port );
is $raw_port_from_c, $expected_raw_port, 'Port passed correctly (Network Byte Order preserved)';

# Verify IP
# IP is just a 32-bit int, raw
my $raw_addr      = get_addr($sa);
my $expected_addr = unpack 'L', inet_aton($ip);
is $raw_addr, $expected_addr, 'IP address passed correctly';
done_testing;
