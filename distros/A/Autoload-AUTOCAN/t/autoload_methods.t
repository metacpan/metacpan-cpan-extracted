use strict;
use warnings;

package My::CodeClass;

sub new {
  my ($class, $code) = @_;
  return bless $code, $class;
}

package My::CodeOverload;
use overload '&{}' => sub { $_[0]{code} }, bool => sub {1}, fallback => 1;

sub new {
  my ($class, $code) = @_;
  return bless { code => $code }, $class;
}

package My::Class;
use Autoload::AUTOCAN;

my $amount = 0;

sub new { bless {}, shift }
sub attribute { $_[0]{attribute} }

sub AUTOCAN {
  my ($class, $method) = @_;
  return sub { $amount += $_[1] } if $method eq 'add';
  return My::CodeClass->new(sub { $amount }) if $method eq 'amount';
  return My::CodeOverload->new(sub { $_[0]{attribute} = $_[1] }) if $method eq 'set';
  return undef;
}

package main;
use Test::More;

ok defined &My::Class::AUTOLOAD, 'autoload sub installed';

ok(eval { My::Class->add(5); 1 }, 'add method autoloaded') or diag $@;
my $check;
ok(eval { $check = My::Class->amount; 1 }, 'amount method autoloaded') or diag $@;
is $check, 5, 'right number';
ok(!eval { My::Class->subtract(5); 1 }, 'subtract method not autoloaded');
like $@, qr/My::Class/, 'class mentioned in error message';
like $@, qr/subtract/, 'method mentioned in error message';

ok defined My::Class->can('add'), 'add method present in can';
ok defined My::Class->can('new'), 'new method present in can';
ok !defined My::Class->can('subtract'), 'subtract method not present in can';

my $obj = My::Class->new;
ok(eval { $obj->set('foobar'); 1 }, 'set method autoloaded') or diag $@;
is $obj->attribute, 'foobar', 'right value';
ok(!eval { $obj->unset; 1 }, 'unset method not autoloaded');
like $@, qr/My::Class/, 'class mentioned in error message';
like $@, qr/unset/, 'method mentioned in error message';

done_testing;

