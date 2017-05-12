use Test::More tests => 9;

use strict;
use warnings;

use ok "Catalyst::Controller::BindLex";

# fake $c->stash
sub Catalyst::Controller::BindLex::stash { $_[0]->{stash} };

{
    package MyApp;
    use base qw/Catalyst::Controller::BindLex Catalyst/;

    sub bar {
        my ( $self, $c ) = @_;
        my $x : Stashed;
        my @dogs : Stashed = ( qw/fido moose/ );

        $x = "magic";
    }

    sub gorch {
        my ( $self, $c ) = @_;

        my @x : Stashed;
        my $dogs : Stashed;

        return $dogs;
    }
}

my $c = bless { stash => {} }, "MyApp";

MyApp->bar( $c );

is( $c->{stash}{x}, "magic", 'my $x : Stashed' );
is_deeply( $c->{stash}{dogs}, [qw/fido moose/], 'my @y : Stashed' );

$c->{stash}{x} = "non reference";

# Test::Exception fiddles with something naugty
ok( !eval { MyApp->gorch( $c ) }, "error thrown with non ref" );
like( $@, qr/non-reference/, "the right error, too" );

$c->{stash}{x} = \undef;

ok( !eval { MyApp->gorch( $c ) }, "error thrown with wrong reftype" );
like( $@, qr/reference of type SCALAR/, "the right error, too" );


$c->{stash}{x} = [];

ok( my $dogs_ref = eval { MyApp->gorch( $c ) }, "no error thrown with scalar ref -> array coercion" );

is( ref($dogs_ref), "ARRAY", "array -> scalar conversion");
