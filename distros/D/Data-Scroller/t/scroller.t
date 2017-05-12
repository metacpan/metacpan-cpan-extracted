#!perl
# vim:syn=perl

=head1 NAME

t/scroller.t

=head1 DESCRIPTION

Test General Scroller functionality.

=head1 AUTHOR

<benhare@gmail.com>

=cut
use strict;
use warnings;
use Test::More tests  => 33;
use lib qw( ./lib );

use_ok( 'Data::Scroller' );

my $max_value = 50; # total table rows of data to be displayed over all pages.
my $selected = 9; # current page requested, default 0 = page 1.
my $increment = 10; # number of results to show per page.

ok( my $scroller = Data::Scroller->new(
      max_value => $max_value,
      selected  => $selected,
      increment => $increment
    ), "new Scroller"
);
isa_ok( $scroller, 'Data::Scroller' );

ok( defined($scroller->PAGING_NAME), "can export default paging name if desired" );
ok( defined($scroller->PAGING_INCREMENT), "can export default paging increment if desired" );

diag( "test default parameters set correctly" );
ok( $scroller->PAGING_NAME eq 'row_num', "default paging name OK" );
ok( $scroller->PAGING_INCREMENT == 10, "default paging increment OK" );

diag( "test in put arguments set correctly" );
ok( $scroller->max_value == $max_value, "max_value OK" );
ok( $scroller->selected == $selected, "selected OK" );
ok( $scroller->increment == $increment, "increment OK" );

diag( "test internal values and defaults initialized correctly" );
ok( $scroller->max_display == $scroller->_round($max_value / $increment), "max_display OK" );
ok( $scroller->page_increment == $increment, "page_increment OK" );
ok( $scroller->name eq $scroller->PAGING_NAME, "paging name OK" );
ok( $scroller->{initialized}, "Pager initialized" );

diag( "test template parameters exist" );
ok( $scroller->PARAM_PAGE_LIST eq "page_list", "page_list OK" );
ok( $scroller->PARAM_PAGE_NEXT eq "page_next", "page_next OK" );
ok( $scroller->PARAM_PAGE_PREV eq "page_prev", "page_prev OK" );
ok( $scroller->PARAM_PAGE_FIRST eq "page_first", "page_first OK" );
ok( $scroller->PARAM_PAGE_LAST eq "page_last", "page_last OK" );
ok( $scroller->PARAM_PAGE_NAME eq "page_name", "page_name OK" );
ok( $scroller->PARAM_PAGE_TOTAL eq "page_total", "page_total OK" );
ok( $scroller->PARAM_PAGE_INCREMENT eq "page_increment", "page_increment OK" );

diag( "test returned template parameters hash ref" );
ok( my $params = $scroller->display(), "got tmpl params via display()" );
ok( ref($params) eq 'HASH', "tmpl params returned is a hash ref" ) ||
  diag( "tmpl params is a ".ref($params) );
ok( keys(%{$params}) == 8, "correct number of params returned (8)" );

diag( "test 4 mandatory template parameters are set" );
ok( defined($params->{$scroller->PARAM_PAGE_LIST}) && ref($params->{$scroller->PARAM_PAGE_LIST}) eq 'ARRAY',
  "param page_list returned OK" );
ok( defined($params->{$scroller->PARAM_PAGE_NAME}) && $params->{$scroller->PARAM_PAGE_NAME} eq $scroller->PAGING_NAME,
  "param page_name returned OK" );
ok( defined($params->{$scroller->PARAM_PAGE_TOTAL}) && $params->{$scroller->PARAM_PAGE_TOTAL} == $scroller->{max_display},
  "param page_total returned OK" );
ok( defined($params->{$scroller->PARAM_PAGE_INCREMENT}) && $params->{$scroller->PARAM_PAGE_INCREMENT} == $increment,
  "param page_increment returned OK" );

diag( "test 4 conditional variable template parameters are set" );
ok( exists($params->{$scroller->PARAM_PAGE_LAST}), "page_last may / may not be set, dependent on case" );
ok( exists($params->{$scroller->PARAM_PAGE_NEXT}), "page_next may / may not be set, dependent on case" );
ok( exists($params->{$scroller->PARAM_PAGE_FIRST}), "page_first may / may not be set, dependent on case" );
ok( exists($params->{$scroller->PARAM_PAGE_PREV}), "page_prev may / may not be set, dependent on case" );

__END__

