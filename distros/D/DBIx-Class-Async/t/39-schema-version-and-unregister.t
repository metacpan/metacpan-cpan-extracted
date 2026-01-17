use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestSchema;
use DBIx::Class::Async::Schema;



# 1. Declare the variable at the top level
my $schema;

# 2. Assign the connection (ensure the key names match your implementation)
$schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=:memory:", undef, undef, {},
    {
        schema_class => 'TestSchema',
        # loop => $loop # include if your setup requires it
    }
);


# In t/39-schema-version-and-unregister.t

# 1. Test schema_version
is($schema->schema_version, $TestSchema::VERSION, 'schema_version matches TestSchema');

# 2. Verify source exists via the CLASS name
my $schema_class = $schema->{schema_class};
ok($schema_class->source('User'), 'User source exists initially in class');

# 3. Perform the unregister via your async wrapper
$schema->unregister_source('User');

# 4. Verify it's gone from the class
eval { $schema_class->source('User') };
like($@, qr/(?:is not registered|Can't find source for)/, 'User source was successfully unregistered');

done_testing();
