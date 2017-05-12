use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::DNS::Nameserver',
    VERSION_FROM      => 'lib/AnyEvent/DNS/Nameserver.pm', # finds $VERSION
    DISTNAME            => 'AnyEvent-DNS-Nameserver',
    LICENSE             => "perl",
    PREREQ_PM         => {
        "AnyEvent::Handle::UDP"  => 0,
        "Net::DNS"               => 0,
    }, # e.g., Module::Name => 1.1
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-DNS-Nameserver-*' },
    META_MERGE => {
        resources => {     
            repository=>{
                type    => 'git',
                url     => 'git://github.com/sjdy521/AnyEvent-DNS-Nameserver.git',
                web     =>  'https://github.com/sjdy521/AnyEvent-DNS-Nameserver',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       #ABSTRACT_FROM  => 'lib/Webqq/Client.pm', # retrieve abstract from module
       ABSTRACT       => 'AnyEvent::DNS::Nameserver - DNS server class using AnyEvent',
       AUTHOR         => 'sjdy521 <sjdy521@163.com>') : ()),
);
