use Test::More tests => 17;
#use Test::More 'no_plan';


use strict;
use Acme::Oil;
#no warnings qw(Acme::Oil);
use warnings qw(Acme::Oil);
#use warnings;

my $warn;


my $var = 100;

is($var, 100, 'normal scalar');
ok(!tied($var), 'not tied');


Acme::Oil::can($var);

ok(tied($var), 'tied');
isa_ok(tied($var), 'Acme::Oil::ed::Scalar');

is( Acme::Oil::can() , 99, "can's level");


my $count = 0;
{ # scope for warning
  local $SIG{__WARN__} = sub { $warn = $_[0] =~ /slipping/ };

  while($count++ < 10){

	for my $i (1..10){
		$warn = 0;
		last if($i ne ($var = $i));
	}

	last if($warn);
	Acme::Oil::can($var);
  }

} # scope for warning

ok($warn, 'slipped!');

is( Acme::Oil::can() , 99 - $count + 1, "check can's level ($count times loop)");

unless($warn){ warn "if 'slipped!' check is failed, please try again." }


Acme::Oil::wipe($var);

ok(!tied($var), 'untied');

{
  local $SIG{__WARN__} = sub { $warn = $_[0] =~ /bom!/i };
  $warn = 0;
  $var = 'ok';
  Acme::Oil::can($var);
  $var = 'fire';
  isa_ok(tied($var), 'Acme::Oil::Ashed::Scalar');
  ok($warn, 'bom!');
  like($var, qr/ash/i, 'ahsed...');
  $var = 'fire';
  like($var, qr/ash/i, 'ahsed...');
}


my $var2 = 'Firefox';

like($var2, qr/fire/i, 'We bring a fire to the oil can...');

{ # scope for warning
  local $SIG{__WARN__} = sub { $warn = $_[0] =~ /bom!/i };
  $warn = 0;
  Acme::Oil::can($var2);
  ok($warn, 'bom!')
} # scope for warning

isa_ok(tied $var2, 'Acme::Oil::Ashed::Scalar');
like($var2, qr/ash/i, 'ahsed...');
$var2 = 'ok';
like($var2, qr/ash/i, 'ahsed...');
