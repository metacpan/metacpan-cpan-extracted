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
      ['is-even'   => sub { $_[0]{number} % 2 == 0 }],
      ['in-bounds' => sub { $_[0]{number} >= 10 && $_[0]{number} <= 21 }],
      {keep_empty => 1}
   );

   validate_validator($v, {structured => {foo => 'bar', number => 12}},
      [], 'all validators are fine');
}

{
   my $v = thoroughly(
      sub { $_[0]{foo} =~ /bar|baz/ },
      ['is-even'   => sub { ($_[0]{number} % 2 == 0) or die "odd\n" }],
      ['in-bounds' => sub { $_[0]{number} >= 10      or die "too low\n" }],
      {keep_empty => 1, wrapper => 'try'}
   );

   validate_validator(
      $v, {structured => {foo => 'bar', number => 12}},
      [], 'all validators are fine, even throwers'
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
