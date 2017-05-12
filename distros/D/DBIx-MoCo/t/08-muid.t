#!perl -w
use strict;
use warnings;
use File::Spec;

use lib File::Spec->catdir('t', 'lib');

ThisTest->runtests;

# ThisTest
package ThisTest;
use base qw/Test::Class/;
use Test::More;
use DBIx::MoCo::MUID;

sub muid : Tests {
    my $muid = DBIx::MoCo::MUID->create_muid;
    ok ($muid, 'muid');
    ok ($muid =~ /^\d+$/, 'is digit');
    ok ($muid < 2 ** 64, 'less than 2 ** 64');
    # ok ($muid > 2 ** 63, 'greater than 2 ** 63');
    ok ($muid > 2 ** 63, 'greater than 2 ** 56');
    my $muid2 = create_muid();
    ok ($muid2, 'muid2');
    ok ($muid2 =~ /^\d+$/, 'is digit');
    ok ($muid2 < 2 ** 64, 'less than 2 ** 64');
    # ok ($muid2 > 2 ** 63, 'greater than 2 ** 63');
    ok ($muid2 > 2 ** 63, 'greater than 2 ** 56');
    ok ($muid ne $muid2, '1 ne 2');
    my $muid3 = create_muid();
    ok ($muid ne $muid3, '1 ne 3');
    ok ($muid2 ne $muid3, '2 ne 3');
}

sub lopnor : Tests {
    return;
    my $addr = '10.0.12.34';
    my $addr2 = join('.',map{oct("0b$_")} (sprintf('%032s',substr(Math::BigInt->new('0b'.join('',map{sprintf('%08b',$_)} split(/\./,$addr)))->binc->as_bin,2)) =~ /[01]{8}/g));
    warn $addr2;
}

1;
