#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use English qw( -no_match_vars );
use File::Find;
use Readonly;

Readonly::Scalar my $min_ver => 5.010;

use Perl::MinimumVersion;

find({ wanted => \&wanted, no_chdir => 1 }, qw( lib t xt ));

sub wanted {
    if ((! -d $File::Find::name) && /\.(t|pm|pl)$/) {
	my $obj = Perl::MinimumVersion->new( $File::Find::name );
	unless (defined $obj) {
	    BAIL_OUT "Cannot get minimum version from ${File::Find::name}";
	}
	ok($obj->minimum_version <= $min_ver,
	   sprintf("%s (%1.6f)", $File::Find::name, $obj->minimum_version)
	);
    }
}

done_testing;
