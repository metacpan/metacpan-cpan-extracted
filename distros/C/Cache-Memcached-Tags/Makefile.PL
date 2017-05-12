use ExtUtils::MakeMaker;
WriteMakefile( 'NAME' => 'Cache::Memcached::Tags',
               'VERSION_FROM' => 'lib/Cache/Memcached/Tags.pm',
               'PREREQ_PM'              => {
                   'Cache::Memcached' => 0,
               },
               ($] >= 5.005 ?
                (ABSTRACT_FROM => 'lib/Cache/Memcached/Tags.pm',
                 AUTHOR     => 'Eugene Bragin <eugene.bragin+memd@gmail.com>') : ()),
               );

