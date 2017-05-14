#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Catalyst::Authentication::User;

my $m;
BEGIN { use_ok($m = "Catalyst::Plugin::Authorization::RoleAbilities") }

my $user = MockUser->new;
$user->role_actions(qw/delete add rename/);

my $c = MockAuthz->new($user);

can_ok($m, "assert_user_ability");

my @action_names = map { $_->name } $user->user_roles->search_related('role')->search_related('role_actions')->search_related('action');

lives_ok { $c->assert_user_ability("delete") } "existing action is OK";
lives_ok { $c->assert_user_ability(@action_names) } "all action is OK";
throws_ok { $c->assert_user_ability("move") } qr/missing action.*move/i, "missing action throws error";
throws_ok { $c->assert_user_ability(qw/delete move/) } qr/missing action.*move/i, "also when there are existing actions";
throws_ok { $c->assert_user_ability(@action_names, qw/move/) } qr/missing action.*move/i, "even all actions";

is($c->check_user_ability("delete"), 1, "check_user_ability true");
is($c->check_user_ability("move"),   0, "check_user_ability false");

$c = MockAuthz->new(undef);

throws_ok { $c->assert_user_ability("delete") } qr/no logged in user/i, "can't assert without logged user";
lives_ok { $c->assert_user_ability($user, "delete") } "unless supplying user explicitly";

done_testing();

#
# Packages for testin
#

#
# Mocking authz
package MockAuthz;

use base 'Catalyst::Plugin::Authorization::RoleAbilities';

sub new {
    my ($class, $user) = @_;
    return bless { user => $user }, $class;
}
sub user  { return shift->{user}; }
sub debug { return 0; }

#
# Mocking user
package MockUser;
use base 'Catalyst::Authentication::User';

sub supported_features { return { roles => 1 } }
sub user_roles { shift->{_role_actions} }
sub role_actions { my $self = shift; $self->{_role_actions} = MockDBIC->new(@_) }

#
# Mocking DB layer
package MockDBIC;

sub new {
    my ($class, @actions) = @_;
    return bless { _actions => \@actions }, $class;
}

sub search_related {
    my ($self, $type) = @_;
    if ($type eq 'action') {
        return map { my $ma = MockAction->new; $ma->name($_); $ma } @{ $self->{_actions} };
    } else {
        return $self;
    }
}

#
# Mocking an action
package MockAction;
sub new { return bless {}, shift }

sub name {
    if ($_[1]) { $_[0]->{_name} = $_[1] }
    return $_[0]->{_name};
}
