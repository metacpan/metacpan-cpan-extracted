######################################################################
#
# 1002_mbeach.t
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

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\AUse of implicit split to \@_ is deprecated at /   ? return :
        /\AUse of uninitialized value at /                   ? return :
        /\AUse of uninitialized value in join or string at / ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub { $_='ABCDE'; my @r=split(//);    "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=split(//,$_); "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=mbeach();     "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=mbeach($_);   "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=mbeach();     "@r" eq "A B C D E"  },
    sub { $_='ABCDE'; my @r=mbeach($_);   "@r" eq "A B C D E"  },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub {              $_='ABCDE'; my $r=split(//);    $r == 5 },
    sub {              $_='ABCDE'; my $r=split(//,$_); $r == 5 },
    sub { local $^W=0; $_='ABCDE'; my $r=mbeach();     $r == 5 },
    sub { local $^W=0; $_='ABCDE'; my $r=mbeach($_);   $r == 5 },
    sub { local $^W=0; $_='ABCDE'; my $r=mbeach();     $r == 5 },
    sub { local $^W=0; $_='ABCDE'; my $r=mbeach($_);   $r == 5 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { $_='AあBｱｲうえC'; my @r=mbeach();     "@r" eq "A あ B ｱ ｲ う え C" },
    sub { $_='AあBｱｲうえC'; my @r=mbeach($_);   "@r" eq "A あ B ｱ ｲ う え C" },
    sub { $_='AあBｱｲうえC'; my @r=mbeach();     "@r" eq "A あ B ｱ ｲ う え C" },
    sub { $_='AあBｱｲうえC'; my @r=mbeach($_);   "@r" eq "A あ B ｱ ｲ う え C" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { local $^W=0; $_='AあBｱｲうえC'; my $r=mbeach();     $r == 8 },
    sub { local $^W=0; $_='AあBｱｲうえC'; my $r=mbeach($_);   $r == 8 },
    sub { local $^W=0; $_='AあBｱｲうえC'; my $r=mbeach();     $r == 8 },
    sub { local $^W=0; $_='AあBｱｲうえC'; my $r=mbeach($_);   $r == 8 },
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
