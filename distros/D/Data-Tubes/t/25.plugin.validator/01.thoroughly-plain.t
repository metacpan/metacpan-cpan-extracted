use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More tests => 13;
use Test::Exception;
use Data::Dumper;

use Data::Tubes qw< pipeline summon >;

summon('Validator::thoroughly');
ok __PACKAGE__->can('thoroughly'), "summoned thoroughly";

{
   my $v = thoroughly(
      sub { $_[0]{foo} =~ /bar|baz/ },
      ['is-even'   => sub { $_[0]{number} % 2 == 0 }],
      ['in-bounds' => sub { $_[0]{number} >= 10 && $_[0]{number} <= 21 }]
   );

   validate_validator($v, {structured => {foo => 'bar', number => 12}},
      undef, 'all validators are fine');
   validate_validator(
      $v,
      {structured => {foo => 'bar', number => 13}},
      [['is-even', '']],
      'is-even has issues'
   );
   validate_validator(
      $v,
      {structured => {foo => 'hey', number => 3}},
      [['validator-0', 0], ['is-even', ''], ['in-bounds', ''],],
      'all validators have issues'
   );
}

{
   my $v = thoroughly(
      sub { $_[0] =~ /bar|baz/ },
      qr{(?mxs:bar|foo)},
      ['the-regex', qr{(?mxs:bar|baz)}],
      { input => 'raw' },
   );

   validate_validator($v, {raw => 'bar'},
      undef, 'all validators are fine');
   validate_validator(
      $v,
      {raw => 'baz'},
      sub {
         my $got = shift->{validation};
         return if ref($got) ne 'ARRAY';
         return if @$got != 1;
         my ($name, $outcome, $type, $rx) = @{$got->[0]};
         return if $name ne 'validator-1';
         return if $outcome;
         return if $type ne 'regex';
         return unless length $rx;
         return unless $rx =~ m{bar\|foo}mxs;
         return 1;
      },
      'regex has issues'
   );
   validate_validator(
      $v,
      {raw => 'whatever'},
      sub {
         my $got = shift->{validation};
         return if ref($got) ne 'ARRAY';
         return if @$got != 3;
         return if $got->[1][2] ne 'regex';
         return if $got->[2][0] ne 'the-regex';
         return 1;
      },
      'all validators have issues'
   );
}

sub validate_validator {
   my ($validator, $record, $expected, $name) = @_;
   $expected = {%$record, validation => $expected}
     unless (ref($expected) eq 'HASH') || (ref($expected) eq 'CODE');
   my $got;
   lives_ok { $got = $validator->($record) } "$name: call lives";
   if (ref($expected) eq 'CODE') {
      ok $expected->($got), "$name: outcome as expected"
        or diag Dumper $got;
   }
   else {
      is_deeply $got, $expected, "$name: outcome as expected"
        or diag Dumper $got;
   }
} ## end sub validate_validator

done_testing();
