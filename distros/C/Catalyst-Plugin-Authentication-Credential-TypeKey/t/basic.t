#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::MockObject::Extends;
use Test::MockObject;
use Test::Exception;
use Scalar::Util qw/blessed/;

use Catalyst::Plugin::Authentication::User::Hash;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Authentication::Credential::TypeKey" ) }

# from 01-verify.t in Authen-TypeKey-0.04
my %user = (
    ts    => '1091163746',
    email => 'bentwo@stupidfool.org',
    name  => 'Melody',
    nick  => 'foobar baz',
);

my $req = Test::MockObject->new;
$req->set_always( params => {} );
$req->mock( param => sub { $_[0]->params->{ $_[1] } } );

{
    package MockTypeKey; # this is cloneable, Test::MockObject isn't

    sub new { bless {}, shift };

    sub verify {
        my ( $self, $p ) = @_;
        $self->{_called}{verify}++;

        return $self->{_rvalue}{verify} if exists $self->{_rvalue}{verify};

        if ( ::blessed($p) ) {
            return \%user if ( $p->param("sig") );
        }
        else {
            return \%user if ( $p->{sig} );
        }
    }
    
    sub set_false {
        shift->set_always( shift, 0 )
    }
    
    sub set_true {
        shift->set_always( shift, 1 )
    }

    sub set_always {
        my ( $self, $method, $value ) = @_;
        $self->{_rvalue}{$method} = $value;
    }

    sub token {
        my $self = shift;
        $self->{token} = shift if @_;
        $self->{token};
    }

    sub clear { $_[0]{_called} = {} }

    sub called_ok {
        my ( $self, $method, $desc ) = @_;
        $desc ||= "called $method";
        ::ok( $self->{_called}{$method}, $desc );
    }
}

my $tk = MockTypeKey->new;

my $store = Test::MockObject->new;
$store->mock( get_user =>
      sub { shift; Catalyst::Plugin::Authentication::User::Hash->new($_[2]) } );

my $c = Test::MockObject::Extends->new($m);
$c->set_always( config => {} );
my $config = $c->config->{authentication}{typekey} ||= {};

$c->set_always( req     => $req );
$c->set_always( request => $req );
$c->set_false("debug");

my $authenticated;
$c->mock( set_authenticated => sub { $authenticated = $_[1] } );
$c->mock( logout => sub { undef $authenticated } );

can_ok( $m, "setup" );

$c->setup;

isa_ok( $config->{typekey_object},
    "Authen::TypeKey", '$c->config->{authentication}{typekey}{typekey_object}' );

$config->{typekey_object} = $tk;

can_ok( $m, "authenticate_typekey" );

lives_ok {
    $c->authenticate_typekey;
  }
  "can try to auth with no args, no params";

ok( !$c->called("set_authenticated"), "nothing was authenticated" );

$_->clear for $c, $tk;

%{ $req->params } = my %vars =
  ( %user, sig => 'GWwAIXbkb2xNrQO2e/r2LDl14ek=:U5+tDsPM0+EXeKzFWsosizG7+VU=',
  );

lives_ok {
    $c->authenticate_typekey;
  }
  "can try to auth, no args, all params";

$tk->called_ok("verify");
$c->called_ok( "set_authenticated", "authenticated" );

$_->clear for $c, $tk;

%{ $req->params } = ();
$config->{auth_store} = $store;

lives_ok {
    $c->authenticate_typekey(%vars);
  }
  "can try to auth with args";

$tk->called_ok("verify");
$c->called_ok( "set_authenticated", "authenticated" );
$store->called_ok( "get_user",      "user retrieved from store" );

$_->clear for $c, $tk, $store;

$tk->set_false("verify");

lives_ok {
    $c->authenticate_typekey(%vars);
  }
  "can try to auth with args";

$tk->called_ok("verify");
ok( !$c->called("set_authenticated"), "authenticated" );
ok( !$store->called("get_user"),      "no user retrieved from store" );

$c->logout;

$tk->set_true("verify");
$c->clear;

ok(
    $c->authenticate_typekey(
        my $user = Catalyst::Plugin::Authentication::User::Hash->new(
            typekey_credentials => { %vars }
        )
    ),
    "can authenticate with user object"
);

$c->called_ok("set_authenticated");

can_ok( $c, "last_typekey_object" );

is( $c->last_typekey_object->token, undef, "token is default" );

$c->authenticate_typekey( $user, token => "elk" );

is( $c->last_typekey_object->token, "elk", "token is altered in last typekey object" );

is( $config->{typekey_object}->token, undef, "but not in the default one" );

can_ok( $c, "last_typekey_error" );
