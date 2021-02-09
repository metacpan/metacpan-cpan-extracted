#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;
use Test2::Tools::Explain;

use CDTest;

############################################################

my $schema = CDTest->init_schema;

our $SQL   = '';
our $BINDS = [];

no warnings 'redefine';
*DBIx::Class::Helper::ResultSet::MySQLHacks::dbh_execute = sub {
    my ($self, $sql, $bind) = @_;

    $SQL   = $sql;
    $BINDS = $bind;

    return '0E0';
};
use warnings 'redefine';

sub test_sql_result (+\@$) {
    my ($expected_sql, $expected_binds, $test_name) = @_;

    # An SQL hash makes it easier to evolve our expected SQL as we go
    if (ref $expected_sql && ref $expected_sql eq 'HASH') {
        $expected_sql = join " ", map {
            # add keyword to SQL and only include if it exists
            exists $expected_sql->{$_} ? "$_ ".$expected_sql->{$_} : ()
        } qw< DELETE UPDATE FROM SET WHERE >;  # DELETE FROM WHERE or UPDATE SET WHERE
    }

    is $SQL, $expected_sql, "$test_name - SQL";
    is $BINDS, $expected_binds, "$test_name - Binds", { sql => $SQL, binds => $BINDS };
}

############################################################

subtest 'multi_table_delete' => sub {
    # Simple no WHERE
    my $track_rs = $schema->resultset('Track');
    my %expected_sql = (
        DELETE => 'me',
        FROM   => 'track me',
    );
    my @expected_binds = ();

    $track_rs->multi_table_delete;
    test_sql_result %expected_sql, @expected_binds, 'Single table, no WHERE';

    # With WHERE
    $track_rs = $track_rs->search({ position => 1 });
    $expected_sql{WHERE} = '( position = ? )';
    push @expected_binds,
        [ { dbic_colname => 'position', sqlt_datatype => 'int' }, 1 ]
    ;

    $track_rs->multi_table_delete;
    test_sql_result %expected_sql, @expected_binds, 'Single table';

    # Joined
    my $to_lyrics_rs = $track_rs->search({ "lyrics.lyric_id" => 5 }, { join => 'lyrics' });

    $expected_sql{FROM}   = join(' ',
        'track me',
        'LEFT JOIN lyrics lyrics ON lyrics.track_id = me.trackid',
    );
    $expected_sql{WHERE}  = '( ( lyrics.lyric_id = ? AND position = ? ) )';
    unshift @expected_binds,
        [ { dbic_colname => 'lyrics.lyric_id', sqlt_datatype => 'integer' }, 5 ]
    ;

    $to_lyrics_rs->multi_table_delete;
    test_sql_result %expected_sql, @expected_binds, 'Joined';

    # Various table targets
    $expected_sql{DELETE} = 'lyrics';
    $to_lyrics_rs->multi_table_delete('lyrics');
    test_sql_result %expected_sql, @expected_binds, 'Joined lyrics';

    $expected_sql{DELETE} = 'me, lyrics';
    $to_lyrics_rs->multi_table_delete(qw< me lyrics >);
    test_sql_result %expected_sql, @expected_binds, 'Joined with dual delete';

    # New join to belongs_to
    my $to_cd_rs = $to_lyrics_rs->search(undef, { join => 'cd' });

    $expected_sql{DELETE} = 'cd';
    $expected_sql{FROM}   = join(' ',
        'track me',
        'LEFT JOIN lyrics lyrics ON lyrics.track_id = me.trackid',
        ' JOIN cd cd ON cd.cdid = me.cd',  # typeless JOIN appears to have an extra space
    );
    $to_cd_rs->multi_table_delete('cd');
    test_sql_result %expected_sql, @expected_binds, 'Three tables';

    # Search related
    my $cd_centered_rs = $to_lyrics_rs->search_related('cd');

    $cd_centered_rs->multi_table_delete();  # should switch to 'cd', like our current $expected_sql
    test_sql_result %expected_sql, @expected_binds, 'search_related source alias switch';

    # Complex subquery
    my $complex_limit_rs = $to_lyrics_rs->search(undef, { rows => 4 })->search_related('cd')->search({ 'cd.title' => 'New Fad' });

    $expected_sql{FROM}  = join(' ',
        '('.  # no space
            'SELECT me.trackid, me.cd, me.position, me.title, me.last_updated_on, me.last_updated_at',
            'FROM track me LEFT JOIN lyrics lyrics ON lyrics.track_id = me.trackid',
            'WHERE ( ( lyrics.lyric_id = ? AND position = ? ) )',
            'LIMIT ?'.  # no space
        ') me',  # space
        'LEFT JOIN lyrics lyrics ON lyrics.track_id = me.trackid',
        ' JOIN cd cd ON cd.cdid = me.cd',  # typeless JOIN appears to have an extra space
    );
    $expected_sql{WHERE} = '( cd.title = ? )';
    push @expected_binds,
        [ { sqlt_datatype => 'integer' }, 4 ],
        [ { dbic_colname => 'cd.title', sqlt_datatype => 'varchar', sqlt_size => 100 }, 'New Fad' ]
    ;

    $complex_limit_rs->multi_table_delete('cd');
    test_sql_result %expected_sql, @expected_binds, 'Complex subquery + limit';
};

subtest 'multi_table_update' => sub {
    # Simple no WHERE
    my $track_rs = $schema->resultset('Track');
    my %expected_sql = (
        UPDATE => 'track me',
        SET    => 'foobar = ?',
    );
    my @expected_binds = (
        [ { dbic_colname => 'foobar' }, 1 ]
    );

    $track_rs->multi_table_update({ foobar => 1 });
    test_sql_result %expected_sql, @expected_binds, 'Single table, no WHERE';

    # With WHERE
    $track_rs = $track_rs->search({ position => 1 });
    $expected_sql{WHERE} = '( position = ? )';
    push @expected_binds,
        [ { dbic_colname => 'position', sqlt_datatype => 'int' }, 1 ]
    ;

    $track_rs->multi_table_update({ foobar => 1 });
    test_sql_result %expected_sql, @expected_binds, 'Single table';

    # Joined
    my $to_lyrics_rs = $track_rs->search({ "lyrics.lyric_id" => 5 }, { join => 'lyrics' });

    $expected_sql{UPDATE} = join(' ',
        'track me',
        'LEFT JOIN lyrics lyrics ON lyrics.track_id = me.trackid',
    );
    $expected_sql{WHERE}  = '( ( lyrics.lyric_id = ? AND position = ? ) )';
    splice @expected_binds, 1, 0,  # in-between SET and position
        [ { dbic_colname => 'lyrics.lyric_id', sqlt_datatype => 'integer' }, 5 ]
    ;

    $to_lyrics_rs->multi_table_update({ foobar => 1 });
    test_sql_result %expected_sql, @expected_binds, 'Joined';

    # Updates for multiple tables
    $expected_sql{SET} = 'lyrics.track_id = ?, me.title = ?';
    splice @expected_binds, 0, 1,  # remove SET and re-add
        [ { dbic_colname => 'lyrics.track_id', sqlt_datatype => 'integer' }, 7 ],
        [ { dbic_colname => 'me.title',        sqlt_datatype => 'varchar', sqlt_size => 100 }, 'Boring' ]
    ;

    $to_lyrics_rs->multi_table_update({ "me.title" => "Boring", "lyrics.track_id" => 7 });
    test_sql_result %expected_sql, @expected_binds, 'Joined lyrics';

    # New join to belongs_to
    my $to_cd_rs = $to_lyrics_rs->search(undef, { join => 'cd' });

    $expected_sql{UPDATE} = join(' ',
        'track me',
        'LEFT JOIN lyrics lyrics ON lyrics.track_id = me.trackid',
        ' JOIN cd cd ON cd.cdid = me.cd',  # typeless JOIN appears to have an extra space
    );
    $expected_sql{SET}    = 'lyrics.track_id = ?, me.title = ?, year = ?';
    splice @expected_binds, 2, 0,  # add in year SET
        [ { dbic_colname => 'year', sqlt_datatype => 'varchar', sqlt_size => 100 }, '2000' ]
    ;

    $to_cd_rs->multi_table_update({
        year              => 2000,  # purposely unaliased
        "me.title"        => "Boring",
        "lyrics.track_id" => 7
    });
    test_sql_result %expected_sql, @expected_binds, 'Three table update /w unaliased SET';

    # Complex subquery
    my $complex_limit_rs = $to_lyrics_rs->search(undef, { rows => 4 })->search_related('cd')->search({ 'cd.title' => 'New Fad' });

    $expected_sql{UPDATE} = join(' ',
        '('.  # no space
            'SELECT me.trackid, me.cd, me.position, me.title, me.last_updated_on, me.last_updated_at',
            'FROM track me LEFT JOIN lyrics lyrics ON lyrics.track_id = me.trackid',
            'WHERE ( ( lyrics.lyric_id = ? AND position = ? ) )',
            'LIMIT ?'.  # no space
        ') me',  # space
        'LEFT JOIN lyrics lyrics ON lyrics.track_id = me.trackid',
        ' JOIN cd cd ON cd.cdid = me.cd',  # typeless JOIN appears to have an extra space
    );
    $expected_sql{SET}    = 'year = ?';
    $expected_sql{WHERE}  = '( cd.title = ? )';
    @expected_binds = (
        # Subquery WHERE
        [ { dbic_colname => 'lyrics.lyric_id', sqlt_datatype => 'integer' }, 5 ],
        [ { dbic_colname => 'position', sqlt_datatype => 'int' }, 1 ],
        # LIMIT
        [ { sqlt_datatype => 'integer' }, 4 ],
        # SET
        [ { dbic_colname => 'year', sqlt_datatype => 'varchar', sqlt_size => 100 }, '2000' ],
        [ { dbic_colname => 'cd.title', sqlt_datatype => 'varchar', sqlt_size => 100 }, 'New Fad' ],
    );

    $complex_limit_rs->multi_table_update({
        year => 2000,  # purposely unaliased
    });
    test_sql_result %expected_sql, @expected_binds, 'Complex subquery + limit';
};

############################################################

done_testing;
