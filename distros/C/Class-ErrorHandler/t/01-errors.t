# $Id: 01-errors.t,v 1.1.1.1 2004/08/15 14:55:43 btrott Exp $

use strict;
use Test;

BEGIN { plan tests => 9 };

my $eh = My::Class->new;
ok($eh);
my $val = $eh->error('foo bar');
ok(!defined $val);
ok($eh->errstr eq "foo bar");
my @val = $eh->error('foo');
ok(@val == 0);
ok($eh->errstr eq "foo");

$val = My::Class->error('foo bar');
ok(!defined $val);
ok(My::Class->errstr eq "foo bar");
@val = My::Class->error('foo');
ok(@val == 0);
ok(My::Class->errstr eq "foo");

package My::Class;
use base qw( Class::ErrorHandler );
sub new { bless { }, shift }
