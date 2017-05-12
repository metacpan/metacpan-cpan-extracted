#!perl -T

use Test::More tests => 8;

BEGIN {
    use_ok( 'Apache2::Pod' );
    use_ok( 'Apache2::Pod::HTML' );
    use_ok( 'Apache2::Pod::Text' );
    use_ok( 'Apache2::Pod::PodSimpleHTML' );
}

APACHE_POD_HTML: {
    can_ok( 'Apache2::Pod::HTML', 'handler' );
}

APACHE_POD_TEXT: {
    can_ok( 'Apache2::Pod::Text', 'handler' );
}

APACHE2_POD_PODSIMPLEHTML: {
    my $psh = Apache2::Pod::PodSimpleHTML->new;
    isa_ok( $psh, 'Apache2::Pod::PodSimpleHTML' );
    isa_ok( $psh, 'Pod::Simple::HTML' );
}
