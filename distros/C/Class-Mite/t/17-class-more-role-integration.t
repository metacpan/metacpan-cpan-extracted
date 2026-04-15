#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 'lib';

SKIP: {
    eval { require Role };
    skip "Role.pm not available", 4 if $@;

    plan tests => 4;

    {
        package Test::Role;
        use Role;

        requires 'get_name';

        sub log_info {
            my ($self) = @_;
            return "Log: " . $self->get_name;
        }
    }

    {
        package Test::RoleConsumer;
        use Class::More;
        with 'Test::Role';

        has name => (required => 1);

        sub get_name { shift->name }
    }

    my $with_role = Test::RoleConsumer->new(name => 'RoleUser');
    is($with_role->get_name, 'RoleUser', 'Role requirement satisfied');
    is($with_role->log_info, 'Log: RoleUser', 'Role method works');

    # Test that does method works
    lives_ok {
        $with_role->does('Test::Role')
    } 'does method works';

    # Test multiple roles
    {
        package Test::AnotherRole;
        use Role;

        requires 'get_name';

        sub uppercase_name {
            my ($self) = @_;
            return uc $self->get_name;
        }
    }

    {
        package Test::MultiRoleConsumer;
        use Class::More;
        with qw(Test::Role Test::AnotherRole);

        has name => (required => 1);

        sub get_name { shift->name }
    }

    my $multi_role = Test::MultiRoleConsumer->new(name => 'MultiUser');
    is($multi_role->uppercase_name, 'MULTIUSER', 'Multiple roles work');
}

done_testing;
