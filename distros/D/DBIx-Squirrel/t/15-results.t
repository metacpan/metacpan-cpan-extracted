use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Context qw(result_original);

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
my $dbh = DBIx::Squirrel->connect(@source);
$dbh->do('CREATE TABLE artist (ArtistId INTEGER PRIMARY KEY, Name TEXT)');
$dbh->do('INSERT INTO artist (Name) VALUES (?)', undef, $_)
    for qw(Abba Blur Cream Dido);
my $all = 'SELECT ArtistId, Name FROM artist ORDER BY ArtistId';

# Every result a result set hands out.
sub drain ($results) {
    my @results;
    while (my($result) = $results->next) { push @results, $result }
    return \@results;
}

package My::Artist {
    our @ISA = 'DBIx::Squirrel::Result';
    sub shout ($self) { return uc $self->name }
}

subtest 'rows are arrays, blessed into a class for their columns' => sub {
    my $results = $dbh->results($all);
    my($row) = $results->next;
    isa_ok $row, ['DBIx::Squirrel::Result'], 'a row';
    is [@$row], [1, 'Abba'], 'an array, as fetched';
    like ref $row, qr( \A DBIx::Squirrel::Result::Row_ [0-9a-f]{16} \z )x,
        'of a class named for its columns';
    my($again) = $dbh->results("$all LIMIT 1")->next;
    is ref $again, ref $row, 'shared by result sets with the same columns';
    my($other) = $dbh->results('SELECT Name FROM artist')->next;
    isnt ref $other, ref $row, 'and not by others';
    my($array) = $dbh->results("$all LIMIT 1", {ekorn_slice => {}})->next;
    is [@$array], [1, 'Abba'], 'arrays, whatever ekorn_slice says';
};

subtest 'a method for each column, in lower case' => sub {
    my($row) = $dbh->results($all)->next;
    is $row->artistid, 1,      'artistid';
    is $row->name,     'Abba', 'name';
    ok ref($row)->can('name'),  'from the first row, as can says';
    ok !ref($row)->can('Name'), 'in lower case only';
    is $row->get_column('NAME'), 'Abba', 'get_column, by name, in any case';
    is $row->get_column(0),      1,      'and by position';
    my $expected = 'Expected a column of the row (nope)';
    my $line     = __LINE__ + 1;
    like dies { $row->get_column('nope') },
        qr( \A \Q$expected\E \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'croaking at the caller on a name it lacks';
    like dies { $row->get_column(2) },
        qr( \A Expected\ a\ column\ of\ the\ row\ \(2\) )x, 'or a position';
    like dies { $row->get_column("\x{0661}") },
        qr( \A Expected\ a\ column\ of\ the\ row\ \(\x{0661}\) )x,
        'a digit of another script being a name, not a position';
};

subtest 'columns no method can reach' => sub {
    my($row) = $dbh->results(
        'SELECT COUNT(*), 1 AS can, 2 AS get_column, 3 AS id, 4 AS id FROM artist',
    )->next;
    is $row->get_column('count(*)'), 4, 'a name no method can have';
    ok $row->can('id'), 'can is still the method';
    is $row->get_column('can'),        1, 'with get_column for the column';
    is $row->get_column('get_column'), 2, 'and get_column too';
    is $row->id,                       3, 'and the first of two named alike';
    is $row->get_column(4),            4, 'the second, by position';
};

subtest 'a row outlives its result set' => sub {
    my $row = $dbh->results("$all LIMIT 1")->single;
    is $row->name, 'Abba', 'from a result set gone at once';
};

subtest 'the stages see the rows as objects' => sub {
    is drain($dbh->results($all, sub ($artist) { $artist->name })),
        [qw(Abba Blur Cream Dido)], 'a map';

    # As version 1's t/06-results.t: a filter, and a flatMap adding results.
    my sub filter ($artist) { return $artist->artistid % 2 ? $artist : () }
    my sub names  ($artist) {
        return $artist->artistid == 1
            ? ($artist->name, 'Agnetha', 'Frida')
            : $artist->name;
    }
    my $results = $dbh->results($all, \&filter, \&names);
    is [$results->all], [qw(Abba Agnetha Frida Cream)],
        'a filter and a flatMap';
    is [$results->reset->all], [qw(Abba Agnetha Frida Cream)], 'and again';

    my($original) = $dbh->results($all, sub { result_original })->next;
    isa_ok $original, ['DBIx::Squirrel::Result'],
        'result_original, as an object';
};

subtest 'bind values' => sub {
    my $sql = 'SELECT Name FROM artist WHERE ArtistId = :id';
    is $dbh->results($sql, id => 3)->single->name, 'Cream', 'by name';
    is $dbh->prepare($sql)->results(id => 2)->single->name, 'Blur',
        'on a statement handle';
};

subtest 'ekorn_result_class' => sub {
    my $row
        = $dbh->results("$all LIMIT 1", {ekorn_result_class => 'My::Artist'})
        ->single;
    isa_ok $row, ['My::Artist'], 'a row, on prepare';
    is $row->shout, 'ABBA', 'with methods of its own';
    like ref $row, qr( \A My::Artist::Row_ )x, 'in a class under its own';

    my $other = DBIx::Squirrel->connect(
        @source[0 .. 2],
        {%{ $source[3] }, ekorn_result_class => 'My::Artist'},
    );
    is $other->results('SELECT 1 AS name')->single->shout, '1', 'or on connect';

    my $expected
        = 'Expected ekorn_result_class to be a subclass of DBIx::Squirrel::Result (main)';
    like dies {
        $dbh->results($all, {ekorn_result_class => 'main'})->next
    }, qr( \A \Q$expected\E )x, 'croaks on another class';
};

subtest 'a statement without rows' => sub {
    my $update = 'UPDATE artist SET Name = Name WHERE ArtistId = ?';
    is drain($dbh->results($update, 1)), [], 'has no results';
    my $quiet = DBIx::Squirrel->connect(
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 0, PrintError => 0},
    );
    $quiet->do('CREATE TABLE u (x INTEGER UNIQUE)');
    $quiet->do('INSERT INTO u VALUES (1)');
    is drain($quiet->results('INSERT INTO u VALUES (?)', 1)), [],
        "nor has one that couldn't be executed, without RaiseError";
};

subtest 'errors are reported at the caller' => sub {

    # The second row overflows, so the fetch fails after execute succeeds.
    my $failed = 'DBD::SQLite::st fetchall_arrayref failed: integer overflow';
    my $overflow
        = 'SELECT abs(column1) FROM (VALUES (1), (-9223372036854775807 - 1))';
    my $line = __LINE__ + 1;
    like dies { $dbh->results($overflow)->all },
        qr( \A \Q$failed\E \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'from a fetch';
};

done_testing;
