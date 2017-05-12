use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh );

eval { $sc->get_checksums_from_snippet };
like($@,qr/need a filename/i,'get_checksums_from_snippet: no filename');

eval { $sc->get_checksums_from_snippet('/does/not/exist/I/hope') };
like($@,qr/cannot read /i,'get_checksums_from_snippet: bad filename');

{
    my ($pre,$post) = $sc->get_checksums_from_snippet('t/dbs/snippets/bad.foo');
    is($pre,'1234567890123456789012345678901234567890','got pre');
    is($post,'','no post');
}

done_testing();

