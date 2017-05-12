#
# $Id: 01-hash.t,v 0.1 2006/12/22 22:47:49 dankogai Exp $
#
use strict;
use warnings;
use Attribute::Tie;
#use Test::More tests => 1;
use Test::More qw/no_plan/;
{
    package Tie::EchoHash;
    use base 'Tie::Hash';
    sub TIEHASH{ bless { }, shift; }
    sub FETCH{ $_[1] }
}

my %hash : Tie('EchoHash');
ok tied(%hash), q{my %hash : Tie('LenHash')};
is $hash{'key'}, 'key', q($hash{'key'} == ) . $hash{'key'};
eval{
    $hash{'key'} = 'value';
};
ok $@, $@;
eval{
    my %nohash : Tie('__NONE__');
};
ok $@, $@;
eval{
    use Fcntl;   # For O_RDWR, O_CREAT, etc.
    my %sdbm : Tie('SDBM_File', './_none_/db', O_RDWR|O_CREAT, 0666);
};
ok $@, $@;

