#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use DateTime;
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Changes::Release' );
};

use strict;
use warnings;

my $r = Changes::Release->new(
    datetime => '2022-11-17T08:12:42+0900',
    datetime_formatter => sub
    {
        my $dt = shift( @_ ) || DateTime->now;
        require DateTime::Format::Strptime;
        my $fmt = DateTime::Format::Strptime->new(
            pattern => '%FT%T%z',
            locale => 'en_GB',
        );
        $dt->set_formatter( $fmt );
        $dt->set_time_zone( 'Asia/Tokyo' );
        return( $dt );
    },
    format => '%FT%T%z',
    note => 'Initial release',
    spacer => "\t",
    time_zone => 'Asia/Tokyo',
    version => 'v0.1.0',
    debug => $DEBUG,
);
isa_ok( $r, 'Changes::Release' );

# To generate this list:
# egrep -E '^sub ' ./lib/Changes/Release.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$r, ''$m'' );"'
can_ok( $r, 'as_string' );
can_ok( $r, 'changes' );
can_ok( $r, 'container' );
can_ok( $r, 'datetime' );
can_ok( $r, 'datetime_formatter' );
can_ok( $r, 'elements' );
can_ok( $r, 'format' );
can_ok( $r, 'freeze' );
can_ok( $r, 'groups' );
can_ok( $r, 'line' );
can_ok( $r, 'nl' );
can_ok( $r, 'note' );
can_ok( $r, 'raw' );
can_ok( $r, 'spacer' );
can_ok( $r, 'time_zone' );
can_ok( $r, 'version' );

is( $r->as_string, "v0.1.0\t2022-11-17T08:12:42+0900 Initial release\n", 'as_string' );
isa_ok( $r->changes, 'Module::Generic::Array' );
is( $r->changes->length, 0, 'changes size' );
isa_ok( $r->datetime, 'DateTime', 'datetime returns a DateTime object' );
is( $r->datetime, '2022-11-17T08:12:42+0900', 'datetime' );
is( ref( $r->datetime_formatter ), 'CODE', 'datetime_formatter' );
is( $r->format, '%FT%T%z', 'format' );
is( $r->note, 'Initial release', 'note' );
is( $r->raw, undef, 'raw' );
is( $r->spacer, "\t", 'spacer' );
isa_ok( $r->time_zone, 'DateTime::TimeZone', 'time_zone returns a DateTime::TimeZone object' );
is( $r->time_zone->name, 'Asia/Tokyo', 'time_zone' );
isa_ok( $r->version, 'Changes::Version', 'version returns a Changes::Version object' );
my $v = $r->version;
is( "$v", 'v0.1.0', 'version' );

done_testing();

__END__

