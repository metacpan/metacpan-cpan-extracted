
use strict;

BEGIN {
    if ( open MEMCACHED, "memcached -i |" ) {
        chomp( my $header = <MEMCACHED> );
        print "Using $header for tests!\n";
    }

    else {
        print "No executable memcached found: $!\n";
        print "Many tests will fail, install can only be forced!\n";
    }
}

use ExtUtils::MakeMaker;
eval "use Devel::Required";
eval "use Devel::Required pod => [ qw(
  lib/Cache/Managed.pm
  lib/Cache/Managed/Inactive.pm
  lib/Cache/Managed/Multi.pm
) ]";

WriteMakefile (
 NAME          => "Cache::Memcached::Managed",
 AUTHOR        => 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT      => 'provide API for managing cached information',
 VERSION_FROM  => 'lib/Cache/Memcached/Managed.pm',
 LICENSE       => 'gpl',

 PREREQ_PM     => { qw(
                    Cache::Memcached    0
                  ) },
);
