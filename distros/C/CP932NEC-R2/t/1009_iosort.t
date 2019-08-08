######################################################################
#
# 1009_iosort.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CP932NEC::R2;
use vars qw(@test);

@test = (
# 1
    sub { join('',   sort(qw( 一 二 三 四 五 六 七 八 九 ))) eq '一七三九二五八六四' },
    sub { join('', iosort(qw( 一 二 三 四 五 六 七 八 九 ))) eq '一九五三四七二八六' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
