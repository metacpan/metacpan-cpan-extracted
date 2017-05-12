use warnings;
use strict;

use Test::More;
eval { require Test::MockModule }
    or plan skip_all => 'Test::MockModule not installed';
eval { require DBD::NullP }
    or plan skip_all => 'DBD::NullP not installed';

# create our sample class
eval q{
    package Testing;
    use base 'Class::DBI::MSAccess';
    Testing->connection('dbi:NullP:');
    Testing->table('testing');
    Testing->columns(Primary => qw/id1 id2/);
    Testing->columns(Others => qw/first second third/);
};
plan skip_all => 'Error in the test' if $@;

plan tests => 3;

# mock an interesting method so we can see if things worked
my $cdbi = Test::MockModule->new('Class::DBI');
my ($columns, $placeholders);
$cdbi->mock(
    sql_MakeNewObj => sub {
        my $self = shift;
        ($columns, $placeholders) = @_;
        die "planned death\n";
    }
);

# try to create an object with explicit primary keys
eval {
    Testing->create({
        id1    => 1234,
        id2    => 5678,
        first  => 'foo',
        second => 'bar',
        third  => 'sample',
    });
};
like( $@, qr/planned death/, 'died correctly' );
is_deeply(
    [ sort split( /\s* , \s*/xms, $columns ) ],
    [qw/ first id1 id2 second third /],  # alphabetical order
    'columns'
);
is_deeply(
    [ sort split( /\s* , \s*/xms, $placeholders ) ],
    [qw/ ? ? ? ? ? /],
    'placeholders'
);
