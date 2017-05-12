#!perl -w
use strict;
use Test::More tests => 11;

my $class = 'Data::ICal::TimeZone';
require_ok( $class );
my $zone;

ok( !($zone = $class->new) );
is( $zone->error_message, "No timezone specified" );

ok( !grep { $_ eq 'Europe/London/Islington' } $class->zones, "Islington is not special" );
ok( !($zone = $class->new( timezone => 'Europe/London/Islington' )) );
is( $zone->error_message, "No such timezone 'Europe/London/Islington'" );

ok( grep { $_ eq 'Europe/London' } $class->zones, "Europe/London is listed" );
ok( $zone = $class->new( timezone => 'Europe/London' ) );
is( ref $zone, "$class\::Object::Europe::London" );
is( $zone->timezone, 'Europe/London' );

is( ref $zone->definition, 'Data::ICal::Entry::TimeZone' );


__END__
use Data::ICal;
my $cal = Data::ICal->new;
$cal->add_entry( $zone->definition );
diag( $cal->as_string );
