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
    Testing->columns(All => qw/id first second third/);
};
plan skip_all => 'Error in the test' if $@;

plan tests => 6;

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

# try to create an object without providing the primary key
eval {
    Testing->create({
        first  => 'foo',
        second => 'bar',
        third  => 'sample',
    });
};
like( $@, qr/planned death/, 'died correctly' );
is_deeply(
    [ sort split( /\s* , \s*/xms, $columns ) ],
    [qw/ first second third /],  # alphabetical order
    'columns'
);
is_deeply(
    [ sort split( /\s* , \s*/xms, $placeholders ) ],
    [qw/ ? ? ? /],
    'placeholders'
);

# try to create an object with an explicit primary key
eval {
    Testing->create({
        id     => 1234,
        first  => 'foo',
        second => 'bar',
        third  => 'sample',
    });
};
like( $@, qr/planned death/, 'died correctly' );
is_deeply(
    [ sort split( /\s* , \s*/xms, $columns ) ],
    [qw/ first id second third /],  # alphabetical order
    'columns'
);
is_deeply(
    [ sort split( /\s* , \s*/xms, $placeholders ) ],
    [qw/ ? ? ? ? /],
    'placeholders'
);
