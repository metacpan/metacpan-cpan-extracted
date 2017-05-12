use strict;
use warnings;
use Test::More;
use FindBin;
use Moose ();
use lib ( "$FindBin::Bin/lib" );

my $test = 'Test::Catalyst::Action::REST';

my $meta = Moose::Meta::Class->create_anon_class(
    # The test app has ForBrowsers actions, so we need that to not have
    # the request class replaced
    superclasses => ['Catalyst::Request::REST::ForBrowsers'],
);

$ENV{CAR_TEST_REQUEST_CLASS} = $meta->name;

use_ok $test;
ok($test->request_class->does('Catalyst::TraitFor::Request::REST'),
  'Request class does Catalyst::TraitFor::Request::REST');
is $test->request_class, $meta->name, 'Request class kept';
ok $test->request_class->can('data'), 'Also smells like REST subclass';

done_testing;
