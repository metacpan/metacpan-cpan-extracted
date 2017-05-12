use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;
use Scalar::Util qw< refaddr >;

use Data::Tubes qw< summon >;

summon('Validator::refuse');
ok __PACKAGE__->can('refuse'), "summoned refuse";

my $same_as_input = [];
for my $tspec (
   [
      [qr{whatever},], {raw => 'whatever you do'},
      undef, 'simple positive test',
   ],
   [
      [qr{whateeeeevah},], {raw => 'whatever you do'},
      $same_as_input, 'simple negative test',
   ],
   [
      [qr{whateeeevah}, sub { 0 }, qr{you\s*do}],
      {raw => 'whatever you do'},
      undef,
      'positive tests, mixing regexes and subs',
   ],
   [
      [qr{whateeeevah}, sub { 0 }, qr{you\s*do\s*it}],
      {raw => 'whatever you do'},
      $same_as_input, 'double check on last',
   ],
   [
      [qr{whatever}, {input => undef}],
      'whatever you do',
      undef,
      'positive test, record is input',
   ],
   [
      [qr{whateeeeevah}, {input => undef}],
      'whatever you do',
      $same_as_input,
      'negative test, record is input',
   ],
  )
{
   my ($inputs, $irec, $expected, $name) = @$tspec;
   $expected = $irec
     if ref($expected) && refaddr($expected) == refaddr($same_as_input);
   my $got = refuse(@$inputs)->($irec);
   is_deeply $got, $expected, $name;
} ## end for my $tspec ([[qr{whatever}...]])

done_testing();
