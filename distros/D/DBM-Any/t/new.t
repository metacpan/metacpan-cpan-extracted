##
## new.t
##
## $Id: new.t,v 1.1 2002/07/19 20:41:56 tony Exp $
##

use strict;
use Test;
use Fcntl;
BEGIN { plan test => 6; }
BEGIN { require SDBM_File; @AnyDBM_File::ISA = qw(SDBM_File); }
use DBM::Any;
ok(1);

my $x;

# Interface abuse, too few arguments.
eval { $x = new DBM::Any(); };
ok($@, qr/Usage/);

eval { $x = new DBM::Any('foo'); };
ok($@, qr/Usage/);

eval { $x = new DBM::Any('foo', O_CREAT); };
ok($@, qr/Usage/);

$x = new DBM::Any('foo', O_CREAT, 0644);
ok(ref $x, 'DBM::Any');

$x->close();
unlink('foo');
ok(not -e 'foo');
