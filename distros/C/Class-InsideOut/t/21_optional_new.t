use strict;
use lib ".";
use Test::More;

select STDERR; $|++;
select STDOUT; $|++;

#--------------------------------------------------------------------------#

my $class = "t::Object::WithNew::Inherited";
my %properties = (
    name => "Larry",
    age  => 42,
);

#--------------------------------------------------------------------------#

my @cases = (
    {
        label   => q{new()},
        args    => [],
    },
    {
        label   => q{new( %hash )},
        args    => [ %properties ],
    },
    {
        label   => q{new( \%hash )},
        args    => [\%properties ],
    },
);

my @error_cases = (
    {
        label   => q{new( qw/foo/ ) croaks},
        args    => [ qw/foo/ ],
        error   => q{must be a hash or hash reference},
    },
    {
        label   => q{new( qw/foo bar bam/ ) croaks},
        args    => [ qw/foo bar bam/ ],
        error   => q{must be a hash or hash reference},
    },
    {
        label   => q{new( [ qw/foo bar/ ] ) croaks},
        args    => [ [qw/foo bar/] ],
        error   => q{must be a hash or hash reference},
    },
);

plan tests => 2 + 2 + 5 * (@cases - 1) + @error_cases; 

#--------------------------------------------------------------------------#
# test initialization
#--------------------------------------------------------------------------#

require_ok( $class );

can_ok( $class, 'new' );

for my $case ( @cases ) {
    my $o;
    ok( $o = $class->new( @{$case->{args}} ),
        $case->{label}
    );
    isa_ok( $o, $class );
    next unless scalar @{ $case->{args} };
    is( $o->name(), "Larry",
        "name property initialized correctly"
    );
    is( $o->reveal_age, 42,
        "age property initialized correctly"
    );
    is( $o->t::Object::WithNew::reveal_age(), 42,
        "superclass age property initialized correctly"
    );
}

#--------------------------------------------------------------------------#
# error tests
#--------------------------------------------------------------------------#

for my $case ( @error_cases ) {
    eval { $class->new( @{ $case->{args} } ) };
    like( $@, "/$case->{error}/i", "$case->{label}");
}

