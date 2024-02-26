#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;
use Test2::Tools::Warnings  qw(warns);
use Test2::Tools::Exception qw(dies lives);
use Test2::Tools::Compare   qw(check_isa);

use Data::Transfigure;

use experimental qw(signatures);

# transfigurator registration tests
like(dies {Data::Transfigure->bare->add_transfigurators(undef)}, qr/^Cannot register undef/, 'attempt to register undef');

my $msg = q{Can't locate NonexistentClass.pm in @INC};
like(dies {Data::Transfigure->bare->add_transfigurators('NonexistentClass')}, qr/^\Q$msg/,
  'attempt to register non-existent class');

like(
  dies {Data::Transfigure->bare->add_transfigurators('File::Spec')},
  qr|^Cannot register non-Data::Transfigure::Node/Tree implementers|,
  'attempt to register class not implementing Data::Transfigure::Node'
);

ok(lives {Data::Transfigure->bare->add_transfigurators('Data::Transfigure::Type::DateTime')},
  'register class that has no required parameters');

like(
  dies {Data::Transfigure->bare->add_transfigurators('Data::Transfigure::Node')},
  qr/^Cannot register Role/,
  'attempt to register class that has required parameters'
);

# transfiguration tests
## no default handler
my $t = Data::Transfigure->bare();
isa_ok($t->transfigure(bless({day => 3, month => 4, year => 2005}, 'MyDateTime')), ['MyDateTime'], 'no default handler');
is($t->transfigure(undef), undef, 'no default handler - undef');

$t = Data::Transfigure->bare();
$t->add_transfigurators(qw(Data::Transfigure::Default::ToString));
like(bless({day => 3, month => 4, year => 2005}, 'MyDateTime'), qr/MyDateTime=HASH\(0x[0-9a-f]+\)/, 'default to-string handler');
is(warns {$t->transfigure(undef)}, 1, 'warning for uninitialized stringification');
{
  local $SIG{__WARN__} = sub { };    # kill the warning we just verified and check the actual value
  is($t->transfigure(undef), '', 'default stringification of undef to empty string');
}

$t = Data::Transfigure->new();
like(bless({day => 3, month => 4, year => 2005}, 'MyDateTime'), qr/MyDateTime=HASH\(0x[0-9a-f]+\)/,
  'std default to-string handler');
is($t->transfigure(undef), undef, 'std handler maintains undef in spite of default stringification');

use Data::Transfigure::Type;

my $date = Data::Transfigure::Type->new(
  type    => 'DateTime',
  handler => sub ($node) {
    return $node->strftime("%F");
  }
);

$t = Data::Transfigure->bare();

ok($t->add_transfigurators($date), 'register custom type transfigurator');

use DateTime;

my $dt = DateTime->new(year => 2015, month => 8, day => 27, hour => 12, minute => 0, second => 8);

is($t->transfigure($dt), "2015-08-27", 'apply custom date transfigurator');

is(
  $t->transfigure([[[{title => 'War and Peace'}, {date => $dt}]]]),
  [[[{title => 'War and Peace'}, {date => "2015-08-27"}]]],
  'apply custom date transfigurator (nested)'
);

use Data::Transfigure::Default;

ok($t->add_transfigurators(Data::Transfigure::Default->new(handler => sub ($value) {"//$value//"})),
  'register default transfigurator (override)');

is(
  $t->transfigure({title => 'War and Peace', pages => 1200}),
  {title => '//War and Peace//', pages => '//1200//'},
  'apply overridden default transfigurator'
);

$t = Data::Transfigure->bare();
$t->add_transfigurator_at(
  "/book/author" => Data::Transfigure::Type->new(
    type    => 'MyApp::Person',
    handler => sub ($data) {
      return $data->{firstname};
    }
  )
);

is(
  $t->transfigure(
    {
      book     => {author => bless({firstname => 'John'}, 'MyApp::Person')},
      some_guy => bless({firstname => 'Bob'}, 'MyApp::Person')
    }
  ),
  {book => {author => 'John'}, some_guy => check_isa('HASH')},
  'check that positional transfigurator applies to book>author but not some_guy'
);

$t = Data::Transfigure->new();
$t->add_transfigurators(
  Data::Transfigure::Type->new(
    type    => 'MyApp::Person',
    handler => sub ($entity) {
      return $entity;
    }
  )
);

like(
  dies {$t->transfigure({person => bless({firstname => 'Bob'}, 'MyApp::Person')})},
  qr/^Deep recursion detected in Data::Transfigure::transfigure/,
  'catch unbounded recursion'
);

done_testing;
