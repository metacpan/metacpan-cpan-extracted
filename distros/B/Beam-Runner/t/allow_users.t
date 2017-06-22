
=head1 DESCRIPTION

This file tests the L<Beam::Runnable::AllowUsers> role to ensure it
allows/denys users as appropriate.

=head1 SEE ALSO

L<Beam::Runnable::AllowUsers>

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $USER = getpwuid( $> );
{ package
        t::AllowUsers;
    use Moo;
    with 'Beam::Runnable', 'Beam::Runnable::AllowUsers';
    sub run { $t::AllowUsers::RAN++ }
}

subtest 'authorization failure' => sub {
    my $foo = t::AllowUsers->new(
        allow_users => [ ],
    );
    is exception { $foo->run }, "Unauthorized user: $USER\n",
        "user is not authorized";
    ok !$t::AllowUsers::RAN, 'main code did not run';
};

subtest 'authorization success' => sub {
    my $foo = t::AllowUsers->new(
        allow_users => [ $USER ],
    );
    ok !exception { $foo->run }, "user is authorized";
    ok $t::AllowUsers::RAN, 'main code ran';
    $t::AllowUsers::RAN = 0;
};

done_testing;
