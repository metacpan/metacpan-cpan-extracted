package APISchema::JSON;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(encode_json_canonical);

use JSON::XS;

my $json = JSON::XS->new->utf8->canonical(1);

sub encode_json_canonical {
    my ($value) = @_;
    $json->encode($value);
}

1;
