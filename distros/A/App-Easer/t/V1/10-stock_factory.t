use v5.24;
use experimental 'signatures';
use Test::More;
use Test::Exception;
use File::Basename 'dirname';
use lib dirname(__FILE__);

use App::Easer;

{
   package This;
   sub thefunc { return __PACKAGE__ }
}

{
   package That;
   sub thefunc { return __PACKAGE__ }
}

my $factory = App::Easer::V1::generate_factory(
   {
      prefixes => {
         '/'  => 'This#',
         '-'  => 'That#',
         '~~' => 'Other#the',
      }
   }
);

sub thefunc { return __PACKAGE__ }

isa_ok $factory, 'CODE';

is $factory->('/thefunc', 'x')->(), 'This', 'resolution to This';
is $factory->('-thefunc', 'x')->(), 'That', 'resolution to That';
is $factory->('~~func',   'x')->(), 'Other',
  'resolution to Other (external module)';
is $factory->('main#thefunc', 'x')->(), 'main', 'resolution to main';
is $factory->('main', 'thefunc')->(), 'main',
  'resolution to main (via default sub name)';
is $factory->(sub { 'a sub!' }, 'x')->(), 'a sub!', 'a sub reference';
is $factory->('= sub { "inline" }', '')->(), 'inline',
  'some inline Perl code';
is $factory->(
   {executable => sub { return $_[0]{message} }, message => 'hashref'}, ''
)->(), 'hashref', 'hash reference as executable';

my $sub1 = $factory->('+help', '');
my $sub2 = \&App::Easer::V1::stock_help;
is "$sub1", "$sub2", 'prefix + to get stock functions';

for my $error (['This', 'whatever'], ['Inexistent#function', '']) {
   throws_ok { $factory->($error->@*) } qr{locate},
     'exception sent as expected';
}

done_testing();
