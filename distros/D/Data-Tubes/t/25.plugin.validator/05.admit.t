use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;
use Scalar::Util qw< refaddr >;

use Data::Tubes qw< summon >;

summon('Validator::admit');
ok __PACKAGE__->can('admit'), "summoned admit";

my $same_as_input = [];
for my $tspec (
   [
      [qr{whatever},], {raw => 'whatever you do'},
      $same_as_input, 'simple positive test',
   ],
   [
      [qr{whateeeeevah},], {raw => 'whatever you do'},
      undef, 'simple negative test',
   ],
   [
      [qr{whatever}, {refuse => 1},],
      {raw => 'whatever you do'},
      undef,
      'simple inverted test',
   ],
   [
      [qr{whateeeeevah}, {refuse => 1},],
      {raw => 'whatever you do'},
      $same_as_input,
      'simple inverted negative test',
   ],
   [
      [qr{whatever}, sub { 1 }, qr{you\s*do}],
      {raw => 'whatever you do'},
      $same_as_input,
      'positive tests, mixing regexes and subs',
   ],
   [
      [qr{whatever}, sub { 0 }, qr{you\s*do}],
      {raw => 'whatever you do'},
      undef,
      'double check on last',
   ],
   [
      [qr{whatever}, {input => undef}],
      'whatever you do',
      $same_as_input,
      'positive test, record is input',
   ],
   [
      [qr{whateeeeevah}, {input => undef}],
      'whatever you do',
      undef,
      'negative test, record is input',
   ],
  )
{
   my ($inputs, $irec, $expected, $name) = @$tspec;
   $expected = $irec
     if ref($expected) && refaddr($expected) == refaddr($same_as_input);
   my $got = admit(@$inputs)->($irec);
   is_deeply $got, $expected, $name;
} ## end for my $tspec ([[qr{whatever}...]])

done_testing();

