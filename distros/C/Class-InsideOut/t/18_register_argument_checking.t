use strict;
use lib ".";
local $^W = 1;
use Test::More;

# keep stdout and stderr in order on Win32

BEGIN {
    $|=1; 
    my $oldfh = select(STDERR); $| = 1; select($oldfh);
}

#--------------------------------------------------------------------------#
# option() argument cases
#--------------------------------------------------------------------------#

my @cases = (
    {
        label   => q{invalid call to register: no argument},
        args    => q{},
        error   => q{empty argument list},
    },
    {
        label   => q{invalid register argument: reference with no class name},
        args    => q{ {} },
        error   => q{must be an object or class name},
    },
);

#--------------------------------------------------------------------------#
# Begin tests
#--------------------------------------------------------------------------#

plan tests => 1 + @cases;

require_ok( "Class::InsideOut" );

for my $case ( @cases ) {
    eval( "Class::InsideOut::register( " . $case->{args} . ")" );
    like( $@, "/$case->{error}/i", "$case->{label}");
}

