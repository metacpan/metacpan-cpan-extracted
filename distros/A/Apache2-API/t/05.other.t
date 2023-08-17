#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::Mock::Apache2;
    no strict 'subs';
    use Test::MockObject;
    use Test2::V0;
};

BEGIN
{
    use ok( 'Apache2::API' ) || bail_out( 'Unable to load Apache2::API' );
};

# instantiate an Apache2::API object from command line, which use mock object
my $api = Apache2::API->new;
# expect an empty hash reference
my $accept = $api->request->accept;
is( $accept => undef, 'accept' );

done_testing();

__END__

