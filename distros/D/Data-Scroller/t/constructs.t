#!perl
# vim:syn=perl

=head1 NAME

t/constructs.t

=head1 DESCRIPTION

Scroller constructor pass / fail tests.

=head1 AUTHOR

<benhare@gmail.com>

=cut
use strict;
use warnings;
use Test::More tests  => 5;
use Test::Exception;
use lib qw( ./lib );

use_ok( 'Data::Scroller' );

my $max_value = 50; # total table rows of data to be displayed over all pages.
my $selected = 9; # current page requested, default 0 = page 1.
my $increment = 10; # number of results to show per page.
my $scroller;

# no options
dies_ok { $scroller = Data::Scroller->new() } "new Scroller failed ( died ) - max_value argument is required";

# minimum options
ok( $scroller = Data::Scroller->new( max_value => $max_value ), "new Pager with single required param max_value (50) OK" ); 
isa_ok( $scroller, 'Data::Scroller' );

# required option present but with illegal value
dies_ok {
  $scroller = Data::Scroller->new(
    max_value => undef,
    selected  => $selected,
    increment => $increment
  );
} "new Scroller with required param max_value present but set to illegal value failed ( died )";

__END__


