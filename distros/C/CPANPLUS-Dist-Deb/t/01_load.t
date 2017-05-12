BEGIN { chdir 't' if -d 't' }

### add ../lib to the path
BEGIN { use File::Spec;
        use lib 'inc';
        use lib File::Spec->catdir(qw[.. lib]);
}        

BEGIN { require 'conf.pl' }

use strict;

### load the appropriate modules
use_ok( $DIST );
use_ok( $CLASS );
use_ok( $CONST );


### check if all required modules are there
{   for my $method (qw[init format_available create install]) {
        can_ok( $CLASS, $method );
    }
}

### check if an object of this class has all required method ###
{   my $dist = $DIST->new( module => $FAKEMOD, format => $CLASS );
    ok( $dist,                      "Dist object created" );
    isa_ok( $dist,                  $CLASS );

    for my $acc (qw[created installed uninstalled dist]) {
        can_ok( $dist->status, $acc );
    }        
}    
