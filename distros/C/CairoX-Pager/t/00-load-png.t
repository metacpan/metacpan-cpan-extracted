#!perl
use lib 'lib';
use Test::More tests => 10;

BEGIN {
	use_ok( 'CairoX::Pager' );
}

diag( "Testing CairoX::Pager $CairoX::Pager::VERSION, Perl $], $^X" );

my $pager = CairoX::Pager->new(
    png => { 
        directory => 'test',
        filename_format => "%04d.png",
        dpi => 600,
    },
    page_spec => { width => 300 , height => 300 },
);

ok( $pager );

for ( 1 .. 3 ) {
    $pager->new_page( );

    my $surface = $pager->surface();   # get cairo surface 
    my $cr = $pager->context();    # get cairo context

    ok( $cr );
    ok( $surface );

    $pager->finish_page( );
}

$pager->finish();
ok( ! $pager->surface() );
ok( ! $pager->context() );
