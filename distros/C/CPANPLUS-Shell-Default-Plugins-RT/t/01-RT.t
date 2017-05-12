BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
}

use strict;
use Test::More 'no_plan';

my $Class   = 'CPANPLUS::Shell::Default::Plugins::RT';
my $List    = 'plugins';

use_ok( $Class );
can_ok( $Class, $List );

### check methods existence
{   my %map = $Class->$List;
    isa_ok( \%map, 'HASH' );
    
    for my $meth ( values %map ) {
        can_ok( $Class, $meth );
        can_ok( $Class, $meth . '_help' );
    }
}    

