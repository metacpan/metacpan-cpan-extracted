use Test::More;

use Cpanel::JSON::XS;
plan tests => 1;

use Data::AnyXfer::JSON ();

my $boolstring = q({"is_true":true});
my $xs_string;
{
    use JSON::XS ();
    my $json = Cpanel::JSON::XS->new;
    $xs_string = $json->decode($boolstring);
}
my $json = Data::AnyXfer::JSON->new;

is( $json->encode($xs_string), $boolstring );
