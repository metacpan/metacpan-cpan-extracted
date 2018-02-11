use strict;
use warnings;

package My::Class;
use Autoload::AUTOCAN 'install_subs';

my $amount = 0;
my $toggle;
sub AUTOCAN {
  my ($class, $method) = @_;
  return sub { $amount } if $method eq 'amount';
  return $toggle++ ? sub { $amount++ } : sub { $amount-- } if $method eq 'change';
  return undef;
}

package main;
use Test::More;
use Sub::Util 'subname';

ok defined &My::Class::AUTOLOAD, 'autoload sub installed';

my $check = My::Class->can('amount');
ok defined $check, 'amount method autoloaded and installed';
is subname($check), 'My::Class::amount', 'right subname';
is $check->(), 0, 'right number';

ok(eval { My::Class->change; 1 }, 'change method autoloaded') or diag $@;
is +My::Class->amount, -1, 'right number';
my $change = My::Class->can('change');
ok defined $change, 'change method installed';
is subname($change), 'My::Class::change', 'right subname';
My::Class->change;
is +My::Class->amount, -2, 'right number';

done_testing;

