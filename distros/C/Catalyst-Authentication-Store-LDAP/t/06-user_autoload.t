use strict;
use warnings;
use Test::More;

use Catalyst::Authentication::Store::LDAP::User;

my $message = 'I exist';

{
    package TestUser;
    use base 'Catalyst::Authentication::Store::LDAP::User';
    sub has_attribute {
        return unless pop eq 'exists';
        return $message;
    }
}

my $o = bless {}, 'TestUser';

is($o->exists, $message, 'AUTOLOAD proxies ok');

ok(my $meth = $o->can('exists'), 'can returns true');

is($o->$meth, $message, 'can returns right coderef');

done_testing;
