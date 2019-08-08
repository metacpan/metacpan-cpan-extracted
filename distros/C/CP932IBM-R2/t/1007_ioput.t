######################################################################
#
# 1007_ioput.t
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
    sub { open(FH,'>a');                                     ioput(FH,"あい\n"); close(FH);                  open(FH,'a'); my $got = <FH>; close(FH); unlink('a'); $got eq "\x82\xA0\x82\xA2\n" },
    sub { open(FH,'>a'); $_="あい\n";                        ioput(FH);          close(FH);                  open(FH,'a'); my $got = <FH>; close(FH); unlink('a'); $got eq "\x82\xA0\x82\xA2\n" },
    sub { open(FH,'>a');              my $select=select(FH); ioput("あい\n");    close(FH); select($select); open(FH,'a'); my $got = <FH>; close(FH); unlink('a'); $got eq "\x82\xA0\x82\xA2\n" },
    sub { open(FH,'>a'); $_="あい\n"; my $select=select(FH); ioput();            close(FH); select($select); open(FH,'a'); my $got = <FH>; close(FH); unlink('a'); $got eq "\x82\xA0\x82\xA2\n" },
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
