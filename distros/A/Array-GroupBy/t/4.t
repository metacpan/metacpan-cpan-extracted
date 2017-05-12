#!perl -w

use strict;

use Test::More;

use Array::GroupBy qw(igroup_by str_row_equal);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}
  
plan tests => 8;

my $n1 = [ 1, 1, 1.0     ];
my $n2 = [ 4.5, 4.50     ];
my $n3 = [ 0.2, .2, .200 ];
my $n4 = [ 1, 1.000, 1.0 ];

my $data = [ @$n1, @$n2, @$n3, @$n4 ];

#
# call errors
#

throws_ok {
igroup_by( compare => sub { $_[0] == $_[1] });
          } qr/Mandatory parameter 'data' missing in call to/,
            '"data => ..." argument missing in igroup_by() call';

throws_ok {
igroup_by( data => $data );
          } qr/Mandatory parameter 'compare' missing in call to/,
            '"compare => ..." argument missing in igroup_by() call';

throws_ok {
igroup_by( xx_data    => $data, compare => sub { $_[0] == $_[1] });
          } qr/validation options: xx_data/,
            'name of argument wrong in igroup_by() call';

throws_ok {
igroup_by( data => $data, compare => 'axolotl' );
          } qr/The 'compare' parameter.*was a 'scalar'.*types: coderef/,
            'compare => not a coderef in igroup_by() call';

throws_ok {
igroup_by( data => $data, compare => sub {}, extra => 0 );
          } qr/The.*parameter.*not listed.*: extra/,
            'extra parameter in igroup_by() call';

throws_ok {
igroup_by( data => [], compare => sub {}, );
          } qr/The array passed to igroup_by.*is empty/,
            'empty array passed to igroup_by()';

throws_ok {
igroup_by( data => undef, compare => sub {}, );
          } qr/The 'data' parameter.*was an 'undef'/,
            "undef 'data' parameter";

throws_ok {
igroup_by( data => $data, compare => undef );
          } qr/The 'compare' parameter.*was an 'undef'/,
            "undef 'compare' parameter";
