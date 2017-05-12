use strictures;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::UUID::Concise' );
}

diag(
    "Testing Data::UUID::Concise $Data::UUID::Concise::VERSION, Perl $], $^X"
);
