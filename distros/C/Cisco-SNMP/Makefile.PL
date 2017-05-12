use 5.010001;
use ExtUtils::MakeMaker;

# Net::IPv6Addr required for ProxyPing.pm if IPv6 support (Socket >= 1.94)
use Socket;
my %addPREREQ_PM;
if ($Socket::VERSION >= 1.94) {
    $addPREREQ_PM{Net::IPv6Addr} = 0.2
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Cisco::SNMP',
    VERSION_FROM      => 'lib/Cisco/SNMP.pm', # finds $VERSION
    ($ExtUtils::MakeMaker::VERSION >= 6.3002) ? ('LICENSE'  => 'perl', ) : (),
    EXE_FILES         => ['bin/cisco-arp.pl',
                          'bin/cisco-config.pl',
                          'bin/cisco-cpu.pl',
                          'bin/cisco-entity.pl',
                          'bin/cisco-intf.pl',
                          'bin/cisco-line.pl',
                          'bin/cisco-memory.pl',
                          'bin/cisco-pass.pl',
                          'bin/cisco-ping.pl',
                          'bin/cisco-system.pl'],
    PREREQ_PM         => {Test::Simple => 0, 
                          Net::SNMP => 0,
                          Socket => 0,
                          Sys::Hostname => 0,
                          %addPREREQ_PM }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Cisco/SNMP.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Vincent <vin at vinsworld dot com>') : ()),
);
