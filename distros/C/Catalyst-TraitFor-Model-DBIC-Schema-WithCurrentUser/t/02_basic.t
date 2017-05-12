use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use Scalar::Util qw/refaddr/;
use lib 'lib';
use lib 't/lib';

use TestApp;
use TestApp::Schema;
use TestApp::User;
use TestApp::Model::DB;

BEGIN { $ENV{CMDS_NO_SOURCES} = 1 }

my $schema;
lives_ok { $schema = TestApp::Schema->connect('dbi:SQLite:dbname=:memory:') }
"Can get schema OK";

my $model;
lives_ok { $model = TestApp::Model::DB->new } "Can get model OK";

can_ok( $model,  qw/ACCEPT_CONTEXT build_per_context_instance/ );
can_ok( $schema, qw/current_user/ );
isa_ok( $model, 'Catalyst::Component' );

my $ctx      = TestApp->new;
my $instance = $model->ACCEPT_CONTEXT($ctx);

my $ctx1 = TestApp->new(user => TestApp::User->new(name => 'Bashr'));
my $instance1 = $model->ACCEPT_CONTEXT($ctx1);

isa_ok( $ctx, 'TestApp' );
isa_ok( $ctx1, 'TestApp' );

is( $instance->schema->current_user->name, 'Amiri', "The first context delivered the right, default, user to schema");
is( $instance1->schema->current_user->name, 'Bashr', "The second context delivered the new user to schema");
