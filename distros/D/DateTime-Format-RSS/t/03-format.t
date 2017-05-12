use strict;
use Test::More (tests => 3);

BEGIN
{
    use_ok("DateTime::Format::RSS");
}

{
    my $fmt = DateTime::Format::RSS->new;

    my $dt = DateTime->now();
    is( $fmt->format_datetime($dt), $dt->iso8601);
}

{
    my $fmt = DateTime::Format::RSS->new(version => '2.0');

    my $dt = DateTime->now();
    is( $fmt->format_datetime($dt), DateTime::Format::Mail->new->format_datetime($dt) );
}