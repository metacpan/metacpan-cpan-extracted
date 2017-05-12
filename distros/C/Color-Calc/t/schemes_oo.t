use Test::More tests => 4;
# use Test::NoWarnings;
use Color::Calc();

my $cc;

$cc = Color::Calc->new( 'OutputFormat' => 'html' );
isa_ok($cc, 'Color::Calc');
is($cc->get('green'), 'lime', 'X (default) ColorScheme');

$cc = Color::Calc->new( 'ColorScheme' => 'HTML', 'OutputFormat' => 'html' );
isa_ok($cc, 'Color::Calc');
is($cc->get('green'), 'green', 'HTML ColorScheme');
