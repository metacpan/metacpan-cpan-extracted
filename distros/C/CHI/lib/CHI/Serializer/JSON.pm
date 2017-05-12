# Default key serializer class, so that we don't have to depend on Data::Serializer.
# Recommend Data::Serializer for other serializers, rather than reinventing the wheel.
#
package CHI::Serializer::JSON;
$CHI::Serializer::JSON::VERSION = '0.60';
use CHI::Util qw(json_encode json_decode);
use Moo;
use strict;
use warnings;

sub serialize {
    return json_encode( $_[1] );
}

sub deserialize {
    return json_decode( $_[1] );
}

1;
