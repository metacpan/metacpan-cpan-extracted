use Test::More tests => 24;
#use Test::More 'no_plan';


use strict;
use Acme::Oil;
#no warnings qw(Acme::Oil);
use warnings qw(Acme::Oil);
#use warnings;

my $warn;

my @var;

ok(!tied(@var), 'not tied');

Acme::Oil::can(@var);

ok(tied(@var), 'tied');
isa_ok(tied(@var), 'Acme::Oil::ed::Array');
is( Acme::Oil::can() , 99, "can's level");

$#var = 9;
is(scalar(@var), 10, '# 0..10');

my $count = 0;
{ # scope for warning
  local $SIG{__WARN__} = sub { $warn = $_[0] =~ /slipping/ };

  while($count++ < 3){

 	@var = (0,1,2,3,4,5,6,7,8,9);

	last if($warn);
	Acme::Oil::can(@var);
  }

} # scope for warning

ok($warn, 'slipped!');
is( Acme::Oil::can() , 99 - $count + 1, "check can's level ($count times loop)");

{ # scope for warning
#  local $SIG{__WARN__} = sub { $warn = $_[0] =~ /slipping/ };
  $warn = 0;

  push @var, 100;
#  is(scalar(@var), 11, 'pushable');
  unshift @var, 100;
#  is(scalar(@var), 12, 'unshiftable');
  shift @var;
  pop @var;
}

Acme::Oil::wipe(@var);
ok(!tied(@var), 'untied');

my $max = 2;
@var = (0..$max);
Acme::Oil::can(@var);

is(scalar(@var), $max + 1, "\@var = (0..$max)");


my $level = Acme::Oil::can();
$count = 0;

{ # scope for warning
  local $SIG{__WARN__} = sub { $warn = $_[0] =~ /slipping/ };

  while($count++ < 3){

	for(my $i = 0; $i <= $max; $i++){
		$warn = 0;
		my $check = $var[$i];
		last if(defined $check and $i ne $check);
	}

	last if($warn);
	Acme::Oil::can(@var);
  }

} # scope for warning

ok($warn, 'slipped!');

is( Acme::Oil::can() , $level - $count + 1, "check can's level ($count times loop)");

Acme::Oil::wipe(@var);
ok(!tied(@var), 'untied');

{
  local $SIG{__WARN__} = sub { $warn = $_[0] =~ /bom!/i };
  $warn = 0;
  Acme::Oil::can(@var);
  $var[0] = 'fire';
  ok($warn, 'bom!');
  isa_ok(tied(@var), 'Acme::Oil::Ashed::Array');
  like($var[0], qr/ash/i, 'ahsed...');
  $var[0] = 'fire';
  like($var[0], qr/ash/i, 'ahsed...');
  $#var = 5;
  is(scalar(@var), 0, "ashed array's index is not changable");
  push @var,"hoge";
  is(scalar(@var), 0, "ashed array's index is not changable");
  ok( !exists($var[2]), "doesn't exists");
}

my @var2 = ('Firefox');

like($var2[0], qr/fire/i, 'We bring a fire to the oil can...');

{ # scope for warning
  local $SIG{__WARN__} = sub { $warn = $_[0] =~ /bom!/i };
  $warn = 0;
  Acme::Oil::can(@var2);
  ok($warn, 'bom!')
} # scope for warning

isa_ok(tied @var2, 'Acme::Oil::Ashed::Array');
like($var2[0], qr/ash/i, 'ahsed...');
$var2[0] = 'ok';
like($var2[0], qr/ash/i, 'ahsed...');
