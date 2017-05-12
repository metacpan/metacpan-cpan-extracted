package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::Coord::ECI::TLE;
use Astro::Coord::ECI::TLE::Set;
use Astro::Coord::ECI::Utils qw{ :time };
use My::Module::Test qw{ :tolerance format_time };
use My::Module::SetDelegate;
use Test::More 0.88;

sub choose_epoch (@);
sub compare_times (@);
sub insert (@);

{
    my $set = Astro::Coord::ECI::TLE::Set->new();

    insert $set, time_gm( 0, 0, 0, 2, 6, 2006 ), 99999, 'Anonymous',
	'Add first member';

    insert $set, time_gm( 0, 0, 0, 4, 6, 2006 ), 99999, 'Anonymous',
	'Add second member';

    choose_epoch $set, select => time_gm( 0, 0, 0, 1, 6, 2006 ),
	time_gm( 0, 0, 0, 2, 6, 2006 ),
	'Select epoch before first member';

    choose_epoch $set, select => time_gm( 0, 0, 0, 2, 6, 2006 ),
	time_gm( 0, 0, 0, 2, 6, 2006 ),
	'Select epoch of first member';

    choose_epoch $set, select => time_gm( 0, 0, 0, 3, 6, 2006 ),
	time_gm( 0, 0, 0, 2, 6, 2006 ),
	'Select epoch between first and second member';

    choose_epoch $set, select => time_gm( 0, 0, 0, 4, 6, 2006 ),
	time_gm( 0, 0, 0, 4, 6, 2006 ),
	'Select epoch of second member';

    choose_epoch $set, select => time_gm( 0, 0, 0, 5, 6, 2006 ),
	time_gm( 0, 0, 0, 4, 6, 2006 ),
	'Select epoch after second member';

    my $time = time_gm( 0, 0, 0, 1, 6, 2006 );
    my $tle = $set->universal( $time );

    compare_times $tle->get( 'epoch' ), time_gm( 0, 0, 0, 2, 6, 2006 ),
	'Setting time before first member returns first member';

    compare_times $tle->universal(), $time,
	q{Member's time is original time set};

    compare_times $set->universal(), $time,
	q{Set's time is original time set};

    $time = time_gm( 0, 0, 0, 2, 6, 2006 );
    $tle = $set->universal( $time );

    compare_times $tle->get( 'epoch' ), time_gm( 0, 0, 0, 2, 6, 2006 ),
	'Setting time of first member returns first member';

    compare_times $tle->universal(), $time,
	q{Member's time is original time set};

    compare_times $set->universal(), $time,
	q{Set's time is original time set};

    $time = time_gm( 0, 0, 0, 3, 6, 2006 );
    $tle = $set->universal( $time );

    compare_times $tle->get( 'epoch' ), time_gm( 0, 0, 0, 2, 6, 2006 ),
	'Setting time between members returns first member';

    compare_times $tle->universal(), $time,
	q{Member's time is original time set};

    compare_times $set->universal(), $time,
	q{Set's time is original time set};

    $time = time_gm( 0, 0, 0, 4, 6, 2006 );
    $tle = $set->universal( $time );

    compare_times $tle->get( 'epoch' ), time_gm( 0, 0, 0, 4, 6, 2006 ),
	'Setting time of second member returns second member';

    compare_times $tle->universal(), $time,
	q{Member's time is original time set};

    compare_times $set->universal(), $time,
	q{Set's time is original time set};

    $time = time_gm( 0, 0, 0, 5, 6, 2006 );
    $tle = $set->universal( $time );

    compare_times $tle->get( 'epoch' ), time_gm( 0, 0, 0, 4, 6, 2006 ),
	'Setting time after second member returns second member';

    compare_times $tle->universal(), $time,
	q{Member's time is original time set};

    compare_times $set->universal(), $time,
	q{Set's time is original time set};

    my @members = $set->members();

    cmp_ok scalar @members, '==', 2,
    'Retrieved two members from set';

    eval {
	$set->set( name => 'Nemo' );
	pass q{Set name to 'Nemo'};
    } or fail "Set name to 'Nemo': $@";

    SKIP: {

	@members
	    or skip '$set->members() returned no members', 4;

	is $members[0]->get( 'name' ), 'Nemo',
	    q{First member's name should be 'Nemo'};

	compare_times $members[0]->get( 'epoch' ),
	    time_gm( 0, 0, 0, 2, 6, 2006 ),
	    q{First member's epoch should be July 2 2006};

	@members > 1
	    or skip '$set->members() only returned 1 member', 2;

	is $members[1]->get( 'name' ), 'Nemo',
	    q{Second member's name should be 'Nemo'};

	compare_times $members[1]->get( 'epoch' ),
	    time_gm( 0, 0, 0, 4, 6, 2006 ),
	    q{Second member's epoch should be July 4 2006};
    }

    $set->clear();

    cmp_ok scalar $set->members(), '==', 0,
	'After clear, set has no members';
}

{

    local $Astro::Coord::ECI::TLE::Set::Singleton = 0;

    my @set;
    eval {
	@set = Astro::Coord::ECI::TLE::Set->aggregate(
	    dummy( time_gm( 0, 0, 0, 1, 6, 2006 ), 99999 ),
	    dummy( time_gm( 0, 0, 0, 2, 6, 2006 ) ),
	    dummy( time_gm( 0, 0, 0, 1, 6, 2006 ), 11111 ),
	);
	pass 'Aggregate TLEs without singletons';
	1;
    } or fail "Aggregate TLEs without singletons: $@";

    cmp_ok scalar @set, '==', 2,
    'Number of objects produced by aggregate()';

    is ref $set[0], 'Astro::Coord::ECI::TLE',
	'Object 0 is an Astro::Coord::ECI::TLE';

    is ref $set[1], 'Astro::Coord::ECI::TLE::Set',
	'Object 1 is an Astro::Coord::ECI::TLE::Set';

}

{

    local $Astro::Coord::ECI::TLE::Set::Singleton = 1;

    my @set;
    eval {
	@set = Astro::Coord::ECI::TLE::Set->aggregate(
	    dummy( time_gm( 0, 0, 0, 1, 6, 2006 ), 99999 ),
	    dummy( time_gm( 0, 0, 0, 2, 6, 2006 ) ),
	    dummy( time_gm( 0, 0, 0, 1, 6, 2006 ), 11111 ),
	);
	pass 'Aggregate TLEs with singletons';
	1;
    } or fail "Aggregate TLEs with singletons: $@";

    cmp_ok scalar @set, '==', 2,
    'Number of objects produced by aggregate()';

    is ref $set[0], 'Astro::Coord::ECI::TLE::Set',
	'Object 0 is an Astro::Coord::ECI::TLE::Set';

    is ref $set[1], 'Astro::Coord::ECI::TLE::Set',
	'Object 1 is an Astro::Coord::ECI::TLE::Set';

}

{	# Begin local symbol block.

    my $set1 = Astro::Coord::ECI::TLE::Set->new(
	My::Module::SetDelegate->new(
	    id => 99999,
	    name => 'Anonymous',
	    epoch => time_gm( 0, 0, 0, 1, 6, 2006 )
	)
    );
    my $set2 = Astro::Coord::ECI::TLE::Set->new();

    $set2->add( $set1 );

    cmp_ok scalar $set2->members(), '==', 1,
	'Add a set to another set';
}	# End local symbol block.

{	# Begin local symbol block.
    my $set = Astro::Coord::ECI::TLE::Set->new(
	My::Module::SetDelegate->new(
	    id => 22222,
	    name => 'Anonymous',
	    epoch => time_gm( 0, 0, 0, 2, 6, 2006 ),
	)
    );

    is ref $set->delegate(), 'My::Module::SetDelegate',
	'Delegation of delegate() to the TLE object';

    is ref $set->nodelegate(), 'Astro::Coord::ECI::TLE::Set',
	'Method nodelegate() handled by the set object';

}	# End of local symbol block.

{	# Begin local symbol block.
    my $set = Astro::Coord::ECI::TLE::Set->new ();

    ok $set->can( 'members' ),
	'Empty set has a members() method';

    ok ! $set->can( 'delegate' ),
	'Empty set has no delegate() method';

    $set->add( My::Module::SetDelegate->new(
	    id => 333333,
	    name => 'Nobody',
	    epoch => time_gm( 0, 0, 0, 2, 6, 2006 ),
	)
    );

    ok $set->can( 'members' ),
	'Non-empty set has a members() method';

    ok $set->can( 'delegate' ),
	'Non-empty set has a delegate() method';

    $set->clear();

    ok $set->can( 'members' ),
	'Cleared set still has a members() method';

    ok ! $set->can( 'delegate' ),
	'Cleared set has no delegate() method';

}	# End of local symbol block.

{
    my $set = Astro::Coord::ECI::TLE::Set->new();

    my $ok = eval {
	$set->represents();
	1;
    };
    ok ! $ok, q{$set->represents() on empty set throws exception};

    $ok = eval {
	$set->represents( 'Astro::Coord::ECI' );
	1;
    };
    ok ! $ok,
    q{$set->represents( 'Astro::Coord::ECI' ) on empty set throws exception};

    $set->add( dummy( time_gm( 0, 0, 0, 6, 1, 2006 ), 99999, 'Nobody' ) );

    is $set->represents(), 'Astro::Coord::ECI::TLE',
    q{$set->represents() on non-empty set returns 'Astro::Coord::ECI::TLE'};

    ok $set->represents( 'Astro::Coord::ECI' ),
    q{$set->represents( 'Astro::Coord::ECI' ) is true};

    ok $set->represents( 'Astro::Coord::ECI::TLE' ),
    q{$set->represents( 'Astro::Coord::ECI::TLE' ) is true};

    ok ! $set->represents( 'Astro::Coord::ECI::TLE::Set' ),
    q{$set->represents( 'Astro::Coord::ECI::TLE::Set' ) is false};

}

done_testing;

sub choose_epoch (@) {
    my ( $set, $method, $epoch, $want, $title ) = @_;
    my $got;
    eval {
	$got = $set->$method( $epoch )->get( 'epoch' );
	1;
    } or do {
	@_ = ( "$title: $@" );
	goto &fail;
    };
    @_ = ( $got, $want, 1, $title, &format_gmt );
    goto &tolerance;
}

sub format_gmt {
    my ( $time ) = @_;
    return format_time( $time ) . ' GMT';
}

sub insert (@) {
    my ( $set, $epoch, $oid, $name, $title ) = @_;
    eval {
	$set->add( dummy( $epoch, $oid, $name ) );
	1;
    } or do {
	@_ = ( "$title: $@" );
	goto &fail;
    };
    @_ = ( $title );
    goto &pass;
}

sub compare_times (@) {
    my ( $got, $want, $title ) = @_;
    @_ = ( $got, $want, 1, $title, \&format_gmt );
    goto &tolerance;
}

########################################################################
#
#	$tle = dummy ($epoch, $id, $name);

#	Make a dummy Astro::Coord::ECI::TLE object. The $id and
#	$name default to the last one used. If none has been
#	specified, the defaults are 99999 and 'Anonymous'.

{	# Local symbol block.

    my ( $id, $name );
    BEGIN {
	( $id, $name ) = ( 99999, 'Anonymous' )
    }

    sub dummy {
	my ( $epoch, $new_id, $new_name ) = @_;
	defined $epoch or die <<'EOD';
Error - You must specify the epoch.
EOD
	defined $new_id and $id = $new_id;
	defined $new_name and $name = $new_name;

	return Astro::Coord::ECI::TLE->new(
	    id => $id,
	    name => $name, 
	    epoch => $epoch,
	    model => 'null'
	);
    }
}	# End of local symbol block.

1;

# ex: set textwidth=72 :
