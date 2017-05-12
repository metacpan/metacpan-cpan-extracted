use strict;
use warnings;
use Test::More;
use Test::Warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Catalyst::Test 'TestApp';
use Test::Fatal;

# action adds an error, catch_errors  handles it
{
    my $res = request('/');
    is( $res->content, "Error:\ 'error'", 'error has been handled by catch_errors().' );
    is( $res->code, 200, 'status 200' );
}

SKIP: {
    skip('Special handling of HTTP::Exception errors not available if Catalyst < 5.90062', 2)
        if $Catalyst::Runtime::VERSION < 5.90062;

    # action throws HTTP::Exception, should not reach catch_errors
    my $res = request('/http_exception/');
    is( $res->code, 400, 'we do not break HTTP::Exception. (code)' );
    is( $res->content, "http_exception foobar", 'we do not break HTTP::Exception. (status_message)' );
}

# action adds 2 errors, catch_error rethrows them
{
    no warnings 'redefine';
    local *Catalyst::finalize_error = sub {
        my $c = shift;
        my @errors = @{ $c->error };
        is( scalar @errors, 2, 'there should be two error in $c->error' );
        is( $errors[0], "Rethrowing\ 'rethrow_error_1'", '1st error has been rethrown.' );
        is( $errors[1], "Rethrowing\ 'rethrow_error_2'", '2nd error has been rethrown.' );
    };
    my $res = request('/rethrow/');
}

# block with controller without catch_errors method fails
eval {
    package FailController;
    use Moose;
    BEGIN { extends 'Catalyst::Controller' }
    with 'Catalyst::ControllerRole::CatchErrors';
    sub end : Private { }
    no Moose;
    1;
};
like(
    $@,
    qr/Catalyst::ControllerRole::CatchErrors'\ requires\ the\ method\ 'catch_errors'\ to\ be\ implemented\ by\ 'FailController'/xms,
    "found error msg (required method catch_errors not implemented).",
);

done_testing;
