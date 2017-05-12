# vi:sw=2
use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok 'DBIx::Class::Sims::Types';

my $sub = DBIx::Class::Sims::Types->can('email_address');

my @tests = (
  # Default is 7
  [ { data_type => 'varchar' }, qr/^[\w.+]+@[\w.]+$/ ],

  ( map {
    [ { data_type => 'varchar', size => $_ }, qr/^[\w.+]+@[\w.]+$/ ],
  } 7 .. 100 ),

  # Anything under 7 characters is too small - "a@b.com" is the smallest legal
  ( map {
    [ { data_type => 'varchar', size => $_ }, qr/^$/ ],
  } 1 .. 6),
);

foreach my $test ( @tests ) {
  $test->[0]{sim} = { type => 'email_address' };
  like( $sub->($test->[0]), $test->[1] );
}

done_testing;
