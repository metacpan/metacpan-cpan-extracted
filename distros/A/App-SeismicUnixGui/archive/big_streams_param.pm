package big_streams_param;
use Moose;

my $path;
my $SeismicUnixGui;
use Shell qw(echo);

BEGIN {

$SeismicUnixGui = ` echo \$SeismicUnixGui`;
chomp $SeismicUnixGui;
$path = $SeismicUnixGui.'/'.'misc';

}
use lib "$path";
extends 'su_param' => { -version => 0.0.2 };

1;