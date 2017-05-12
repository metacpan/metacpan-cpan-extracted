use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use File::Spec;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh, sqlsnippetdir=>'t/dbs/snippets_recursive' );

my $update = $sc->_update_path;
is( int keys %$update, 2, '2 updates' );
is(
    $update->{'5f22e538285f79ec558e16dbfeb0b34a36e4da19'}->[1],
    '6620c14bb4aaafdcf142022b5cef7f74ee7c7383',
    'first sum link'
);
is(
    $update->{'6620c14bb4aaafdcf142022b5cef7f74ee7c7383'}->[1],
    '39219d6fd802540c79b0a93d7111ea45f66e9518',
    'second sum link'
);
is( $update->{'7a1263a17bc9648e06de64fabb688633feb04f05'},
    undef, 'end of chain' );

cmp_deeply(
    [File::Spec->splitdir($update->{'5f22e538285f79ec558e16dbfeb0b34a36e4da19'}->[0])],
    [qw(t dbs snippets_recursive 1 first_change.sql)],
    'first snippet'
);
cmp_deeply(
    [File::Spec->splitdir($update->{'6620c14bb4aaafdcf142022b5cef7f74ee7c7383'}->[0])],
    [qw(t dbs snippets_recursive 2 another_change.sql)],
    'second snippet'
);

done_testing();
