# -*- perl -*-
# t/00.load.t - check module loading and create testing directory
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test2::V0;
}

# To build the list of modules:
# find ./lib -type f -name "*.pm" -print | xargs perl -lE 'my @f=sort(@ARGV); for(@f) { s,./lib/,,; s,\.pm$,,; s,/,::,g; substr( $_, 0, 0, q{use ok( ''} ); $_ .= q{'' );}; say $_; }'
BEGIN
{
    use ok( 'Apache2::API' );
    use ok( 'Apache2::API::DateTime' );
    use ok( 'Apache2::API::Query' );
    use ok( 'Apache2::API::Request' );
    use ok( 'Apache2::API::Request::Params' );
    use ok( 'Apache2::API::Request::Upload' );
    use ok( 'Apache2::API::Response' );
    use ok( 'Apache2::API::Status' );
};

done_testing();

__END__

