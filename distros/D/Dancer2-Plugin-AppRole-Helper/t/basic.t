use strictures 2;

use Test::InDistDir;
use Test::More;

use Dancer2::Plugin::AppRole::Helper;

{ package App;                            use Moo }
{ package Role;                           use Moo::Role }
{ package Dancer2::Plugin::AppRole::Role; use Moo::Role }

my $app = App->new;

{

    package DSL;
    use Moo;
    sub app { $app }
}

run();
done_testing;
exit;

sub run {

    my $r = "Role";
    ok !$app->does( $r );

    my $dsl = DSL->new;
    ensure_approle $r, $dsl;
    ok $app->does( $r );

    {
        my $called = 0;
        no warnings 'redefine';
        local *Moo::Role::apply_roles_to_object = sub { $called++ };
        ensure_approle $r, $dsl;
        ok !$called;
    }

    ensure_approle_s $r, $dsl;
    ok $app->does( "Dancer2::Plugin::AppRole::$r" );

    return;
}
