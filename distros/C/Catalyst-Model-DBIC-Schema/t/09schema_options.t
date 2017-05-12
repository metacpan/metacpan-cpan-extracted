use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Test::Exception;
use Catalyst::Model::DBIC::Schema;
use ASchemaClass;
use AnotherSchemaClass;

# reusing the same app for 2 models, gets a redefined warning
$SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /redefined/ };

ok((my $m = instance(a_schema_option => 'mtfnpy')), 'instance');

is $m->schema->a_schema_option, 'mtfnpy', 'option was passed from config';

lives_ok { $m->a_schema_option('pass the crack pipe') } 'delegate called';

is $m->schema->a_schema_option, 'pass the crack pipe', 'delegation works';

ok(($m = instance(schema_class => 'AnotherSchemaClass')), 'instance');

is $m->resultset('User')->rs_config_option, 'configured rs value',
    'ResultSet option passed from config';

done_testing;

sub instance {
    MyApp::Model::DB->COMPONENT('MyApp', {
        traits => 'SchemaProxy',
        schema_class => 'ASchemaClass',
        connect_info => ['dbi:SQLite:foo.db', '', ''],
        @_,
    })
}

BEGIN {
    package MyApp;
    use Catalyst;
    __PACKAGE__->config({
        'Model::DB::User' => {
            rs_config_option => 'configured rs value',
        },
    });
}

{
    package MyApp::Model::DB;
    use base 'Catalyst::Model::DBIC::Schema';
}
