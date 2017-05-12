package # hide from CPAN
Catalyst::Model::KiokuDB::Test::Controller::Root;
use Moose;

use Catalyst::Model::KiokuDB::Test::User;
use Authen::Passphrase::Clear;

use Test::More;

use namespace::clean -except => 'meta';

BEGIN { extends qw(Catalyst::Controller) }

__PACKAGE__->config( namespace => '' );

our $ran;

sub insert : Local {
    my ( $self, $c ) = @_;

    ok( my $m = $c->model("KiokuDB"), "got a model" );

    isa_ok( $m, "KiokuX::Model" );

    can_ok( $m, "directory" );

    {
        my $foo = { bar => "lala" };
        $m->store( foo => $foo );

        my $user = Catalyst::Model::KiokuDB::Test::User->new(
            id => "henry",
            password => Authen::Passphrase::Clear->new("foobar"),
        );

        $m->insert($user);
    }

    isa_ok( $m->directory, "KiokuDB" );

    $ran++;
}

sub fetch : Local {
    my ( $self, $c ) = @_;

    my $m = $c->model("KiokuDB");

    {
        my $foo = $m->lookup('foo');
        is( $foo->{bar}, "lala", "correct value in loaded object" );
    }

    isa_ok( $m->directory, "KiokuDB" );

    $ran++;
}

sub leak : Local {
    my ( $self, $c ) = @_;

    my $m = $c->model("KiokuDB");

    {
        my $foo = $m->lookup('foo');
        $foo->{self} = $foo;
        $foo->{bar} = "gorch";
    }

    isa_ok( $m->directory, "KiokuDB" );

    $ran++;
}

sub fresh : Local {
    my ( $self, $c ) = @_;

    my $m = $c->model("KiokuDB");

    {
        my $foo = $m->lookup('foo');
        is( $foo->{bar}, "lala", "object loaded again (despite leak)" );
    }

    isa_ok( $m->directory, "KiokuDB" );

    $ran++;
}

sub login : Local {
    my ( $self, $c ) = @_;

    ok( !$c->user_exists, "no user" );

    $c->authenticate({ id => "henry", password => "foobar" });

    ok( $c->user_exists, 'user exists now' );

    isa_ok( $c->user->get_object, "Catalyst::Model::KiokuDB::Test::User" );

    $ran++;
}


sub login_username : Local {
    my ( $self, $c ) = @_;

    ok( !$c->user_exists, "no user" );

    $c->authenticate({ username => "henry", password => "foobar" });

    ok( $c->user_exists, 'user exists now' );

    isa_ok( $c->user->get_object, "Catalyst::Model::KiokuDB::Test::User" );

    $ran++;
}
__PACKAGE__

__END__
