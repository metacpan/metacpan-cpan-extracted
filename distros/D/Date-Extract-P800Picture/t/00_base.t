use Test::More;
use DateTime;

BEGIN {
    @methods = qw(extract filename);
    plan tests => ( 7 + @methods );
    ok(1);    # If we made it this far, we're ok.
    use_ok('Date::Extract::P800Picture');
}
my $parser = new_ok('Date::Extract::P800Picture');

@Date::Extract::P800Picture::Sub::ISA = qw(Date::Extract::P800Picture);
my $parser_sub = new_ok('Date::Extract::P800Picture::Sub');

foreach my $method (@methods) {
    can_ok( 'Date::Extract::P800Picture', $method );
}
my $datetime  = $parser->extract("8B421234.JPG");
my $datetime2 = DateTime->new(
    year      => 2008,
    month     => 12,
    day       => 5,
    hour      => 2,
    time_zone => 'UTC',
);
is( ref $datetime, ref $datetime2, 'extract method returns DateTime object' );

SKIP: {
    skip 'is_deeply() has bogus fail on 5.6.2', 1 unless $^V gt v5.6.2;
    is_deeply( $datetime, $datetime2,
        'extract method returns DateTime object with correct values' );
}

$parser = Date::Extract::P800Picture->new();
is( eval '$parser->extract()', undef, "unset filename error catch" );
