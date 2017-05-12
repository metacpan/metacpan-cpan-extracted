use strict;
use lib ".";
use Config;

# keep stdout and stderr in order on Win32

BEGIN {
    $|=1; 
    my $oldfh = select(STDERR); $| = 1; select($oldfh);
}

# If running under threads, Test::More must load *after* threads.pm
# so load Test::More only if needed to bail out or only after loading
# threads.pm

BEGIN {
    # don't run without threads configured
    if ( ! $Config{useithreads} ) {
        require Test::More;
        Test::More::plan( skip_all => 
            "perl ithreads not available" );
    }
    
    # don't run for Perl prior to 5.8 (with CLONE) (even if
    # threads *are* configured)
    if( $] < 5.008005 ) {
        require Test::More;
        Test::More::plan( skip_all => 
            "thread support requires perl 5.8.5" );
    }

    # don't run without Scalar::Util::weaken()
    eval "use Scalar::Util 'weaken'";
    if( $@ =~ /\AWeak references are not implemented/ ) {
        require Test::More;
        Test::More::plan( skip_all =>
            "Scalar::Util::weaken() is required for thread-safety" );
    }

    # don't run this at all under Devel::Cover
    if ( $ENV{HARNESS_PERL_SWITCHES} &&
         $ENV{HARNESS_PERL_SWITCHES} =~ /Devel::Cover/ ) {
        require Test::More;
        Test::More::plan( skip_all => 
            "Devel::Cover not compatible with threads" );
    }
    
}

use threads;
use Test::More tests => 10;

#--------------------------------------------------------------------------#

my $class    = "t::Object::Animal";
my $subclass = "t::Object::Animal::Antelope";
my ($o, $p);

#--------------------------------------------------------------------------#

require_ok( $class );
require_ok( $subclass );

ok( ($o = $class->new()) && $o->isa($class),
    "Creating a $class object"
);

ok( ($p = $subclass->new()) && $p->isa($subclass),
    "Creating a $subclass object"
);


is( $o->name( "Larry" ), "Larry",
    "Setting a name for the superclass object in the parent"
);

is( $p->name( "Harry" ), "Harry",
    "Setting a name for the subclass object in the parent"
);

is( $p->color( "brown" ), "brown",
    "Setting a color for the subclass object in the parent"
);

my $thr = threads->new( 
    sub { 
        is( $o->name, "Larry", "got right superclass object name in thread");
        is( $p->name, "Harry", "got right subclass object name in thread"); 
        is( $p->color, "brown", "got right subclass object name in thread"); 
    } 
);

SKIP: {
    skip "Couldn't create a thread", 3
        unless defined $thr;
    $thr->join;
}


