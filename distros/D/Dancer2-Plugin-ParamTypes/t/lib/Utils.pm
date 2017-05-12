use strict;
use warnings;

sub successful_test {
    my ( $test, $request, $source ) = @_;
    my $response = $test->request($request);
    ok( $response->is_success, "$source succeeded" );
    is( $response->content, $source, "$source matched and run" );
}

sub missing_test {
    my ( $test, $request, $source, $param ) = @_;
    my $response = $test->request($request);
    ok( !$response->is_success, "$source failed with missing parameter" );
    like(
        $response->content,
        qr{\QMissing parameter: $param\E},
        "Correct error message for $source"
    );
}

sub failing_test {
    my ( $test, $request, $source, $param, $type ) = @_;
    my $response = $test->request($request);
    ok( !$response->is_success, "$source failed with bad parameter value" );
    like(
        $response->content,
        qr{\QParameter $param must be $type\E},
        "Correct error message for $source"
    );
}

1;
