#!perl

use warnings;
use strict;

use Test::More;

use App::podweaver;

plan tests => 5;

my $dist_info = App::podweaver->get_dist_info();

#
#  1:  Was the meta parsed?
isa_ok( $dist_info->{ meta }, 'CPAN::Meta',
    "META file found" );

#
#  2:  Authors extracted?
is_deeply( $dist_info->{ authors },
    [ q~Sam Graham <libapp-podweaver-perl@illusori.co.uk>~ ],
    "authors extracted" );

#
#  3:  License extracted?
isa_ok( $dist_info->{ license }, 'Software::License::Perl_5',
    "license extracted" );

#
#  4:  Dist version set.
ok( defined( $dist_info->{ dist_version } ),
    "dist_version populated" );


$dist_info = App::podweaver->get_dist_info(
    antispam => 'BLAHBLAH',
    );

#
#  5:  Antispam applied?
is_deeply( $dist_info->{ authors },
    [ q~Sam Graham <libapp-podweaver-perl BLAHBLAH illusori.co.uk>~ ],
    "antispam option applied" );
