
use strict;
use warnings;
use 5.010;

use ExtUtils::MakeMaker;

WriteMakefile(NAME          => 'AnyEvent::FileLock',
              VERSION_FROM  => 'lib/AnyEvent/FileLock.pm',
              PREREQ_PM     => { 'AnyEvent' => '7.04',
                                 'Method::WeakCallback' => '0.03' },
              ABSTRACT_FROM => 'lib/AnyEvent/FileLock.pm',
              AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
             );
