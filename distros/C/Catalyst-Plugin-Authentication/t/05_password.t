use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;
use Class::MOP;
use Class::MOP::Class;
use Moose::Object;

# 1,2
my $m; BEGIN { use_ok($m = "Catalyst::Authentication::Credential::Password") }
can_ok($m, "authenticate");

my $app_meta = Class::MOP::Class->create_anon_class( superclasses => ['Moose::Object'] );
my $realm_meta = Class::MOP::Class->create_anon_class( superclasses => ['Moose::Object'] );
my $user_meta = Class::MOP::Class->create_anon_class( superclasses => ['Moose::Object'] );
our ($user_get_password_field_name, $user_password );
$user_meta->add_method('get' => sub { $user_get_password_field_name = $_[1]; return $user_password });

# 3-6 # Test clear passwords if you mess up the password_field
{
    local $user_password = undef;        # The user returns an undef password,
    local $user_get_password_field_name; # as there is no field named 'mistyped'
    my $config = { password_type => 'clear', password_field => 'mistyped' };
    my $i; lives_ok { $i = $m->new($config, $app_meta->name->new, $realm_meta->name->new) } 'Construct instance';
    ok($i, 'Have instance');
    my $r = $i->check_password($user_meta->name->new, { username => 'someuser', password => 'password' });
    is($user_get_password_field_name, 'mistyped',
        '(Incorrect) field name from config correctly passed to user');
    ok(! $r, 'Authentication unsuccessful' );
}

# 7-11 # Test clear passwords working, and not working
{
    local $user_password = 'mypassword';
    local $user_get_password_field_name;
    my $config = { password_type => 'clear', password_field => 'the_password_field' };
    my $i; lives_ok { $i = $m->new($config, $app_meta->name->new, $realm_meta->name->new) } 'Construct instance';
    ok($i, 'Have instance');
    my $r = $i->check_password($user_meta->name->new, { username => 'someuser', the_password_field => 'mypassword' });
    is($user_get_password_field_name, 'the_password_field',
        'Correct field name from config correctly passed to user');
    ok( $r, 'Authentication successful with correct password' );
    $r = $i->check_password($user_meta->name->new, { username => 'someuser', the_password_field => 'adifferentpassword' });
    ok( ! $r, 'Authentication ussuccessful with incorrect password' );
}
