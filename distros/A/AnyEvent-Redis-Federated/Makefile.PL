use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::Redis::Federated',
    VERSION_FROM      => 'lib/AnyEvent/Redis/Federated.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::TCP'           => 0,
        'Test::More'          => 0,
#        'Test::RedisServer'   => '0.09',
        'AnyEvent::Redis'     => 0,
		'Set::ConsistentHash' => 0,
		'Memory::Usage'       => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/Redis/Federated.pm', # retrieve abstract from module
       AUTHOR         => 'jzawodn <jzawodn@craigslist.org>') : ()),
);
