package Test::Class::Business::DK::Postalcode;

# $Id$

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Tree::Simple;
use Test::Exception;
use Env qw($TEST_VERBOSE);
use utf8;

sub startup : Test(startup => 1) {
    my $self = shift;

    use_ok( 'Business::DK::Postalcode', qw(validate_postalcode get_all_postalcodes get_all_cities create_regex get_all_data get_city_from_postalcode get_postalcode_from_city) );
};

sub test_get_postalcode_from_city : Test(3) {
    ok(my @postalcodes = get_postalcode_from_city('Vallensbæk Strand'), 'get_city_from_postalcode');

    is((scalar @postalcodes), 1, 'asserting number of postalcodes');

    dies_ok { get_postalcode_from_city(); } 'get_postalcode_from_city';
}

sub test_get_city_from_postalcode : Test(3) {
    is('København S', get_city_from_postalcode(2300), 'get_city_from_postalcode');
    is('', get_city_from_postalcode(2301), 'get_city_from_postalcode');
    dies_ok { get_city_from_postalcode(); } 'get_city_from_postalcode';
}

sub test_get_all_cities : Test(2) {
    ok(my $cities_ref = get_all_cities(), 'calling get all cities');
    is(scalar(@{$cities_ref}), 1285), 'asserting number of cities';
}

sub test_get_all_postalcodes_with_param : Test(2) {
    ok(my $postalcodes_ref = get_all_postalcodes([qw(2300 2665)]), 'calling get all postalcodes');
    is(scalar(@{$postalcodes_ref}), 2), 'asserting number of postalcodes';
}

sub test_get_all_postalcodes : Test(2) {
    ok(my $postalcodes_ref = get_all_postalcodes(), 'calling get all postalcodes');
    is(scalar(@{$postalcodes_ref}), 1285), 'asserting number of postalcodes';
}

sub test_get_all_data : Test(2) {
    ok(my $postalcodes_ref = get_all_data(), 'calling get_all_data');
    is(scalar(@{$postalcodes_ref}), 1285, 'asserting number of postalcodes');
}

sub test_retrieve_postalcode : Test(2) {
    my @postalcodes = ();
    ok(Business::DK::Postalcode::_retrieve_postalcode(\@postalcodes, "0555\tScanning\tData Scanning A/S\tTrue\t1\n"), 'calling _retrieve_postalcode');
    is(scalar @postalcodes, 1, 'asserting number of postalcodes');
}

sub test_retrieve_postalcode_with_empty_data : Test(1) {
    my @postalcodes = ();
    dies_ok { Business::DK::Postalcode::_retrieve_postalcode(\@postalcodes, ''); }, 'feeding with empty data';
}

sub test_retrieve_postalcode_with_bad_data : Test(2) {
    my @postalcodes = ();
    ok(Business::DK::Postalcode::_retrieve_postalcode(\@postalcodes, 'BAD DATA'), 'feeding with bad data');
    is(scalar @postalcodes, 0, 'asserting number of postalcodes');
}

sub test_retrieve_postalcode_with_no_data : Test(1) {
    my @postalcodes = ();
    dies_ok { Business::DK::Postalcode::_retrieve_postalcode(\@postalcodes); }, 'feeding with no data';
}

sub test_validate : Test(5) {
    my $self = shift;

    my @invalids = qw();
    my @valids = qw();

    foreach (1 .. 9999) {
        my $number = sprintf '%04d', $_;
        if (not validate_postalcode($number)) {
            push @invalids, $number;
        } else {
            push @valids, $number;
        }
    }

    is(scalar @invalids, 8808);
    is(scalar @valids, 1191);
}

sub test_create_regex : Test(3695) {
    my $postalcodes = get_all_postalcodes();
    my $regex = create_regex($postalcodes);

    foreach my $postalcode (@{$postalcodes}) {
        ok($postalcode =~ m/$$regex/cg, "$postalcode tested");
    }
};

sub test_build_tree : Test(1293) {

    my $tree = Tree::Simple->new();

    ok(Business::DK::Postalcode::_build_tree($tree, 4321));

    is($tree->size, 5);

    if ($TEST_VERBOSE) {
        $tree->traverse(sub {
            my ($_tree) = @_;
            print (("\t" x $_tree->getDepth()), $_tree->getNodeValue(), "\n");
        });
    }

    $tree = Tree::Simple->new();

    my @data = qw(0800 0500 0911 0577);
    foreach my $postalcode (@data) {
        ok(Business::DK::Postalcode::_build_tree($tree, $postalcode));
    }

    is($tree->size, 13);

    if ($TEST_VERBOSE) {
        $tree->traverse(sub {
            my ($_tree) = @_;
            print (("\t" x $_tree->getDepth()), $_tree->getNodeValue(), "\n");
        });
    }

    $tree = Tree::Simple->new();

    my $postalcodes = Business::DK::Postalcode::get_all_postalcodes();

    foreach my $postalcode (@{$postalcodes}) {
        ok(Business::DK::Postalcode::_build_tree($tree, $postalcode));
    }

    $tree = Tree::Simple->new();
    dies_ok { Business::DK::Postalcode::_build_tree($tree, 'BADDATA'); } 'test with bad data';
};

1;
