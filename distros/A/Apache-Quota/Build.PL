use strict;

use Module::Build;

my $has_locker;
foreach my $c ( qw ( BerkeleyDB DB_File::Lock ) )
{
    eval "require $c";

    $has_locker = 1 unless $@;
}

unless ($has_locker)
{
    print "\n*** This module will not work without either BerkeleyDB or DB_File::Lock installed. ***\n\n";
}

Module::Build->new
    ( module_name => 'Apache::Quota',
      license     => 'perl',
      recommends  => { 'BerkeleyDB'    => 0,
                       'DB_File::Lock' => 0,
                     },
      sign        => 1,
      create_makefile_pl => 'passthrough',
    )->create_build_script;
