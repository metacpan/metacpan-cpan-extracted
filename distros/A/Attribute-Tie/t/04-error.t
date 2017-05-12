#
# $Id: 04-error.t,v 0.1 2006/12/22 22:48:47 dankogai Exp $
#
use strict;
use warnings;
use Attribute::Tie;
#use Test::More tests => 1;
use Test::More qw/no_plan/;

use Fcntl;   # For O_RDWR, O_CREAT, etc.
eval{
    my %sdbm : Tie('SDBM_File', './_none_/db', O_RDWR|O_CREAT, 0666);
};
ok $@, $@;
Attribute::Tie->seterror(0);
eval{
    my %sdbm : Tie('SDBM_File', './_none_/db', O_RDWR|O_CREAT, 0666);
};
ok !$@, "no error";

Attribute::Tie->seterror(sub{ die join(", ", @_) });
eval{
    my %sdbm : Tie('SDBM_File', './_none_/db', O_RDWR|O_CREAT, 0666);
};
ok $@, $@;

Attribute::Tie->seterror(1);
eval{
    my %sdbm : Tie('SDBM_File', './_none_/db', O_RDWR|O_CREAT, 0666);
};
ok $@, $@;


