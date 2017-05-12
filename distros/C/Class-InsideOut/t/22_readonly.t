use strict;
use lib ".";
use Test::More;

# keep stdout and stderr in order on Win32

select STDERR; $|++;
select STDOUT; $|++;

#--------------------------------------------------------------------------#

my $class = "t::Object::ReadOnly";
my $properties = {
    $class => {
        name => "public",
        age => "public",
    },
};

    
my ($o, @got, $got);

#--------------------------------------------------------------------------#

plan tests => 6;

require_ok( $class );

is_deeply( Class::InsideOut::_properties( $class ), 
           $properties,
    "$class has/inherited its expected properties"
);

ok( ($o = $class->new( name => "Larry" )) && $o->isa($class),
    "Creating a $class object"
);

#--------------------------------------------------------------------------#

is( $o->name, "Larry",
    "initialized readonly accessor readable and correct"
);

is( $o->age, undef,
    "uninitialized readonly accessor returns undef"
);

eval { $o->age(23) };
my $err = $@;
like( $err, '/age\(\) is read-only/i',
    "readonly accessor dies if given an argument"
);


