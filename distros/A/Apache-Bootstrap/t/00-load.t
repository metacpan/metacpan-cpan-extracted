#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

my ( $pkg, $mp1_bootstrap, $mp2_bootstrap, $dual_bootstrap, $skip_all,
    $skip_mp1, $skip_mp2 );

BEGIN {
    $pkg = 'Apache::Bootstrap';
    use_ok($pkg);

    can_ok(
        $pkg, qw( new satisfy_mp_generation _wanted_mp_generation
          check_for_apache_test apache_major_version )
    );

    # try bootstrapping just mp1
    diag("bootstrapping mp1 only");
    $mp1_bootstrap = eval { $pkg->new( { mod_perl => 0 } ) };
    $skip_mp1 = $@ if $@;

  SKIP: {
        skip $skip_mp1, 1 if $skip_mp1;

        isa_ok( $mp1_bootstrap, $pkg );
    }

    # try bootstrapping just mp2
    diag("bootstrapping mp2 only");
    $mp2_bootstrap = eval { $pkg->new( { mod_perl2 => 1.99022 } ) };
    $skip_mp2 = $@ if $@;
  
  SKIP: {
        skip $skip_mp2, 1 if $skip_mp2;

        isa_ok( $mp2_bootstrap, $pkg );
    }

  SKIP: {
        skip "Skipping dual bootstrap", 2 if ( $skip_mp1 or $skip_mp2 );

        $dual_bootstrap =
          eval { $pkg->new( { mod_perl => 0, mod_perl2 => 1.99022 } ); };

        # this should not throw an exception since individual bootstraps worked
        ok( !$@, 'no exception thrown for dual bootstrap: ' . $@ );

        isa_ok( $dual_bootstrap, $pkg );
    }

}

diag("Testing Apache::Bootstrap $Apache::Bootstrap::VERSION, Perl $], $^X");

eval { require Apache::Test };
my $skip = $@ ? 'Apache::Test not installed, skipping test' : undef;

SKIP: {
    skip $skip, 1 if ( $skip or ( !$mp2_bootstrap && !$mp1_bootstrap ) );

    # need a bootstrap object
    my $bootstrap = $dual_bootstrap || $mp2_bootstrap || $mp1_bootstrap;

    my $at_version = $bootstrap->check_for_apache_test(
        $Apache::Test::VERSION + 0.01);

    ok(!$at_version, 'check for non existing a:t version (+0.01)');
}

# delete mod_perl from INC
delete $INC{'mod_perl.pm'};

SKIP: {
    skip 'could not bootstrap mp1, skipping', 1 if !$mp1_bootstrap;

    # test mp1 functions
    my $mp1_version = $mp1_bootstrap->satisfy_mp_generation(1);
    cmp_ok( $mp1_version, '==', 1, 'mod_perl1 present' );

}

SKIP: {
    skip 'could not bootstrap mp1/mp2, skipping', 2 if !$dual_bootstrap;

    # test mp2 functions with dual bootstrap
    my $mp2_version = $dual_bootstrap->satisfy_mp_generation(2);
    cmp_ok( $mp2_version, '==', 2, 'mod_perl2 present' );

    my $mp1_version = $dual_bootstrap->satisfy_mp_generation(1);
    cmp_ok( $mp1_version, '==', 1, 'mod_perl1 present' );

}

delete $INC{'mod_perl.pm'};

SKIP: {
    skip 'could not bootstrap mp2, skipping', 1 if !$mp2_bootstrap;
    my $mp2_version = $mp2_bootstrap->satisfy_mp_generation(2);
    cmp_ok( $mp2_version, '==', 2, 'mod_perl2 present' );
}
