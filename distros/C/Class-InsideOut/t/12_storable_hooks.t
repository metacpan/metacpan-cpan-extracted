use strict;
use lib ".";
use Test::More;
use Class::InsideOut ();
use Scalar::Util qw( refaddr reftype );

$|++; # keep stdout and stderr in order on Win32

my $class    = "t::Object::Animal::Jackalope";
my $gp_class = "t::Object::Animal";

# Need Storable 2.04 ( relatively safe STORABLE_freeze support )
eval { require Storable and Storable->VERSION( 2.04 ) };
if ( $@ ) {
    plan skip_all => "Storable >= 2.04 not installed",
}
else
{
    plan tests => 10;
}

#--------------------------------------------------------------------------#
# tests
#--------------------------------------------------------------------------#

require_ok( $class );
my $o;
# create the object
ok( $o = $class->new(),  
    "... Creating $class object"
);

# note the underlying type
my $type;
ok( $type = reftype($o),
    "... Object is reftype $type"
);

# freeze object
my ( $frozen, $thawed );
ok( $frozen = Storable::freeze( $o ),
    "... Freezing object"
);

# check that hooks worked
{
    no strict 'refs';
    is( ${ $class . "::freezings"}, 1,
        "... $class freeze hook updated freeze count"
    );
    is( ${ $gp_class . "::freezings"}, 1,
        "... $gp_class freeze hook updated freeze count (diamond pattern)"
    );
}

# thaw object
ok( $thawed = Storable::thaw( $frozen ),
    "... Thawing object"
);
isnt( refaddr $o, refaddr $thawed,
    "... Thawed object is a copy"
);

# check that hooks worked
{
    no strict 'refs';
    is( ${ $class . "::thawings"}, 1,
        "... $class thaw hook updated thaw count"
    );
    is( ${ $gp_class . "::thawings"}, 1,
        "... $gp_class thaw hook updated thaw count (diamond pattern)"
    );
}


