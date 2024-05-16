#!/usr/bin/env perl

use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Tie::Watch;
use Storable;

pass "tie-watch start";

sub run {
    my $output = "";
    my @return;

    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, ">",  \$output or die $!;
        open STDERR, ">>", \$output or die $!;
        @return = eval { Data::Tie::Watch->new( @_ ) };
    }

    if ( $@ ) {
        $output = $@;
        chomp $output;
    }

    ( $output, @return );
}

my $test_scalar;
my @test_array;
my %test_hash;
my $clone;

sub reset_vars {
    $test_scalar = 'test_scalar';
    @test_array  = ( 'test', 'array' );
    %test_hash   = ( test => 'hash' );
    undef $clone;
}

###########################################
#               Cases
###########################################

# User Errors
sub _define_cases_error {
    (
        {
            name     => "no input",
            args     => {},
            expected => {
                watch_obj => 0,
                stdout    => qr{ -variable \s+ is \s+ required! }x,
            },
        },
    )
}

# Scalar
sub _define_cases_scalar_basic {
    (
        {
            name => "scalar",
            args => {
                -variable => \$test_scalar,
            },
            actions => sub {
                $test_scalar = 'updated_test_scalar';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => \"updated_test_scalar",
            },
        },
        {
            name => "scalar - fetch",
            args => {
                -variable => \$test_scalar,
                -fetch    => sub { 42 },
            },
            actions => sub {
                $test_scalar = $test_scalar;
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => \"42",
            },
        },
        {
            name => "scalar - store",
            args => {
                -variable => \$test_scalar,
                -store    => sub { shift->Store( 43 ) },
            },
            actions => sub {
                $test_scalar = 'updated_test_scalar';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => \"43",
            },
        },
    )
}

sub _define_cases_scalar_clone {
    (
        {
            name => "scalar with clone",
            args => {
                -variable => \$test_scalar,
            },
            actions => sub {
                $clone       = Storable::dclone( \$test_scalar );
                $$clone      = "cloned_test_scalar";
                $test_scalar = 'updated_test_scalar2';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => \"updated_test_scalar2",
                clone     => \"cloned_test_scalar",
            },
        },
        {
            name => "scalar with clone - fetch",
            args => {
                -variable => \$test_scalar,
                -fetch    => sub { 42 },
            },
            actions => sub {
                $clone       = Storable::dclone( \$test_scalar );
                $$clone      = $$clone;
                $test_scalar = $test_scalar;
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => \"42",
                clone     => \"42",
            },
        },
        {
            name => "scalar with clone - store",
            args => {
                -variable => \$test_scalar,
                -store    => sub { shift->Store( 43 ) },
            },
            actions => sub {
                $clone  = Storable::dclone( \$test_scalar );
                $$clone = "new clone value",
                  $test_scalar = "updated_test_scalar";
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => \"43",
                clone     => \"43",
            },
        },
    )
}

sub _define_cases_scalar_no_clone {
    (
        {
            name => "scalar no clone",
            args => {
                -variable => \$test_scalar,
                -clone    => 0,
            },
            actions => sub {
                $clone       = Storable::dclone( \$test_scalar );
                $$clone      = "cloned_test_scalar";
                $test_scalar = 'updated_test_scalar2';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => \"updated_test_scalar2",
                clone     => \"cloned_test_scalar",
            },
        },
        {
            name => "scalar no clone - fetch",
            args => {
                -variable => \$test_scalar,
                -fetch    => sub { 42 },
                -clone    => 0,
            },
            actions => sub {
                $clone       = Storable::dclone( \$test_scalar );
                $$clone      = $$clone;
                $test_scalar = $test_scalar;
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => \"42",
                clone     => \"test_scalar",
            },
        },
        {
            name => "scalar no clone - store",
            args => {
                -variable => \$test_scalar,
                -store    => sub { shift->Store( 43 ) },
                -clone    => 0,
            },
            actions => sub {
                $clone  = Storable::dclone( \$test_scalar );
                $$clone = "new clone value",
                  $test_scalar = "updated_test_scalar";
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => \"43",
                clone     => \"new clone value",
            },
        },
    )
}

# Array
sub _define_cases_array_basic {
    (
        {
            name => "array",
            args => {
                -variable => \@test_array,
            },
            actions => sub {
                $test_array[0] = "test2";
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => [qw( test2 array )],
            },
        },
        {
            name => "array - fetch",
            args => {
                -variable => \@test_array,
                -fetch    => sub { 42 },
            },
            actions => sub {
                $clone = $test_array[0];
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => [qw( 42 42 )],
                clone     => "42"
            },
        },
        {
            name => "array - store",
            args => {
                -variable => \@test_array,
                -store    => sub { shift->Store( shift, 43 ) },
            },
            actions => sub {
                $test_array[0] = 'updated_test_array';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => [qw( 43 array )],
            },
        },
    )
}

sub _define_cases_array_clone {
    (
        {
            name => "array with clone",
            args => {
                -variable => \@test_array,
            },
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $test_array[0] = "test3";
                $clone->[0]    = "cloned";
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => [qw( test3 array )],
                clone     => [qw( cloned array )],
            },
        },
        {
            name => "array with clone - fetch",
            args => {
                -variable => \@test_array,
                -fetch    => sub { 42 },
            },
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $test_array[0] = "test3";
                $clone->[0]    = "cloned";
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => [qw( 42 42 )],
                clone     => [qw( 42 42 )],
            },
        },
        {
            name => "array with clone - store",
            args => {
                -variable => \@test_array,
                -store    => sub { shift->Store( shift, 43 ) },
            },
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $test_array[0] = "test3";
                $clone->[1]    = "cloned";
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => [qw( 43 array )],
                clone     => [qw( test 43 )],
            },
        },
    )
}

sub _define_cases_array_no_clone {
    (
        {
            name => "array no clone",
            args => {
                -variable => \@test_array,
                -clone    => 0,
            },
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $test_array[0] = "test4";
                $clone->[0]    = "cloned";
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => [qw( test4 array )],
                clone     => [qw( cloned array )],
            },
        },
        {
            name => "array no clone - fetch",
            args => {
                -variable => \@test_array,
                -fetch    => sub { 42 },
                -clone    => 0,
            },
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $test_array[0] = "test3";
                $clone->[0]    = "cloned";
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => [qw( 42 42 )],
                clone     => [qw( cloned array )],
            },
        },
        {
            name => "array no clone - store",
            args => {
                -variable => \@test_array,
                -store    => sub { shift->Store( shift, 43 ) },
                -clone    => 0,
            },
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $test_array[0] = "test3";
                $clone->[0]    = "cloned";
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => [qw( 43 array )],
                clone     => [qw( cloned array )],
            },
        },
    )
}

# Hash
sub _define_cases_hash_basic {
    (
        {
            name => "hash",
            args => {
                -variable => \%test_hash,
            },
            actions => sub {
                $test_hash{var} = 'updated_test_hash';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test hash var updated_test_hash )},
            },
        },
        {
            name => "hash - fetch",
            args => {
                -variable => \%test_hash,
                -fetch    => sub { 42 },
            },
            actions => sub {
                $clone = $test_hash{test};
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test 42 )},
                clone     => "42",
            },
        },
        {
            name => "hash - store",
            args => {
                -variable => \%test_hash,
                -store    => sub { shift->Store( shift, 43 ) },
            },
            actions => sub {
                $test_hash{var} = 'updated_test_hash';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test hash var 43 )},
            },
        },
    )
}

sub _define_cases_hash_clone {
    (
        {
            name => "hash with clone",
            args => {
                -variable => \%test_hash,
            },
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_test_hash3";
                $test_hash{test} = 'updated_test_hash3';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test updated_test_hash3 )},
                clone     => {qw( test cloned_test_hash3 )},
            },
        },
        {
            name => "hash with clone - fetch",
            args => {
                -variable => \%test_hash,
                -fetch    => sub { 42 },
            },
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_test_hash3";
                $test_hash{test} = 'updated_test_hash3';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test 42 )},
                clone     => {qw( test 42 )},
            },
        },
        {
            name => "hash with clone - store",
            args => {
                -variable => \%test_hash,
                -store    => sub { shift->Store( shift, 43 ) },
            },
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_test_hash3";
                $test_hash{test} = 'updated_test_hash3';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test 43 )},
                clone     => {qw( test 43 )},
            },
        },
    )
}

sub _define_cases_hash_no_clone {
    (
        {
            name => "hash no clone",
            args => {
                -variable => \%test_hash,
                -clone    => 0,
            },
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_test_hash4";
                $test_hash{test} = 'updated_test_hash4';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test updated_test_hash4 )},
                clone     => {qw( test cloned_test_hash4 )},
            },
        },
        {
            name => "hash no clone - fetch",
            args => {
                -variable => \%test_hash,
                -fetch    => sub { 42 },
                -clone    => 0,
            },
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_test_hash5";
                $test_hash{test} = 'updated_test_hash5';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test 42 )},
                clone     => {qw( test cloned_test_hash5 )},
            },
        },
        {
            name => "hash no clone - store",
            args => {
                -variable => \%test_hash,
                -store    => sub { shift->Store( shift, 43 ) },
                -clone    => 0,
            },
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_test_hash6";
                $test_hash{test} = 'updated_test_hash6';
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test 43 )},
                clone     => {qw( test cloned_test_hash6 )},
            },
        },
    )
}

# Segmentation Faults

sub _define_cases_segmentation {
    (
        {
            name => "segv fault",
            args => {
                -variable => \%test_hash,
                -clone    => 0,
            },
            actions => sub {
                $clone = Storable::dclone( \%test_hash );

                # $clone->{test}   = "cloned_test_hash4";
                # $test_hash{test} = 'updated_test_hash4';
                1 for keys %$clone;
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test hash )},
                clone     => {qw( test hash )},
            },
        },
        {
            name => "segv fault - fetch",
            args => {
                -variable => \%test_hash,
                -fetch    => sub { 42 },
                -clone    => 0,
            },
            actions => sub {
                $clone = Storable::dclone( \%test_hash );
                1 for keys %$clone;
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test 42 )},
                clone     => {qw( test hash )},
            },
        },
        {
            name => "segv fault - store",
            args => {
                -variable => \%test_hash,
                -store    => sub { shift->Store( shift, 43 ) },
                -clone    => 0,
            },
            actions => sub {
                $clone = Storable::dclone( \%test_hash );
                1 for keys %$clone;
            },
            expected => {
                watch_obj => 1,
                stdout    => "",
                value     => {qw( test hash )},
                clone     => {qw( test hash )},
            },
        },
    )
}

my @cases = (

    # User Errors
    _define_cases_error(),

    # Scalar
    _define_cases_scalar_basic(),
    _define_cases_scalar_clone(),
    _define_cases_scalar_no_clone(),

    # Array
    _define_cases_array_basic(),
    _define_cases_array_clone(),
    _define_cases_array_no_clone(),

    # Hash
    _define_cases_hash_basic(),
    _define_cases_hash_clone(),
    _define_cases_hash_no_clone(),

    # Segmentation Faults
    _define_cases_segmentation(),
);

for my $case ( @cases ) {
    my ( $stdout, $watch_obj ) = run( %{ $case->{args} } );

    if ( $case->{expected} ) {

        # STDOUT.
        my $expected_stdout = $case->{expected}{stdout} // '';
        if ( ref( $expected_stdout ) eq ref( qr// ) ) {
            like $stdout, $expected_stdout, "$case->{name} - stdout";
        }
        else {
            is $stdout, $expected_stdout, "$case->{name} - stdout";
        }

        # Return object.
        if ( $case->{expected}{watch_obj} ) {
            ok $watch_obj, "$case->{name} - watch_obj";
            ok(
                defined $Data::Tie::Watch::METHODS{"$watch_obj"},
                "$case->{name} - METHODS has object",
            );
        }
        else {
            ok !$watch_obj, "$case->{name} - watch_obj";
        }
    }

    # Run actions.
    if ( $case->{actions} ) {
        $case->{actions}->( $case );
    }

    # Check for variable values afterwards.
    if ( exists $case->{expected}{value} ) {
        is_deeply(
            $case->{args}{-variable},
            $case->{expected}{value},
            "$case->{name} - value",
        );
    }

    # Check for clone values afterwards (if any).
    if ( exists $case->{expected}{clone} ) {
        is_deeply( $clone, $case->{expected}{clone}, "$case->{name} - clone", );
    }

    # Cleanup for the next call.
    if ( $watch_obj ) {
        $watch_obj->Unwatch();
        reset_vars();
    }

    last if $case->{debug};
}

done_testing();
