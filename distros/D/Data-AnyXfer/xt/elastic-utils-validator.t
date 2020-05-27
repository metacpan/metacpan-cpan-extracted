use Data::AnyXfer::Test::Kit;
use Geo::JSON::Polygon                               ();
use Data::AnyXfer::Elastic::Utils::Validator ();


# TEST DATA
BEGIN {
  require Data::AnyXfer;
  Data::AnyXfer->test(1);
}


# VALID POLYGON
my $valid_polygon = Geo::JSON::Polygon->new(
    {   coordinates => [
            [   [ -0.3596305847167969,  51.6218534384778 ],
                [ -0.35190582275390625, 51.61759020766987 ],
                [ -0.35362243652343744, 51.62334547464101 ],
                [ -0.3596305847167969,  51.6218534384778 ],
            ]
        ]
    }
);

# INVALID POLYGON
my $invalid_polygon = Geo::JSON::Polygon->new(
    {   coordinates => [
            [   [ -0.3862380981445312,  51.60127965381104 ],
                [ -0.3675270080566406,  51.608636119273314 ],
                [ -0.36083221435546875, 51.58880292298877 ],
                [ -0.3570556640625,     51.6070369890419 ],
                [ -0.3862380981445312,  51.60127965381104 ]
            ]
        ]
    }
);


# TESTS


my $validator = Data::AnyXfer::Elastic::Utils::Validator->new;
isa_ok $validator, 'Data::AnyXfer::Elastic::Utils::Validator';



{
    my $result = $validator->validate_geo_shape($valid_polygon);
    ok $result->{valid}, 'polygon is valid';
}


{
    my $result = $validator->validate_geo_shape($invalid_polygon);
    ok !$result->{valid}, 'polygon is invalid';

    my $error = $result->{explanations}->[0]->{error};

    like $error, qr/InvalidShapeException/,
        'polygon causes an elasticsearch invalid shape exception';

    like $error, qr/Self-intersection/,
        'polygon contains a self intersecting polygon';

}


done_testing;
