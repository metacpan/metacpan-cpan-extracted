package ACLTestApp;

use strict;
use warnings;
no warnings 'uninitialized';

use Catalyst qw/
	Session
	Session::Store::Dummy
	Session::State::Cookie

	Authentication
	Authentication::Store::Minimal
	Authentication::Credential::Password

	Authorization::Roles
	Authorization::ACL
/;

use Catalyst::Plugin::Authorization::ACL::Engine qw/$DENIED $ALLOWED/;

__PACKAGE__->config(
    authentication => {
        users => {
            foo => {
                password => "bar",
                os => "windows",
            },
            gorch => {
                password => "moose",
                roles => [qw/child/],
                os => "linux",
            },
            quxx => {
                password => "ding",
                roles => [qw/zoo_worker moose_trainer/],
                os => "osx",
            },
        },
    },
    acl => {
        deny => ["/restricted"],
    }
);

__PACKAGE__->setup;

__PACKAGE__->allow_access_if("/", sub { 1 }); # just to test that / can be applied to

__PACKAGE__->deny_access_unless_any("/lioncage", [qw/zoo_worker lion_tamer/]);

# this now in config
# __PACKAGE__->deny_access_unless("/restricted", sub { 0 }); # no one can access

__PACKAGE__->deny_access_unless("/zoo", sub {
	my ( $c, $action ) = @_;
	$c->user;
}); # only people who have bought a ticket can enter

__PACKAGE__->deny_access_unless("/zoo/rabbit", ["child"]); # the petting zoo is for children

__PACKAGE__->deny_access_unless("/zoo/moose", [qw/moose_trainer/]);

__PACKAGE__->acl_add_rule("/zoo/penguins/tux", sub {
	my ( $c, $action ) = @_;
	my $user = $c->user;
	die ( ( $user && $user->os eq "linux" ) ? 
                $Catalyst::Plugin::Authorization::ACL::Engine::ALLOWED : 
                $Catalyst::Plugin::Authorization::ACL::Engine::DENIED );
});

__PACKAGE__->allow_access_if("/zoo/penguins/madagascar", sub { 
	my ( $c, $action ) = @_;
	my $user = $c->user;
	$user && $user->os ne "windows";
});

__PACKAGE__
