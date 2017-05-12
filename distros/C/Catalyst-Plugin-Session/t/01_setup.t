#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::MockObject;
use Test::Deep;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session" ) }

my %config;
my $log      = Test::MockObject->new;
my @mock_isa = ();

$log->set_true("fatal");

{

    package MockCxt;
    use MRO::Compat;
    use base $m;
    sub new { bless {}, $_[0] }
    sub config { \%config }
    sub log    { $log }

    sub isa {
        my $self  = shift;
        my $class = shift;
        grep { $_ eq $class } @mock_isa or $self->SUPER::isa($class);
    }
}

can_ok( $m, "setup" );

eval { MockCxt->new->setup };    # throws OK is not working with NEXT
like(
    $@,
    qr/requires.*((?:State|Store).*){2}/i,
    "can't setup an object that doesn't use state/store plugins"
);

$log->called_ok( "fatal", "fatal error logged" );

@mock_isa = qw/Catalyst::Plugin::Session::State/;
eval { MockCxt->new->setup };
like( $@, qr/requires.*(?:Store)/i,
    "can't setup an object that doesn't use state/store plugins" );

@mock_isa = qw/Catalyst::Plugin::Session::Store/;
eval { MockCxt->new->setup };
like( $@, qr/requires.*(?:State)/i,
    "can't setup an object that doesn't use state/store plugins" );

$log->clear;

@mock_isa =
  qw/Catalyst::Plugin::Session::State Catalyst::Plugin::Session::Store/;
eval { MockCxt->new->setup };
ok( !$@, "setup() lives with state/store plugins in use" );
ok( !$log->called("fatal"), "no fatal error logged either" );

cmp_deeply(
    [ keys %{ $config{session} } ],
    bag(qw/expires verify_address/),
    "default values for config were populated in successful setup",
);

%config = ( session => { expires => 1234 } );
MockCxt->new->setup;
is( $config{session}{expires},
    1234, "user values are not overwritten in config" );

