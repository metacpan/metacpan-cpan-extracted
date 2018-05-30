use Test::More tests => 1;

use Class::Date;

my $d2 = Class::Date->new('1935-12-23');
my $d1 = Class::Date->new('2008-12-17');
  
my $k = int( (Class::Date->new($d1)-$d2)->year );
is $k => 72, 'gh#3';
