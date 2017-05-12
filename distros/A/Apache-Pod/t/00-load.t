#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'Apache::Pod' );
    use_ok( 'Apache::Pod::HTML' );
}

APACHE_POD_HTML: {
    can_ok( 'Apache::Pod::HTML', 'handler' );
}

MY_POD_SIMPLE_HTML: {
    my $psh = My::Pod::Simple::HTML->new;
    isa_ok( $psh, 'My::Pod::Simple::HTML' );
    isa_ok( $psh, 'Pod::Simple::HTML' );
}
