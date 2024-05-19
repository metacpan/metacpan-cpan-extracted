#!/usr/bin/env perl

use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Trace;
use feature      qw( say );
use Data::Dumper qw( Dumper );
use Storable;

pass "data-trace start";

###########################################
#            Test Variables
###########################################

my $test_scalar;
my @test_array;
my %test_hash;
my $test_complex;
my $clone;

sub _define_complex_base_value {
    {
        authors => [
            {
                first => 'Charles',
                last  => 'Dickens',
            },
            {
                first => 'George',
                last  => 'Eliot',
            },
        ],
        poets => [ 'Robert Frost', 'William Blake', ],
    };
}

sub _reset_vars {
    $test_scalar  = 'test_scalar';
    @test_array   = ( 'test', 'array' );
    %test_hash    = ( test => 'hash' );
    $test_complex = _define_complex_base_value();
    undef $clone;
}
_reset_vars();

###########################################
#             Define Cases
###########################################

sub _define_regex {

    # General builders.
    my $timestamp  = qr{ \[ [^\[]+ \] }x;
    my $anon_lines = qr{
        \n \s+ \|- \s+ main::__ANON__\b .+
        \n \s+ \|- \s+ main::__ANON__\b .+
    }x;
    my $anon_coderef_lines = qr{
        \n \s+ \|- \s+ main::__ANON__\b .+
        \n \s+ \|- \s+ main::_dummy_run_coderef\b .+
    }x;
    my $anon_raw_lines = qr{
        \n \s+ \|- \s+ Data::Trace::_Trace\b .+
        \n \s+ \|- \s+ Data::Trace::__ANON__\b .+
    }x;
    my $_build_trace = sub {
        my ( $ref, $method, @values ) = @_;
        my $args =
          join ', \s+',
          map { qq("$_") } @values;

        my $is_tie = qr{
            ^
            (?: Scalar | Array | Hash )
            $
        }x;

        my $sub =
          ( $ref =~ /$is_tie/ )
          ? qr{ ::${ref}::$method \( }x
          : qr{ $ref }x;

        return qr {
            $timestamp \s+
            $method\( \s* $args \s* \): .+
            $sub .+
        }x;
    };

    # Scalar
    my $scalar_store     = $_build_trace->( "Scalar", "STORE", "scalar2" );
    my $scalar_store_mod = $_build_trace->( "Scalar", "STORE", "scalar3" );
    my $scalar_clone_store =
      $_build_trace->( "Scalar", "STORE", "cloned_scalar" );
    my $scalar_store_firstname = $_build_trace->( "Scalar", "STORE", "Charly" );
    my $scalar_store_firstname_raw =
      $_build_trace->( "Data::Trace", "STORE", "Charly" );

    # Array.
    my $array_store = $_build_trace->( "Array", "STORE", 1, "array2" );
    my $array_clone_store =
      $_build_trace->( "Array", "STORE", 1, "cloned_array" );
    my $array_pop   = $_build_trace->( "Array", "POP" );
    my $array_clear = $_build_trace->( "Array", "CLEAR" );

    # Hash.
    my $hash_store = $_build_trace->( "Hash", "STORE", "test", "hash2" );
    my $hash_clone_store =
      $_build_trace->( "Hash", "STORE", "test", "cloned_hash" );
    my $hash_delete = $_build_trace->( "Hash", "DELETE", "test" );
    my $hash_clear  = $_build_trace->( "Hash", "CLEAR" );
    my $hash_store_firstname =
      $_build_trace->( "Hash", "STORE", "first", "Charly" );
    my $hash_store_firstname_raw =
      $_build_trace->( "Data::Trace", "STORE", "first", "Charly" );

    # Actual patterns to use.
    {
        empty => qr{ ^ $ }x,

        trace => {
            basic1 => qr{ ^ $timestamp \s+ HERE: \s+ main:: .+ $ }x,
            basic2 => qr{
                ^
                \n $timestamp \s+ HERE: \s+ main:: .+
                \n \s+ \|- \s+ main::_run\b .+
                $
            }x,
            hey1 => qr{ ^ $timestamp \s+ HEY \s+ main:: .+ $ }x,
            hey2 => qr{
                ^
                \n $timestamp \s+ HEY \s+ main:: .+
                \n \s+ \|- \s+ main::_run\b .+
                $
            }x,
        },

        scalar => {
            basic1    => qr{ ^ $scalar_store $ }x,
            basic     => qr{ ^ \n $scalar_store $anon_lines $ }x,
            basic_mod => qr{ ^ \n $scalar_store_mod $anon_lines $ }x,
            clone1    => qr{ ^ $scalar_clone_store \n $scalar_store $ }x,
            clone     => qr{
                ^
                \n $scalar_clone_store $anon_lines
                \n
                \n $scalar_store $anon_lines
                $
            }x,
            firstname  => qr{ ^ \n $scalar_store_firstname $anon_lines $ }x,
            firstname1 => qr{ ^ $scalar_store_firstname $ }x,
            coderef_firstname =>
              qr{ ^ \n $scalar_store_firstname $anon_coderef_lines $ }x,
            firstname_raw =>
              qr{ ^ \n $scalar_store_firstname_raw $anon_raw_lines $ }x,
            firstname_raw1 => qr{ ^ $scalar_store_firstname_raw $ }x,
        },

        array => {
            basic1 => qr{ ^ $array_store $ }x,
            basic  => qr{ ^ \n $array_store $anon_lines $ }x,
            pop    => qr{ ^ \n $array_pop $anon_lines $ }x,
            clear  => qr{ ^ \n $array_clear $anon_lines $ }x,
            clone1 => qr{ ^ $array_clone_store \n $array_store $ }x,
            clone  => qr{
                ^
                \n $array_clone_store $anon_lines
                \n
                \n $array_store $anon_lines
                $
            }x,
        },

        hash => {
            basic1 => qr{ ^ $hash_store $ }x,
            basic  => qr{ ^ \n $hash_store $anon_lines $ }x,
            delete => qr{ ^ \n $hash_delete $anon_lines $ }x,
            clear  => qr{ ^ \n $hash_clear $anon_lines $ }x,
            clone1 => qr{ ^ $hash_clone_store \n $hash_store $ }x,
            clone  => qr{
                ^
                \n $hash_clone_store $anon_lines
                \n
                \n $hash_store $anon_lines
                $
            }x,
            firstname     => qr{ ^ \n $hash_store_firstname $anon_lines $ }x,
            firstname1    => qr{ ^ $hash_store_firstname $ }x,
            firstname_raw =>
              qr{ ^ \n $hash_store_firstname_raw $anon_raw_lines $ }x,
            firstname_raw1    => qr{ ^ $hash_store_firstname_raw $ }x,
            coderef_firstname =>
              qr{ ^ \n $hash_store_firstname $anon_coderef_lines $ }x,
        },

    };
}
my $regex = _define_regex();

sub _dummy_run_coderef {    # To provide another scope.
    my ( $coderef ) = @_;
    $coderef->();
}

sub _dummy_update_firstname {
    sub {
        _dummy_run_coderef(
            sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            }
        );
    };
}

# Only stack trace.
sub _define_cases_stack_trace {
    (
        {
            name     => "no input",
            args     => [],
            expected => {
                stdout => $regex->{trace}{basic1},
            },
        },
        {
            name     => "args: lv=1",
            args     => [1],
            expected => {
                stdout => $regex->{trace}{basic1},
            },
        },
        {
            name     => "args: -levels 1",
            args     => [ -levels => 1 ],
            expected => {
                stdout => $regex->{trace}{basic1},
            },
        },
        {
            name     => "args: lv=2",
            args     => [2],
            expected => {
                stdout => $regex->{trace}{basic2},
            },
        },
        {
            name     => "args: -levels 2",
            args     => [ -levels => 2 ],
            expected => {
                stdout => $regex->{trace}{basic2},
            },
        },
        {
            name     => "args: -message HEY",
            args     => [ -message => "HEY" ],
            expected => {
                stdout => $regex->{trace}{hey1},
            },
        },
        {
            name     => "args: HEY",
            args     => ["HEY"],
            expected => {
                stdout => $regex->{trace}{hey1},
            },
        },
        {
            name     => "args: -message HEY -levels 2",
            args     => [ -message => "HEY", -levels => 2 ],
            expected => {
                stdout => $regex->{trace}{hey2},
            },
        },
        {
            name     => "args: HEY 2",
            args     => [ "HEY", 2 ],
            expected => {
                stdout => $regex->{trace}{hey2},
            },
        },
    )
}

# Scalar
sub _define_cases_scalar_basic {
    (
        {
            name    => "scalar",
            args    => [ \$test_scalar, ],
            actions => sub {
                $test_scalar = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{basic},
                variable => \$test_scalar,
                value    => \"scalar2",
            },
        },
        {
            name => "scalar -var",
            args => [
                -var => \$test_scalar,
            ],
            actions => sub {
                $test_scalar = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{basic},
                variable => \$test_scalar,
                value    => \"scalar2",
            },
        },
        {
            name    => "scalar 1",
            args    => [ \$test_scalar, 1, ],
            actions => sub {
                $test_scalar = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{basic1},
                variable => \$test_scalar,
                value    => \"scalar2",
            },
        },
        {
            name => "scalar -levels 1",
            args => [
                \$test_scalar, -levels => 1,
            ],
            actions => sub {
                $test_scalar = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{basic1},
                variable => \$test_scalar,
                value    => \"scalar2",
            },
        },
        {
            name => "scalar -levels 1 -var",
            args => [
                -var    => \$test_scalar,
                -levels => 1,
            ],
            actions => sub {
                $test_scalar = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{basic1},
                variable => \$test_scalar,
                value    => \"scalar2",
            },
        },
    )
}

sub _define_cases_scalar_clone {
    (
        {
            name    => "scalar clone",
            args    => [ \$test_scalar, ],
            actions => sub {
                $clone       = Storable::dclone( \$test_scalar );
                $$clone      = "cloned_scalar";
                $test_scalar = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{clone},
                variable => \$test_scalar,
                value    => \"scalar2",
                clone    => \"cloned_scalar",
            },
        },
        {
            name    => "scalar clone, lv=1",
            args    => [ \$test_scalar, 1, ],
            actions => sub {
                $clone       = Storable::dclone( \$test_scalar );
                $$clone      = "cloned_scalar";
                $test_scalar = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{clone1},
                variable => \$test_scalar,
                value    => \"scalar2",
                clone    => \"cloned_scalar",
            },
        },
    )
}

sub _define_cases_scalar_no_clone {
    (
        {
            name => "scalar no clone",
            args => [
                \$test_scalar, -clone => 0,
            ],
            actions => sub {
                $clone       = Storable::dclone( \$test_scalar );
                $$clone      = "cloned_scalar";
                $test_scalar = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{basic},
                variable => \$test_scalar,
                value    => \"scalar2",
                clone    => \"cloned_scalar",
            },
        },
        {
            name => "scalar no clone, lv=1",
            args => [
                \$test_scalar,
                -clone => 0,
                1,
            ],
            actions => sub {
                $clone       = Storable::dclone( \$test_scalar );
                $$clone      = "cloned_scalar";
                $test_scalar = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{basic1},
                variable => \$test_scalar,
                value    => \"scalar2",
                clone    => \"cloned_scalar",
            },
        },
    )
}

# Array
sub _define_cases_array_basic {
    (
        {
            name    => "array",
            args    => [ \@test_array, ],
            actions => sub {
                $test_array[1] = 'array2';
            },
            expected => {
                stdout   => $regex->{array}{basic},
                variable => \@test_array,
                value    => [qw( test array2 )],
            },
        },
        {
            name => "array -var",
            args => [
                -var => \@test_array,
            ],
            actions => sub {
                $test_array[1] = 'array2';
            },
            expected => {
                stdout   => $regex->{array}{basic},
                variable => \@test_array,
                value    => [qw( test array2 )],
            },
        },
        {
            name    => "array 1",
            args    => [ \@test_array, 1, ],
            actions => sub {
                $test_array[1] = 'array2';
            },
            expected => {
                stdout   => $regex->{array}{basic1},
                variable => \@test_array,
                value    => [qw( test array2 )],
            },
        },
        {
            name => "array -levels 1",
            args => [
                \@test_array, -levels => 1,
            ],
            actions => sub {
                $test_array[1] = 'array2';
            },
            expected => {
                stdout   => $regex->{array}{basic1},
                variable => \@test_array,
                value    => [qw( test array2 )],
            },
        },
        {
            name => "array -levels 1 -var",
            args => [
                -var    => \@test_array,
                -levels => 1,
            ],
            actions => sub {
                $test_array[1] = 'array2';
            },
            expected => {
                stdout   => $regex->{array}{basic1},
                variable => \@test_array,
                value    => [qw( test array2 )],
            },
        },
        {
            name    => "array - pop",
            args    => [ \@test_array ],
            actions => sub {
                pop @test_array;
            },
            expected => {
                stdout   => $regex->{array}{pop},
                variable => \@test_array,
                value    => [qw( test )],
            },
        },
        {
            name    => "array - undef",
            args    => [ \@test_array ],
            actions => sub {
                undef @test_array;
            },
            expected => {
                stdout   => $regex->{array}{clear},
                variable => \@test_array,
                value    => [qw( )],
            },
        },
    )
}

sub _define_cases_array_clone {
    (
        {
            name    => "array full clone",
            args    => [ \@test_array, ],
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $clone->[1]    = "cloned_array";
                $test_array[1] = 'array2';
            },
            expected => {
                stdout   => $regex->{array}{clone},
                variable => \@test_array,
                value    => [qw( test array2 )],
                clone    => [qw( test cloned_array )],
            },
        },
        {
            name    => "array full clone, lv=1",
            args    => [ \@test_array, 1, ],
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $clone->[1]    = "cloned_array";
                $test_array[1] = 'array2';
            },
            expected => {
                stdout   => $regex->{array}{clone1},
                variable => \@test_array,
                value    => [qw( test array2 )],
                clone    => [qw( test cloned_array )],
            },
        },
    )
}

sub _define_cases_array_no_clone {
    (
        {
            name    => "array full no clone",
            args    => [ \@test_array, -clone => 0 ],
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $clone->[1]    = "cloned_array";
                $test_array[1] = 'array2';
            },
            expected => {
                stdout   => $regex->{array}{basic},
                variable => \@test_array,
                value    => [qw( test array2 )],
                clone    => [qw( test cloned_array )],
            },
        },
        {
            name    => "array full no clone, lv=1",
            args    => [ \@test_array, 1, -clone => 0 ],
            actions => sub {
                $clone         = Storable::dclone( \@test_array );
                $clone->[1]    = "cloned_array";
                $test_array[1] = 'array2';
            },
            expected => {
                stdout   => $regex->{array}{basic1},
                variable => \@test_array,
                value    => [qw( test array2 )],
                clone    => [qw( test cloned_array )],
            },
        },
    )
}

sub _define_cases_array_element {
    (
        # This one is a bit tricky:
        # - Before the first case begins, a reference is taken to an element
        #   in the array.
        # - But then at the end of each case, @test_array is reset.
        #   \$test_array[1] may point to a reference that no longer really
        #   is there (at least logically).
        # - So either update _reset_vars to not wipe a struct (probably not
        #   a good idea).
        # - Or Dynamically create the args (with sub {}).
        {
            name    => "array element - update",
            args    => sub { [ \$test_array[1] ] },
            actions => sub {
                $test_array[1] = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{basic},
                variable => \@test_array,
                value    => [qw( test scalar2 )],
            },
        },
        {
            name    => "array element - update again",
            args    => sub { [ \$test_array[1] ] },
            actions => sub {
                $test_array[1] = 'scalar3';
            },
            expected => {
                stdout   => $regex->{scalar}{basic_mod},
                variable => \@test_array,
                value    => [qw( test scalar3 )],
            },
        },

        # No effect since bound to scalar.
        # Can only STORE/FETCH.
        {
            name    => "array element - pop (no output)",
            args    => sub { [ \$test_array[1] ] },
            actions => sub {
                pop @test_array;
            },
            expected => {
                stdout   => $regex->{empty},
                variable => \@test_array,
                value    => [qw( test )],
            },
        },
        {
            name    => "array element - undef (no output)",
            args    => sub { [ \$test_array[1] ] },
            actions => sub {
                undef @test_array;
            },
            expected => {
                stdout   => $regex->{empty},
                variable => \@test_array,
                value    => [qw( )],
            },
        },
    )
}

# Hash
sub _define_cases_hash_basic {
    (
        {
            name    => "hash",
            args    => [ \%test_hash, ],
            actions => sub {
                $test_hash{test} = 'hash2';
            },
            expected => {
                stdout   => $regex->{hash}{basic},
                variable => \%test_hash,
                value    => {qw( test hash2 )},
            },
        },
        {
            name => "hash -var",
            args => [
                -var => \%test_hash,
            ],
            actions => sub {
                $test_hash{test} = 'hash2';
            },
            expected => {
                stdout   => $regex->{hash}{basic},
                variable => \%test_hash,
                value    => {qw( test hash2 )},
            },
        },
        {
            name    => "hash 1",
            args    => [ \%test_hash, 1, ],
            actions => sub {
                $test_hash{test} = 'hash2';
            },
            expected => {
                stdout   => $regex->{hash}{basic1},
                variable => \%test_hash,
                value    => {qw( test hash2 )},
            },
        },
        {
            name => "hash -levels 1",
            args => [
                \%test_hash, -levels => 1,
            ],
            actions => sub {
                $test_hash{test} = 'hash2';
            },
            expected => {
                stdout   => $regex->{hash}{basic1},
                variable => \%test_hash,
                value    => {qw( test hash2 )},
            },
        },
        {
            name => "hash -levels 1 -var",
            args => [
                -var    => \%test_hash,
                -levels => 1,
            ],
            actions => sub {
                $test_hash{test} = 'hash2';
            },
            expected => {
                stdout   => $regex->{hash}{basic1},
                variable => \%test_hash,
                value    => {qw( test hash2 )},
            },
        },
        {
            name    => "hash - delete key",
            args    => [ \%test_hash ],
            actions => sub {
                delete $test_hash{test};
            },
            expected => {
                stdout   => $regex->{hash}{delete},
                variable => \%test_hash,
                value    => {},
            },
        },
        {
            name    => "hash - undef",
            args    => [ \%test_hash ],
            actions => sub {
                undef %test_hash;
            },
            expected => {
                stdout   => $regex->{hash}{clear},
                variable => \%test_hash,
                value    => {},
            },
        },
    )
}

sub _define_cases_hash_clone {
    (
        {
            name    => "hash full clone",
            args    => [ \%test_hash, ],
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_hash";
                $test_hash{test} = 'hash2';
            },
            expected => {
                stdout   => $regex->{hash}{clone},
                variable => \%test_hash,
                value    => {qw( test hash2 )},
                clone    => {qw( test cloned_hash )},
            },
        },
        {
            name    => "hash full clone, lv=1",
            args    => [ \%test_hash, 1, ],
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_hash";
                $test_hash{test} = 'hash2';
            },
            expected => {
                stdout   => $regex->{hash}{clone1},
                variable => \%test_hash,
                value    => {qw( test hash2 )},
                clone    => {qw( test cloned_hash )},
            },
        },
    )
}

sub _define_cases_hash_no_clone {
    (
        {
            name    => "hash full no clone",
            args    => [ \%test_hash, -clone => 0 ],
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_hash";
                $test_hash{test} = 'hash2';
            },
            expected => {
                stdout   => $regex->{hash}{basic},
                variable => \%test_hash,
                value    => {qw( test hash2 )},
                clone    => {qw( test cloned_hash )},
            },
        },
        {
            name    => "hash full no clone, lv=1",
            args    => [ \%test_hash, 1, -clone => 0 ],
            actions => sub {
                $clone           = Storable::dclone( \%test_hash );
                $clone->{test}   = "cloned_hash";
                $test_hash{test} = 'hash2';
            },
            expected => {
                stdout   => $regex->{hash}{basic1},
                variable => \%test_hash,
                value    => {qw( test hash2 )},
                clone    => {qw( test cloned_hash )},
            },
        },
    )
}

sub _define_cases_hash_element {
    (
        # This one is a bit tricky:
        # - Before the first case begins, a reference is taken to an element
        #   in the hash.
        # - But then at the end of each case, @test_hash is reset.
        #   \$test_hash{test} may point to a reference that no longer really
        #   is there (at least logically).
        # - So either update _reset_vars to not wipe a struct (probably not
        #   a good idea).
        # - Or Dynamically create the args (with sub {}).
        {
            name    => "hash element - update",
            args    => sub { [ \$test_hash{test} ] },
            actions => sub {
                $test_hash{test} = 'scalar2';
            },
            expected => {
                stdout   => $regex->{scalar}{basic},
                variable => \%test_hash,
                value    => {qw( test scalar2 )},
            },
        },
        {
            name    => "hash element - update again",
            args    => sub { [ \$test_hash{test} ] },
            actions => sub {
                $test_hash{test} = 'scalar3';
            },
            expected => {
                stdout   => $regex->{scalar}{basic_mod},
                variable => \%test_hash,
                value    => {qw( test scalar3 )},
            },
        },

        # No effect since bound to scalar.
        # Can only STORE/FETCH.
        {
            name    => "hash element - delete (no output)",
            args    => sub { [ \$test_hash{test} ] },
            actions => sub {
                delete $test_hash{test};
            },
            expected => {
                stdout   => $regex->{empty},
                variable => \%test_hash,
                value    => {},
            },
        },
        {
            name    => "hash element - undef (no output)",
            args    => sub { [ \$test_hash{test} ] },
            actions => sub {
                undef %test_hash;
            },
            expected => {
                stdout   => $regex->{empty},
                variable => \%test_hash,
                value    => {},
            },
        },
    )
}

sub _define_cases_hash_basic_old {
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

sub _define_cases_hash_clone_old {
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

sub _define_cases_hash_no_clone_old {
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

# Complex
sub _define_cases_complex {
    (

        # Full.
        {
            name     => "complex - watch full - no change",
            args     => sub { [$test_complex] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "complex - watch full - firstname",
            args    => sub { [$test_complex] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "complex - watch full - firstname 1",
            args    => sub { [ $test_complex, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # Partial.
        {
            name     => "complex - watch partial - no change",
            args     => sub { [ $test_complex->{authors} ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "complex - watch partial - firstname",
            args    => sub { [ $test_complex->{authors} ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "complex - watch partial - firstname 1",
            args    => sub { [ $test_complex->{authors}, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # Single node.
        {
            name     => "complex - watch single - no change",
            args     => sub { [ \$test_complex->{authors}[0]{first} ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "complex - watch single - firstname",
            args    => sub { [ \$test_complex->{authors}[0]{first} ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{scalar}{firstname},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "complex - watch single - firstname 1",
            args    => sub { [ \$test_complex->{authors}[0]{first}, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{scalar}{firstname1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
    )
}

# Location
sub _define_cases_other_location {
    (

        # Full.
        {
            name     => "location - watch full - firstname",
            args     => sub { [$test_complex] },
            actions  => _dummy_update_firstname(),
            expected => {
                stdout   => $regex->{hash}{coderef_firstname},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name     => "location - watch full - firstname 1",
            args     => sub { [ $test_complex, 1 ] },
            actions  => _dummy_update_firstname(),
            expected => {
                stdout   => $regex->{hash}{firstname1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # Partial.
        {
            name     => "location - watch partial - firstname",
            args     => sub { [ $test_complex->{authors} ] },
            actions  => _dummy_update_firstname(),
            expected => {
                stdout   => $regex->{hash}{coderef_firstname},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name     => "location - watch partial - firstname 1",
            args     => sub { [ $test_complex->{authors}, 1 ] },
            actions  => _dummy_update_firstname(),
            expected => {
                stdout   => $regex->{hash}{firstname1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # Single node.
        {
            name     => "location - watch single - firstname",
            args     => sub { [ \$test_complex->{authors}[0]{first} ] },
            actions  => _dummy_update_firstname(),
            expected => {
                stdout   => $regex->{scalar}{coderef_firstname},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name     => "location - watch single - firstname 1",
            args     => sub { [ \$test_complex->{authors}[0]{first}, 1 ] },
            actions  => _dummy_update_firstname(),
            expected => {
                stdout   => $regex->{scalar}{firstname1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
    )
}

# Raw
sub _define_cases_raw {
    (

        # Full.
        # -NUM
        {
            name     => "raw -3 - watch full - no change",
            args     => sub { [ $test_complex, -3 ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "raw -3 - watch full - firstname",
            args    => sub { [ $test_complex, -3 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "raw -1 - watch full - firstname",
            args    => sub { [ $test_complex, -1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # -NUM -raw 1
        {
            name     => "raw -3 -raw - watch full - no change",
            args     => sub { [ $test_complex, -3, -raw, 1 ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "raw -3 -raw - watch full - firstname",
            args    => sub { [ $test_complex, -3, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "raw -1 -raw - watch full - firstname",
            args    => sub { [ $test_complex, -1, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # NUM -raw 1
        {
            name     => "raw 3 -raw - watch full - no change",
            args     => sub { [ $test_complex, 3, -raw, 1 ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "raw 3 -raw - watch full - firstname",
            args    => sub { [ $test_complex, 3, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "raw 1 -raw - watch full - firstname",
            args    => sub { [ $test_complex, 1, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # Partial.
        # -NUM
        {
            name     => "raw -3 - watch partial - no change",
            args     => sub { [ $test_complex->{authors}, -3 ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "raw -3 - watch partial - firstname",
            args    => sub { [ $test_complex->{authors}, -3 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "raw -1 - watch partial - firstname 1",
            args    => sub { [ $test_complex->{authors}, -1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # -NUM -raw 1
        {
            name     => "raw -3 -raw - watch partial - no change",
            args     => sub { [ $test_complex->{authors}, -3, -raw, 1 ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "raw -3 -raw - watch partial - firstname",
            args    => sub { [ $test_complex->{authors}, -3, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "raw -1 -raw - watch partial - firstname 1",
            args    => sub { [ $test_complex->{authors}, -1, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # NUM -raw 1
        {
            name     => "raw 3 -raw - watch partial - no change",
            args     => sub { [ $test_complex->{authors}, 3, -raw, 1 ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "raw 3 -raw - watch partial - firstname",
            args    => sub { [ $test_complex->{authors}, 3, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "raw 1 -raw - watch partial - firstname 1",
            args    => sub { [ $test_complex->{authors}, 1, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{hash}{firstname_raw1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # Single node.
        # -NUM
        {
            name     => "raw -3 - watch single - no change",
            args     => sub { [ \$test_complex->{authors}[0]{first}, -3 ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name    => "raw -3 - watch single - firstname",
            args    => sub { [ \$test_complex->{authors}[0]{first}, -3 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{scalar}{firstname_raw},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name    => "raw -1 - watch single - firstname",
            args    => sub { [ \$test_complex->{authors}[0]{first}, -1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{scalar}{firstname_raw1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # -NUM -raw 1
        {
            name => "raw -3 -raw - watch single - no change",
            args =>
              sub { [ \$test_complex->{authors}[0]{first}, -3, -raw, 1 ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name => "raw -3 -raw - watch single - firstname",
            args =>
              sub { [ \$test_complex->{authors}[0]{first}, -3, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{scalar}{firstname_raw},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name => "raw -1 -raw - watch single - firstname",
            args =>
              sub { [ \$test_complex->{authors}[0]{first}, -1, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{scalar}{firstname_raw1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },

        # NUM -raw 1
        {
            name => "raw 3 -raw - watch single - no change",
            args => sub { [ \$test_complex->{authors}[0]{first}, 3, -raw, 1 ] },
            expected => {
                stdout   => $regex->{empty},
                variable => $test_complex,
                value    => _define_complex_base_value(),
            },
        },
        {
            name => "raw 3 -raw - watch single - firstname",
            args => sub { [ \$test_complex->{authors}[0]{first}, 3, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{scalar}{firstname_raw},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
        {
            name => "raw 1 -raw - watch single - firstname",
            args => sub { [ \$test_complex->{authors}[0]{first}, 1, -raw, 1 ] },
            actions => sub {
                $test_complex->{authors}[0]{first} = 'Charly';
            },
            expected => {
                stdout   => $regex->{scalar}{firstname_raw1},
                variable => sub { $test_complex },
                value    => sub {
                    my $val = _define_complex_base_value();
                    $val->{authors}[0]{first} = "Charly";
                    $val;
                },
            },
        },
    )
}

my @cases = (

    # User Errors
    _define_cases_stack_trace(),

    # Scalar
    _define_cases_scalar_basic(),
    _define_cases_scalar_clone(),
    _define_cases_scalar_no_clone(),

    # Array
    _define_cases_array_basic(),
    _define_cases_array_clone(),
    _define_cases_array_no_clone(),
    _define_cases_array_element(),

    # Hash
    _define_cases_hash_basic(),
    _define_cases_hash_clone(),
    _define_cases_hash_no_clone(),
    _define_cases_hash_element(),

    # Complex
    _define_cases_complex(),

    # Location
    _define_cases_other_location(),

    # Raw
    _define_cases_raw(),
);

###########################################
#            Test Case Support
###########################################

sub _run {
    my ( $code, $expect_return ) = @_;
    $expect_return //= 1;
    my $output = "";
    my @return;

    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, ">",  \$output or die $!;
        open STDERR, ">>", \$output or die $!;

        # Test effects of wantarray.
        if ( $expect_return ) {
            @return = eval { $code->() };
        }
        else {
            eval { $code->() };
        }
    }

    chomp $output;

    ( $output, @return );
}

sub _test_tie {
    my ( $case ) = @_;

    # Setup trace.
    my $args = $case->{args} // [];
    $args = $args->() if ref( $args ) eq "CODE";
    say "args: $args" if $case->{debug};

    # Tie the reference and compare output.
    my ( $stdout, @refs ) = _run( sub { Trace( @$args ) } );
    is( $stdout, "", "$case->{name} - stdout", );
    say "trace stdout: [$stdout]" if $case->{debug};

    # Should have tied references by now.
    ok scalar @refs, "$case->{name} - Got tied references";

    # Run actions.
    if ( $case->{actions} ) {
        ( $stdout ) = _run( sub { $case->{actions}->( $case ) } );
        say "action stdout: [$stdout]" if $case->{debug};
    }

    # Check STDOUT.
    if ( exists $case->{expected}{stdout} ) {
        my $expected = $case->{expected}{stdout};

        ok defined( $expected ), "$case->{name} - expected stdout is defined";

        if ( ref( $expected ) ne "Regexp" ) {
            $expected = qr{ ^ $expected $ }x;
            say "make regexp";
        }
        like( $stdout, $expected, "$case->{name} - action stdout", );
    }

    # Check for variable values afterwards.
    if ( $case->{expected}{variable} ) {
        my $var = $case->{expected}{variable};
        my $val = $case->{expected}{value};

        for ( $var, $val ) {
            $_ = $_->() if ref() eq "CODE";
        }

        is_deeply( $var, $val, "$case->{name} - value", );
    }

    # Check for clone values afterwards (if any).
    if ( exists $case->{expected}{clone} ) {
        is_deeply( $clone, $case->{expected}{clone}, "$case->{name} - clone", );
    }

    # Cleanup for the next call.
    for my $ref ( @refs ) {
        say "Removing: $ref" if $case->{debug};
        $ref->Unwatch();
    }
    _reset_vars();
}

sub _test_trace_only {
    my ( $case ) = @_;

    # Setup trace.
    my $args = $case->{args} // [];

    # Run the command with wantarray undef.
    my ( $stdout_noret, $return_noret ) =
      _run( sub { Data::Trace::Trace( @$args ) }, 0, );

    # Run the command with wantarray defined.
    my ( $stdout_ret, $return_ret ) =
      _run( sub { Data::Trace::Trace( @$args ) } );

    like(
        $stdout_noret,
        $case->{expected}{stdout},
        "$case->{name} - stdout_noret",
    );

    is( $return_noret, undef, "$case->{name} - return_noret", );

    is( $stdout_ret, "", "$case->{name} - stdout_ret", );

    like(
        $return_ret,
        $case->{expected}{stdout},
        "$case->{name} - return_ret",
    );
}


###########################################
#               Test It
###########################################

for my $case ( @cases ) {
    $case->{debug} //= 0;
    say "\ncase: " . Dumper( $case ) if $case->{debug} >= 2;

    # Compare stdout and return when using wantarray.
    if ( $case->{expected}{variable} ) {
        _test_tie( $case );
    }
    else {
        _test_trace_only( $case );
    }

    last if $case->{debug};
}

done_testing();
