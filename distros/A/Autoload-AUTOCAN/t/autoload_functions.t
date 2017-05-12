use strict;
use warnings;

package My::Package;
use Autoload::AUTOCAN 'functions';

sub AUTOCAN {
  my ($package, $function) = @_;
  return sub { $_[0] . $_[1] } if $function =~ m/cat/;
  return undef;
}

sub dog { $_[0] }

package main;
use Test::More;

my $res;
ok(eval { $res = My::Package::concatenate('foo', 'bar'); 1 }, 'concatenate function autoloaded') or diag $@;
is $res, 'foobar', 'right result';
ok(!eval { My::Package::join('foo', 'bar'); 1 }, 'join function not autoloaded');
like $@, qr/My::Package::join/, 'function in error message';

ok defined My::Package->can('cat'), 'cat method present in can';
ok defined My::Package->can('dog'), 'dog method present in can';
ok !defined My::Package->can('bird'), 'bird method not present in can';

done_testing;
