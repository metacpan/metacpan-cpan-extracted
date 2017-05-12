# DBIx::Class::Schema::ResultSetAccessors - check module loading and create testing directory

use strict;
use warnings;

use lib qw(t/lib);

use Test::More;
use Test::Warn;

BEGIN {
    use_ok('MyApp1::Schema');
}

ok my $schema1 = MyApp1::Schema->connect('dbi:SQLite:dbname=:memory:', '', ''),
    'Got schema 1';

isa_ok $schema1->resultset('Artist'), 'DBIx::Class::ResultSet';
can_ok $schema1, qw/cds artists liner_notes/;
isa_ok $schema1->artists, 'DBIx::Class::ResultSet';    # generic resultset
isa_ok $schema1->cds, 'MyApp1::Schema::ResultSet::CD'; # custom ResultSet

# overwrite the accessor name with resultset_accessor_name()
can_ok $schema1, qw/source_resultset/;
isa_ok $schema1->source_resultset, 'DBIx::Class::ResultSet';

# test the warnings
warning_like { warn_same_name() } qr/Schema method with the same name already exists/,
    'Schema method with the same name already exists';

sub warn_same_name {
    # must use required, because for some reason throws_ok cannot catch
    # erros with "use"
    require MyApp2::Schema;
    
    # eval'ing this, otherwise an odd error is thrown
    # "Can't call method "_count_select" on an undefined value"
    # I presume it's due to the store not having the actual schema installed
    # as we are connecting to an empty database
    eval {
        my $schema = MyApp2::Schema->connect('dbi:SQLite:dbname=:memory:', '', '');
    };
}

done_testing;
