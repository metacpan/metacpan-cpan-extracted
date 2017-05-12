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
        label   => q{invalid options argument: array is not a hash},
        args    => q{ [ qw( foo bar ) ] },
        error   => q{invalid options argument},
    },
    {
        label   => q{invalid options argument: scalar is not a hash},
        args    => q{ 'foo' => 'bar' },
        error   => q{invalid options argument},
    },
    {
        label   => q{invalid options argument: unknown option},
        args    => q{ { privacy => 'public', not_an_option => 1} },
        error   => q{invalid option 'not_an_option'},
    },
    {
        label   => q{invalid options argument: bad 'privacy' option},
        args    => q{ { privacy => 'yes'} },
        error   => q{invalid option 'privacy'.+?yes},
    },
    {
        label   => q{invalid options argument: bad 'set_hook' option},
        args    => q{ { set_hook => 'foo' } },
        error   => q{invalid option 'set_hook'.+code},
    },
    {
        label   => q{invalid options argument: bad 'get_hook' option},
        args    => q{ { get_hook => 'foo' } },
        error   => q{invalid option 'get_hook'.+code},
    },
);

#--------------------------------------------------------------------------#
# Begin tests
#--------------------------------------------------------------------------#

plan tests => 1 + @cases;

require_ok( "Class::InsideOut" );

for my $case ( @cases ) {
    eval( "Class::InsideOut::options( " . $case->{args} . ")" );
    like( $@, "/$case->{error}/i", "$case->{label}");
}

