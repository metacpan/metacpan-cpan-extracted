######################################################################
#
# 1006_ioget.t
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
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2\n\x82\xA4\x82\xA6\n\x82\xA8\x82\xA9\n"; close(FH); open(FH,'a');   my $got = ioget(FH); close(FH);   unlink('a');  $got  eq "あい\n"               },
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2\n\x82\xA4\x82\xA6\n\x82\xA8\x82\xA9\n"; close(FH); open(FH,'a');   my @got = ioget(FH); close(FH);   unlink('a'); "@got" eq "あい\n うえ\n おか\n" },
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2\n\x82\xA4\x82\xA6\n\x82\xA8\x82\xA9\n"; close(FH); open(ARGV,'a'); my $got = ioget();   close(ARGV); unlink('a');  $got  eq "あい\n"               },
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2\n\x82\xA4\x82\xA6\n\x82\xA8\x82\xA9\n"; close(FH); open(ARGV,'a'); my @got = ioget();   close(ARGV); unlink('a'); "@got" eq "あい\n うえ\n おか\n" },
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
