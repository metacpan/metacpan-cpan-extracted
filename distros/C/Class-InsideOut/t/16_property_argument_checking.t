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
# property() argument cases
#--------------------------------------------------------------------------#

my @property_cases = (
    {
        label   => q{invalid property name: bad symbols},
        args    => q{'test#data' => my %testdata},
        error   => q{invalid property name},
    },
    {
        label   => q{invalid property name: leading number},
        args    => q{'1testdata' => my %testdata},
        error   => q{invalid property name},
    },
    {
        label   => q{invalid property name: object},
        args    => q{[] => my %testdata},
        error   => q{invalid property name},
    },
    {
        label   => q{invalid property store: not a hashref},
        args    => q{testdata => my @testdata},
        error   => q{must be hash},
    },
    {
        label   => q{invalid property options: passed arrayref, not a hashref},
        args    => q{testdata => my %testdata, []},
        error   => q{must be a hash reference},
    },
    {
        label   => q{invalid property options: passed scalar, not a hashref},
        args    => q{testdata => my %testdata, 'foo'},
        error   => q{must be a hash reference},
    },
);

#--------------------------------------------------------------------------#
# Begin tests
#--------------------------------------------------------------------------#

plan tests => 2 + 3 * @property_cases;

require_ok( "Class::InsideOut" );

for my $fcn ( qw( property public private ) ) {
    for my $case ( @property_cases ) {
        eval( "Class::InsideOut::$fcn " . $case->{args});
        like( $@, "/$case->{error}/i", "$fcn: $case->{label}");
    }
}

#--------------------------------------------------------------------------#
# Special cases
#--------------------------------------------------------------------------#

# Duplicate names

eval << 'END_EVAL';
    Class::InsideOut::property twin => my %twin;
    Class::InsideOut::property twin => my %double;
END_EVAL

like( $@, "/duplicate property name/i", "Duplicate property name detected" );
    
