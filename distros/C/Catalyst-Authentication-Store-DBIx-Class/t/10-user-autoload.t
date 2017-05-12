use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Catalyst::Authentication::Store::DBIx::Class::User;

my $message = 'I exist';

{
  package My::Test;

  sub exists { $message }
}

my $class = 'Catalyst::Authentication::Store::DBIx::Class::User';
my $o = bless({
  _user => bless({}, 'My::Test'),
}, $class);

is($o->exists, $message, 'AUTOLOAD proxies ok');

ok(my $meth = $o->can('exists'), 'can returns true');

is($o->$meth, $message, 'can returns right coderef');

is($o->can('non_existent_method'), undef, 'can on non existent method returns undef');

is($o->non_existent_method, undef, 'AUTOLOAD traps non existent method');

try {
    is($class->can('non_existent_method'), undef, "can on non existent class method");
} catch {
    my $e = $_;
    fail('can on non existent class method');
    diag("Got exception: $e");
};

try { 
    is($class->non_existent_method, undef, 'AUTOLOAD traps non existent class method');
} catch {
    my $e = $_;
    fail('AUTOLOAD traps non existent class method');
    diag("Got exception: $e");
};

done_testing;
