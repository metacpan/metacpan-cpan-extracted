use inc::Module::Install;
name 'AnyEvent-Pcap';
all_from 'lib/AnyEvent/Pcap.pm';

requires 'AnyEvent';
requires 'Net::Pcap';
requires 'NetPacket::TCP';
requires 'NetPacket::IP';
requires 'NetPacket::Ethernet';
requires 'Class::Accessor::Fast';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
