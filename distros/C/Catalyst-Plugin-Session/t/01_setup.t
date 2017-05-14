#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Class::MOP;
use Test::Deep;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session" ) }

my %config;
my $log_meta = Class::MOP::Class->create_anon_class(superclasses => ['Moose::Object']);
my $log      = $log_meta->name->new;
my @mock_isa = ();

my $calls = 0;
$log_meta->add_method("fatal" => sub { $calls++; 1; });

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

is $calls, 1, 'Fatal error logged';

@mock_isa = qw/Catalyst::Plugin::Session::State/;
eval { MockCxt->new->setup };
like( $@, qr/requires.*(?:Store)/i,
    "can't setup an object that doesn't use state/store plugins" );

@mock_isa = qw/Catalyst::Plugin::Session::Store/;
eval { MockCxt->new->setup };
like( $@, qr/requires.*(?:State)/i,
    "can't setup an object that doesn't use state/store plugins" );

$calls = 0;

@mock_isa =
  qw/Catalyst::Plugin::Session::State Catalyst::Plugin::Session::Store/;
eval { MockCxt->new->setup };
ok( !$@, "setup() lives with state/store plugins in use" );
is( $calls, 0, "no fatal error logged either" );

cmp_deeply(
    [ keys %{ $config{'Plugin::Session'} } ],
    bag(qw/expires verify_address verify_user_agent expiry_threshold/),
    "default values for config were populated in successful setup",
);

%config = ( session => { expires => 1234 } );
MockCxt->new->setup;
is( $config{session}{expires},
    1234, "user values are not overwritten in config" );

