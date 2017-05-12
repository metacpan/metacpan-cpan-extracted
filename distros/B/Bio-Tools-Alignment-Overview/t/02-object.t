use strict;
use warnings;
use Bio::Tools::Alignment::Overview;
use Test::More tests => 3;                      # last test to print

ok( my $view = Bio::Tools::Alignment::Overview->new(), "instantiation" );

isa_ok( $view, 'Bio::Tools::Alignment::Overview' );

can_ok( $view, qw(input output color make_image) );


