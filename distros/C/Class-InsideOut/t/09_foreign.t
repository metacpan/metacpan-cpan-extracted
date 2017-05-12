use strict;
use lib ".";
use Test::More;
use File::Spec;
use Class::InsideOut ();

$|++; # keep stdout and stderr in order on Win32

eval { require IO::File };
if ( $@ ) {
    plan skip_all => "IO::File not installed";
}

eval { require File::Spec };
if ( $@ ) {
    plan skip_all => "File::Spec not installed";
}

plan tests => 5; 

#--------------------------------------------------------------------------#

my $class = "t::Object::Foreign";
my $filename = File::Spec->catfile( qw( t data testdata.txt ) ); 
my $o;

#--------------------------------------------------------------------------#

require_ok( $class );

ok( ($o = $class->new( $filename )) && $o->isa($class),
    "Creating a $class object"
);

ok( $o->isa( "IO::File" ),
    "Object isa IO::File"
);

my $line = <$o>;
chomp $line;
is( $line, "one",
    "Read a line from the $class object"
);

$o->name( "Larry" );
is( $o->name(), "Larry",
    "Setting a name for the object"
);

