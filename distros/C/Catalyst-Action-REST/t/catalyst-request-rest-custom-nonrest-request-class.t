use strict;
use warnings;
use Test::More;
use FindBin;
use Moose ();
use lib ( "$FindBin::Bin/lib" );

my $test = 'Test::Catalyst::Action::REST';

my $meta = Moose::Meta::Class->create_anon_class(
    superclasses => ['Catalyst::Request'],
);
$meta->add_method('__random_method' => sub { 42 });

$ENV{CAR_TEST_REQUEST_CLASS} = $meta->name;

use_ok $test;
ok($test->request_class->does('Catalyst::TraitFor::Request::REST'),
  'Request class does Catalyst::TraitFor::Request::REST');
isnt $test->request_class, $meta->name, 'Different request class';
ok $test->request_class->can('__random_method'), 'Is right class';
ok $test->request_class->can('data'), 'Also smells like REST subclass';

done_testing;
