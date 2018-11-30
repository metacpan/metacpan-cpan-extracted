use strict;
use warnings;
use Test::More tests => 23;
use File::Spec ();
use Test::NoWarnings;

BEGIN { use_ok('Authen::Radius', qw(0.28)) };

my $auth = Authen::Radius->new(Host => '127.0.0.1', Secret => 'secret', Debug => 0);
ok($auth, 'object created');

my $freeradius_path = $ENV{TEST_FREERADIUS_PATH} || '/usr/share/freeradius';

SKIP: {
    # +1 test for no-warnings
    skip 'no FreeRADIUS dictionary found', 20 if (! -d $freeradius_path);

    ok($auth->load_dictionary(File::Spec->catdir($freeradius_path, 'dictionary.rfc2865'), format => 'freeradius'), 'rfc2865 dictionary');
    ok($auth->load_dictionary(File::Spec->catdir($freeradius_path, 'dictionary.erx'), format => 'freeradius'), 'ERX (Juniper) vendor');
    ok($auth->load_dictionary(File::Spec->catdir($freeradius_path, 'dictionary.rfc2868'), format => 'freeradius'), 'rfc2868 dictionary');

    $auth->add_attributes(
        { Name => 'User-Name', Value => '1'},
        { Name => 'ERX-Service-Activate:1', Value => 'INTERNET-SERVICE(64000)' },
        { Name => 'Tunnel-Type:5', Value => 'PPTP'},
        # when integer values are tagged, the value portion is reduced to three bytes
        { Name => 'ERX-Service-Statistics', Value => 'time-volume', Tag => 2 },
    );

    my $data = $auth->{attributes};

#           00 01 02 03 04 05 06 07 - 08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF
#------------------------------------------------------------------------------
# 00000000  01 03 31 1A 20 00 00 13 - 0A 41 1A 01 49 4E 54 45  ..1. ....A..INTE
# 00000010  52 4E 45 54 2D 53 45 52 - 56 49 43 45 28 36 34 30  RNET-SERVICE(640
# 00000020  30 30 29 40 06 05 00 00 - 01 1A 0C 00 00 13 0A 45  00)@...........E
# 00000030  06 02 00 00 02                                     .....


    my $expected = '';
    # User-Name
    $expected .= "\x01\x03\x31";
    # ERX-Service-Activate
    $expected .= "\x1A\x20\x00\x00\x13\x0A\x41\x1A\x01\x49\x4E\x54\x45";
    $expected .= "\x52\x4E\x45\x54\x2D\x53\x45\x52\x56\x49\x43\x45\x28\x36\x34\x30";
    $expected .= "\x30\x30\x29";
    # Tunnel-Type
    $expected .= "\x40\x06\x05\x00\x00\x01";
    # ERX-Service-Statistics
    $expected .= "\x1A\x0C\x00\x00\x13\x0A\x45\x06\x02\x00\x00\x02";


    # 01 User-Name len=03 value: 31 (1)
    # 1A Vendor-specific len=0x20 (32)
    #    00 00 13 0A (Vendor ERX)
    #    41 (ERX-Service-Activate) len 1A tag 1 value 49 4E 54 45 52 4E 45 54 2D 53 45 52 56 49 43 45 28 36 34 30 30 30 29
    # 40 Tunnel-Type len=06 (64) tag: 05 value: 00 00 01
    # 1A Vendor-Specific len=0c (12)
    #    00 00 13 0A (Vendor ERX)
    #    45 (ERX-Service-Statistics) len 06 tag 2 value 00 00 02 (time-volume)

    is($data, $expected, "encoded attributes with tags");

    # here we parse $self->{attributes} - without a real request
    my @p = $auth->get_attributes();
    is(@p, 4, 'parsed 3 attributes');

    is($p[0]->{Name}, 'User-Name');
    ok(! $p[0]->{Tag}, 'No tag for User-Name');

    is($p[1]->{Vendor}, 'ERX');
    is($p[1]->{Name}, 'ERX-Service-Activate:1');
    is($p[1]->{AttrName}, 'ERX-Service-Activate');
    is($p[1]->{Tag}, 1);

    is($p[2]->{Vendor}, 'not defined', 'No vendor');
    is($p[2]->{Name}, 'Tunnel-Type:5', 'Tunnel-Type:5 tagged attr');
    is($p[2]->{AttrName}, 'Tunnel-Type', 'Tunnel-Type attr');
    is($p[2]->{Tag}, 5, 'tag value');
    is($p[2]->{Value}, 'PPTP', 'Tunnel-Type value');

    is($p[3]->{Vendor}, 'ERX');
    is($p[3]->{Name}, 'ERX-Service-Statistics:2');
    is($p[3]->{AttrName}, 'ERX-Service-Statistics');
    is($p[3]->{Tag}, 2);
};

