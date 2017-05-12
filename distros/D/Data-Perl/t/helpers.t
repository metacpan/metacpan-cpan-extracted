use Data::Perl;
use Test::More;


my $array = array(qw/1 2 3 4/);
isa_ok($array, 'Data::Perl::Collection::Array');

my $hash = hash(qw/1 2 3 4/);
isa_ok($hash, 'Data::Perl::Collection::Hash');

my $code = code();
isa_ok($code, 'Data::Perl::Code');

my $code2 = code(sub { 'foo' });
isa_ok($code2, 'Data::Perl::Code');

my $number = number();
isa_ok($number, 'Data::Perl::Number');

$number2 = number(2);
isa_ok($number2, 'Data::Perl::Number');

my $bool = bool(1);
isa_ok($bool, 'Data::Perl::Bool');

my $string = string();
isa_ok($string, 'Data::Perl::String');

my $string2 = string('foo');
isa_ok($string2, 'Data::Perl::String');

my $counter = counter();
isa_ok($counter, 'Data::Perl::Counter');

my $counter2 = counter(1);
isa_ok($counter2, 'Data::Perl::Counter');

done_testing();
