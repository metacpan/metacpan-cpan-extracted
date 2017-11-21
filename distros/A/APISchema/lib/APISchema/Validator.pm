package APISchema::Validator;
use strict;
use warnings;
use 5.014;

# cpan
use Class::Load qw(load_class);
use Class::Accessor::Lite::Lazy (
    ro => [qw(fetch_resource_method)],
    ro_lazy => [qw(validator_class)],
);

# lib
use APISchema::Resource;
use APISchema::Validator::Decoder;
use APISchema::Validator::Result;

use constant +{
    DEFAULT_VALIDATOR_CLASS => 'Valiemon',
    TARGETS => [qw(header parameter body)],
    DEFAULT_ENCODING_SPEC => {
        'application/json'                  => 'json',
        'application/x-www-form-urlencoded' => 'url_parameter',
        # TODO yaml, xml
    },
};

sub _build_validator_class {
    return DEFAULT_VALIDATOR_CLASS;
}

sub _new {
    my $class = shift;
    return bless { @_ == 1 && ref($_[0]) eq 'HASH' ? %{$_[0]} : @_ }, $class;
}

sub for_request {
    my $class = shift;
    return $class->_new(@_, fetch_resource_method => 'canonical_request_resource');
}

sub for_response {
    my $class = shift;
    return $class->_new(@_, fetch_resource_method => 'canonical_response_resource');
}

sub _valid_result { APISchema::Validator::Result->new_valid(@_) }
sub _error_result { APISchema::Validator::Result->new_error(@_) }

sub _resolve_encoding {
    my ($content_type, $encoding_spec) = @_;
    # TODO handle charset?
    $content_type = $content_type =~ s/\s*;.*$//r;
    $encoding_spec //= DEFAULT_ENCODING_SPEC;

    if (ref $encoding_spec) {
        $encoding_spec = $encoding_spec->{$content_type};
        return ( undef, { message => "Wrong content-type: $content_type" } )
            unless $encoding_spec;
    }

    my $method = $encoding_spec;
    return ( undef, {
        message      => "Unknown decoding method: $method",
        content_type => $content_type,
    } )
        unless APISchema::Validator::Decoder->new->can($method);

    return ($method, undef);
}

sub _validate {
    my ($validator_class, $decode, $target, $spec) = @_;

    my $obj = eval { APISchema::Validator::Decoder->new->$decode($target) };
    return { message => "Failed to parse $decode" } if $@;

    my $validator = $validator_class->new($spec->definition);
    my ($valid, $err) = $validator->validate($obj);

    return {
        attribute => $err->attribute,
        position  => $err->position,
        expected  => $err->expected,
        actual    => $err->actual,
        message   => "Contents do not match resource '@{[$spec->title]}'",
    } unless $valid;

    return; # avoid returning the last conditional value
}

sub validate {
    my ($self, $route_name, $target, $schema) = @_;

    my @target_keys = @{+TARGETS};
    my $valid = _valid_result(@target_keys);

    my $route = $schema->get_route_by_name($route_name)
        or return $valid;
    my $method = $self->fetch_resource_method;
    my $resource_root = $schema->get_resource_root;
    my $resource_spec = $route->$method(
        $resource_root,
        $target->{status_code} ? [ $target->{status_code} ] : [],
        [ @target_keys ],
    );
    @target_keys = grep { $resource_spec->{$_} } @target_keys;

    my $body_encoding = $resource_spec->{body} && do {
        my ($enc, $err) = _resolve_encoding(
            $target->{content_type} // '',
            $resource_spec->{encoding},
        );
        if ($err) {
            return _error_result(body => $err);
        }
        $enc;
    };

    my $encoding = {
        body      => $body_encoding,
        parameter => 'url_parameter',
        header    => 'perl',
    };

    my $validator_class = $self->validator_class;
    load_class $validator_class;
    my $result = APISchema::Validator::Result->new;
    $result->merge($_) for map {
        my $field = $_;
        my $err = _validate($validator_class, map { $_->{$field} } (
            $encoding, $target, $resource_spec,
        ));
        $err ? _error_result($field => {
            %$err,
            encoding => $encoding->{$_},
        }) : _valid_result($field);
    } @target_keys;

    return $result;
}

1;
__END__
