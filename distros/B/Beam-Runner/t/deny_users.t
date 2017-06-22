
=head1 DESCRIPTION

This file tests the L<Beam::Runnable::DenyUsers> role to ensure it
allows/denys users as appropriate.

=head1 SEE ALSO

L<Beam::Runnable::DenyUsers>

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $USER = getpwuid( $> );
{ package
        t::DenyUsers;
    use Moo;
    with 'Beam::Runnable', 'Beam::Runnable::DenyUsers';
    sub run { $t::DenyUsers::RAN++ }
}

subtest 'authorization success' => sub {
    local $t::DenyUsers::RAN = 0;
    my $foo = t::DenyUsers->new(
        deny_users => [ ],
    );
    ok !exception { $foo->run }, "user is not denied";
    ok $t::DenyUsers::RAN, 'main code ran';
};

subtest 'authorization failure' => sub {
    local $t::DenyUsers::RAN = 0;
    my $foo = t::DenyUsers->new(
        deny_users => [ $USER ],
    );
    is exception { $foo->run }, "Unauthorized user: $USER\n",
        "user is denied";
    ok !$t::DenyUsers::RAN, 'main code did not run';
};

done_testing;
