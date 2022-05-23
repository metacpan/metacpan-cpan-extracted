use Test::More;

use strict;
use warnings;

use Authen::Pluggable;
use Mojo::Log;
use Mojo::File 'path';

my $provider = 'Passwd';

my $user = 'test';
my $pass = 'test';

my $users = { users1 => [ 'foo', 'foo' ], users2 => [ 'bar', 'bar' ] };

my $log  = $ENV{DEBUG} ? Mojo::Log->new( color => 1 ) : undef;
my $auth = new Authen::Pluggable( log => $log );

isa_ok(
    $auth->providers(
        {   users1 => {
                provider => 'Passwd',
                'file'   => path(__FILE__)->sibling('users1')->to_string,
            },
            users2 => {
                provider => 'Passwd',
                'file'   => path(__FILE__)->sibling('users2')->to_string
            }
        }
    ),
    'Authen::Pluggable', "Manual alias configuration"
);

foreach my $p (qw/users1 users2/) {
    my $uinfo = $auth->authen( $users->{$p}->[0], $users->{$p}->[1] );

    is( $uinfo->{user},     $users->{$p}->[0], "$p: user authenticated" );
    is( $uinfo->{provider}, $p,                "$p: correct provider" );
}

my $auth1 = new Authen::Pluggable( log => $log );

foreach my $alias (keys %$users) {
    isa_ok(
        $auth1
            ->provider($alias, 'Passwd')
            ->cfg('file'   => path(__FILE__)->sibling($alias)->to_string),
    'Authen::Pluggable', "$alias: automatic alias configuration"
    );
}

foreach my $p (qw/users1 users2/) {
    my $uinfo = $auth->authen( $users->{$p}->[0], $users->{$p}->[1] );

    is( $uinfo->{user},     $users->{$p}->[0], "$p: user authenticated" );
    is( $uinfo->{provider}, $p,                "$p: correct provider" );
}

done_testing();
