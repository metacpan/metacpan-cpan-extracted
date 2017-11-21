package APISchema::Validator::Decoder;
use strict;
use warnings;

# cpan
use JSON::XS qw(decode_json);
use URL::Encode qw(url_params_mixed);
use Class::Accessor::Lite ( new => 1 );

sub perl {
    my ($self, $body) = @_;
    return $body;
}

my $JSON = JSON::XS->new->utf8;
sub json {
    my ($self, $body) = @_;
    return $JSON->decode($body);
}

sub url_parameter {
    my ($self, $body) = @_;
    return undef unless defined $body;
    return url_params_mixed($body, 1);
}

1;
