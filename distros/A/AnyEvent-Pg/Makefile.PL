use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my %prereq_pm = ( 'Pg::PQ'   => '0.14',
                  'AnyEvent' => '5.34',
                  'Method::WeakCallback' => '0.01' );

$prereq_pm{'Test::PostgreSQL'} = '1.05' if $ENV{AUTOMATED_TESTING};

WriteMakefile( NAME          => 'AnyEvent::Pg',
               VERSION_FROM  => 'lib/AnyEvent/Pg.pm',
               PREREQ_PM     => \%prereq_pm,
               ABSTRACT_FROM => 'lib/AnyEvent/Pg.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>'
             );
