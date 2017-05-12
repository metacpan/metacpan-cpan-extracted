use Test::More tests => 3;
use Acme::Lelek;

my $lek = Acme::Lelek->new;

is(
    $lek->encode("LOL"),
    "AH Le lEk Lek lek lEK LEK LeK leK lEK",
    "should encode"
);
is( $lek->decode("AH lEk Lek lek lEK LEK LeK leK lEK"), "LOL",
    "should decode" );
is( $lek->decode("lEk Lek lek lEK LEK LeK leK lEK"),
    "LOL", "should decode without AH (optional)" );
