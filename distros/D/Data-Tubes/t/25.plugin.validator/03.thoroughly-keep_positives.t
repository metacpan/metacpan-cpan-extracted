use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Test::Exception;
use Data::Dumper;

use Data::Tubes qw< pipeline summon >;

summon('Validator::thoroughly');
ok __PACKAGE__->can('thoroughly'), "summoned thoroughly";

{
   my $v = thoroughly(
      sub { $_[0]{foo} =~ /bar|baz/ },
      ['is-even'   => sub { ($_[0]{number} % 2 == 0) or die "odd\n" }],
      ['in-bounds' => sub { $_[0]{number} >= 10      or die "too low\n" }],
      {wrapper => 'try', keep_positives => 1},
   );

   validate_validator(
      $v,
      {structured => {foo => 'bar', number => 12}},
      [['validator-0', 1], ['is-even', 1], ['in-bounds', 1],],
      'all validators are fine, all outcomes kept'
   );
   validate_validator(
      $v,
      {structured => {foo => 'bar', number => 13}},
      [['validator-0', 1], ['is-even', 0, "odd\n"], ['in-bounds', 1],],
      'one validator throws, all outcomes kept'
   );
   validate_validator(
      $v,
      {structured => {foo => 'hey', number => 4}},
      [['validator-0', 0], ['is-even', 1], ['in-bounds', 0, "too low\n"],],
      'two validators have issues, all outcomes kept'
   );
}

sub validate_validator {
   my ($validator, $record, $expected, $name) = @_;
   $expected = {%$record, validation => $expected}
     unless ref($expected) eq 'HASH';
   my $got;
   lives_ok { $got = $validator->($record) } "$name: call lives";
   is_deeply $got, $expected, "$name: outcome as expected"
     or diag Dumper $got;
} ## end sub validate_validator

done_testing();
