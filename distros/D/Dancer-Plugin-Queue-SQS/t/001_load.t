# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Dancer::Plugin::Queue::SQS' ); }

my $object = Dancer::Plugin::Queue::SQS->new(access_key => 'Test', secret_key => 'test', queue_name => 'test');
isa_ok ($object, 'Dancer::Plugin::Queue::SQS');

diag( "Testing Dancer::Plugin::Queue::SQS $Dancer::Plugin::Queue::SQS::VERSION, Perl $], $^X" );

