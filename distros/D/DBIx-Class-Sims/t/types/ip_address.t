# vi:sw=2
use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok 'DBIx::Class::Sims::Types';

my $sub = DBIx::Class::Sims::Types->can('ip_address');

my $info = {
  data_type => 'varchar',
  sim => { type => 'ip_address' },
};
my $expected = qr/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
for ( 1 .. 1000 ) {
  my $val = $sub->($info);
  if ( like( $sub->($info), $expected ) ) {
    my @parts = split '\.', $val;
    foreach my $part ( @parts ) {
      cmp_ok( $part, '>=', 1 );
      cmp_ok( $part, '<=', 255 );
    }
  }
}

done_testing;
