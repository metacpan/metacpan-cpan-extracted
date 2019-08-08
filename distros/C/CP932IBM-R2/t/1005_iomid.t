######################################################################
#
# 1005_iomid.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CP932IBM::R2;
use vars qw(@test);

@test = (
# 1
    sub {                  iomid('01234',2)               eq '234'                },
    sub {                  iomid('あいうえお',6)          eq 'えお'               },
    sub {                  iomid('01234',2,1)             eq '2'                  },
    sub {                  iomid('あいうえお',6,2)        eq 'え'                 },
    sub { $_='01234';      iomid($_,2,2,'ABCD');       $_ eq '01ABCD4'            },
    sub { $_='あいうえお'; iomid($_,6,2,'かきくけこ'); $_ eq 'あいうかきくけこお' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
