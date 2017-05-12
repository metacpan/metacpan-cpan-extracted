#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 100;

use Config::Strict;
use Declare::Constraints::Simple -All;

my %default = (
    b1    => 1,
    s2    => 'meh',
    enum1 => undef,
    nvar  => 2.3,
    aref1 => [ 'meh' ],
    href1 => { 'k' => 'v' },
    pos => 3,
    pos2 => 5,
    posi => 10,
);
my $config = Config::Strict->new( {
        params => {    # Parameter names
            Bool   => [ qw( b1 b2 ) ],                     # Multiple parameters
            Int    => 'ivar',                              # One parameter
            Num    => 'nvar',
            Str    => [ qw( s1 s2 ) ],
            Enum   => { enum1 => [ qw( e1 e2 ), undef ] },
            Regexp => 're1',
            ArrayRef => 'aref1',
            HashRef  => 'href1',
            CodeRef  => 'cref1',
            Anon   => {                                  # Anon routines
                pos  => And( IsNumber, Matches( qr/^[^-]+$/ ) ),
                pos2 => sub { $_[0] > 0 },
                posi => sub { $_[0] > 0 and int($_[0]) == $_[0] },
                nest => IsA( 'Config::Strict' ),
            }
        },
        required => [ qw( b1 nvar ) ],                     # Required parameters
        defaults => \%default
    }
);
#$Data::Dumper::Indent = 2;
#print Dumper $config;

# get
while ( my ( $p, $v ) = each %default ) {
    my $got = $config->get( $p );
    no warnings;
    is( $got, $v, "$p => $v" );
}

# Bad params
my_eval_ok( 'get', $config, 'blah' );
my_eval_ok( 'set', $config, 'blah' => 0 );
ok( !$config->param_exists( 'blah' ), 'blah' );
ok( !$config->param_is_set( 'blah' ), 'blah unset' );

# Set/Existent params
for my $p ( $config->all_params ) {
    # Check that all existing keys are valid
    ok( $config->param_exists( $p ), "$p exists" );
    # Check set/nonset params
    if ( exists $default{ $p } ) {
        ok( $config->param_is_set( $p ), "$p set" );
        # Validate defaults
        ok( $config->validate( $p => $config->get( $p ) ),
            "$p default valid" );
    }
    else {
        ok( !$config->param_is_set( $p ), "$p not set" );
    }
}

# Unset checks
ok( $config->param_is_set( 's2' ), 's2 set' );
$config->unset( 's2' );
ok( !$config->param_is_set( 's2' ), 's2 unset' );
ok( $config->param_exists( 's2' ),  's2 exists' );
# Required parameters
ok( $config->param_is_required( 'b1' ),  'b1 required' );
ok( !$config->param_is_required( 'b2' ), 'b2 not required' );
my_eval_ok( 'unset', $config, 'b1' );
ok( $config->param_is_set( 'b1' ), 'b1 still set' );

# Profile checks

# Int
ok( $config->validate( 'ivar' => 2 ), 'int validate' );
ok( $config->set( 'ivar' => 2 ), 'int set' );
my_eval_ok( 'set', $config, 'ivar' => 1.1 );
my_eval_ok( 'set', $config, 'ivar' => 'meh' );
is( $config->get( 'ivar' ) => 2, 'int get' );

# Enum
is( $config->get( 'enum1' ) => undef, 'enum' );
$config->set( 'enum1' => 'e1' );
is( $config->get( 'enum1' ) => 'e1', 'enum' );
$config->set( 'enum1' => undef );
is( $config->get( 'enum1' ) => undef, 'enum undef' );
my_eval_ok( 'set', $config, 'enum1' => 'blah' );
my_eval_ok( 'set', $config, 'enum1' => 1 );

# Refs
my_eval_ok( 'set', $config, 'aref1' => {} );
my_eval_ok( 'set', $config, 'href1' => [] );
my_eval_ok( 'set', $config, 'cref1' => 'meh' );
ok( $config->set( 'aref1' => [] ), 'aref set' );
ok( $config->set( 'href1' => {} ), 'href set' );
ok( $config->set( 'cref1' => sub { 1 } ), 'cref set' );

# Anon
is( $config->get( 'pos' ), 3, 'pos' );
is( $config->get( 'pos2' ), 5, 'pos' );
is( $config->get( 'posi' ), 10, 'pos' );
my_eval_ok( 'set', $config, 'pos' => -1 );
my_eval_ok( 'set', $config, 'pos2' => -1 );
my_eval_ok( 'set', $config, 'posi' => -1 );
my_eval_ok( 'set', $config, 'posi' => 1.1 );
my_eval_ok( 'set', $config, 'ivar' => 5, 'pos' => -5 );
my_eval_ok( 'set', $config, 'ivar' => 5, 'pos2' => -5 );
$config->set( pos => 2.22 );
$config->set( pos2 => 3.33 );
is_deeply(
    [ $config->get( qw( ivar pos pos2 ) ) ] => [ 2, 2.22, 3.33 ],
    "posints"
);
$config->set(
    'nest' => Config::Strict->new( {
            params   => { Bool => [ 'b1' ] },
            defaults => { b1   => 0 }
        }
    )
);
is( $config->get( 'nest' )->get( 'b1' ), 0, 'nested' );

# Subroutines

sub my_eval_ok {
    # Check for error
    my ( $subname, $object, @params ) = @_;
    $subname = "Config::Strict::$subname";
    no strict 'refs';
#    eval { $sub->( @params ) };
    eval { &{ $subname }( $object, @params ) };
    ok( $@, _error( $@ ) );
    if ( $subname eq 'Config::Strict::set' and @params % 2 == 0 ) {
        ok( !$object->validate( @params ), "setting @params invalid" );
    }
}

sub _error {
    local $_ = shift;
    s/^(.+?)\s+at.+$/$1/sg;
    'error: ' . $_;
}
