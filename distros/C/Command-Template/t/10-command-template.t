use strict;
use warnings;
use Test::More;

use Command::Template;

can_ok 'Command::Template', $_
   for qw< command_runner command_template cr ct >;

{
   no strict 'refs';
   *ct = *Command::Template::ct;
}

my $ct = ct(qw{ foo <bar=galook> <baz> [muz] [far=away] });
isa_ok $ct, 'Command::Template::Instance';

for my $test (
   [
      {
         bar => 'BAR',
         baz => 'BAZ',
         muz => 'Moooz',
         far => 'close',
      },
      [qw< foo BAR BAZ Moooz close >],
      'all parameters have a value',
   ],
   [
      {
         baz => 'BAZ',
         muz => 'Moooz',
      },
      [qw< foo galook BAZ Moooz away >],
      'defaults are used',
   ],
   [
      {
         baz => 'BAZ',
      },
      [qw< foo galook BAZ away >],
      'missing optional parameter',
   ],
   [
      {
         baz => 'BAZ',
         far => undef,
      },
      [qw< foo galook BAZ >],
      'removing optional parameter',
   ],
) {
   my ($bindings, $expected, $message) = @$test;
   my $got = $ct->generate(%$bindings);
   is_deeply $got, $expected, $message;
}

done_testing();
