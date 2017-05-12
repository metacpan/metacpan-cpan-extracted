#!perl -w

use strict;
use Clone qw(clone);
use Data::Clone qw(data_clone);
use Storable qw(dclone);
use Errno qw(ENOENT);

use Devel::Peek;
use Data::Dumper;

our $errstr = 'foo';

my $data = { errstr_ref => \$errstr, errno_ref => \$! };

my $c1 = clone($data);
my $c2 = dclone($data);
my $c3 = data_clone($data);

$errstr = 'bar';
$!      = ENOENT;

print Data::Dumper->Dump([$c1], ['Clone']);
print Data::Dumper->Dump([$c2], ['Storable']);
print Data::Dumper->Dump([$c3], ['DataClone']);

#Dump($c1);
#Dump($c2);

