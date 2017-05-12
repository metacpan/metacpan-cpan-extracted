use Test::More;
use strict; use warnings;

BEGIN {
  use_ok( 'Bot::Cobalt::Utils', qw/
    color
  / );
}

use IRC::Utils qw/has_color has_formatting/;

my $format;
ok( 
    $format = color('bold') 
            . "Bold text" 
            . color('teal') 
            . "Teal text" 
            . color('normal'),
    "Format string: bold, teal"
);

ok( has_formatting($format), "color() string has formatting" );
ok( has_color($format), "color() string has color" );

{
  my $warning;
  local $SIG{__WARN__} = sub { $warning = $_[0] };
  $format = color('foo') . "Some text";
  like $warning, qr/invalid color/i, 'bad format warned';
}

ok $Bot::Cobalt::Utils::COLORS{RED}, 'COLORS hash accessible';

done_testing
