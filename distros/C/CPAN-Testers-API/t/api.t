
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::API> module, application startup,
plugins, and helpers.

Individual controllers have their own tests.

=cut

use CPAN::Testers::API::Base 'Test';
my $t = prepare_test_app();

subtest 'can get OpenAPI document' => sub {
    $t->get_ok( '/v1' )
        ->status_is( 200 )
        ->header_like( 'Content-Type' => qr{^application/json} );
    $t->get_ok( '/v3' )
        ->status_is( 200 )
        ->header_like( 'Content-Type' => qr{^application/json} );
};

done_testing;
