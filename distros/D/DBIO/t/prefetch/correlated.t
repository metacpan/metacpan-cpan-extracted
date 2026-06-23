use strict;
use warnings;

use Test::More;
use Test::Deep;
use DBIO::Test ':DiffSQL';

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $cdrs = $schema->resultset('CD')->search({ 'me.artist' => { '!=', 2 }});

my $c_rs = $cdrs->search ({}, {
  prefetch => 'tracks',
  '+columns' => { sibling_count => $cdrs->search(
      {
        'siblings.artist' => { -ident => 'me.artist' },
        'siblings.cdid' => { '!=' => ['-and', { -ident => 'me.cdid' }, 23414] },
      }, { alias => 'siblings' },
    )->count_rs->as_query,
  },
});

is_same_sql_bind(
  $c_rs->as_query,
  '(
    SELECT me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track,
           (SELECT COUNT( * )
              FROM cd siblings
            WHERE me.artist != ?
              AND siblings.artist = me.artist
              AND siblings.cdid != me.cdid
              AND siblings.cdid != ?
           ),
           tracks.trackid, tracks.cd, tracks.position, tracks.title, tracks.last_updated_on, tracks.last_updated_at
      FROM cd me
      LEFT JOIN track tracks
        ON tracks.cd = me.cdid
    WHERE me.artist != ?
  )',
  [

    # subselect
    [ { sqlt_datatype => 'integer', dbic_colname => 'me.artist' }
      => 2 ],

    [ { sqlt_datatype => 'integer', dbic_colname => 'siblings.cdid' }
      => 23414 ],

    # outher WHERE
    [ { sqlt_datatype => 'integer', dbic_colname => 'me.artist' }
      => 2 ],
  ],
  'Expected SQL on correlated realiased subquery'
);

# now add an unbalanced select/as pair
$c_rs = $c_rs->search ({}, {
  '+select' => $cdrs->search(
    { 'siblings.artist' => { -ident => 'me.artist' } },
    { alias => 'siblings', columns => [
      { first_year => { min => 'year' }},
      { last_year => { max => 'year' }},
    ]},
  )->as_query,
  '+as' => [qw/active_from active_to/],
});

is_same_sql_bind(
  $c_rs->as_query,
  '(
    SELECT me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track,
           (SELECT COUNT( * )
              FROM cd siblings
            WHERE me.artist != ?
              AND siblings.artist = me.artist
              AND siblings.cdid != me.cdid
              AND siblings.cdid != ?
           ),
           (SELECT MIN( year ), MAX( year )
              FROM cd siblings
            WHERE me.artist != ?
              AND siblings.artist = me.artist
           ),
           tracks.trackid, tracks.cd, tracks.position, tracks.title, tracks.last_updated_on, tracks.last_updated_at
      FROM cd me
      LEFT JOIN track tracks
        ON tracks.cd = me.cdid
    WHERE me.artist != ?
  )',
  [

    # first subselect
    [ { sqlt_datatype => 'integer', dbic_colname => 'me.artist' }
      => 2 ],

    [ { sqlt_datatype => 'integer', dbic_colname => 'siblings.cdid' }
      => 23414 ],

    # second subselect
    [ { sqlt_datatype => 'integer', dbic_colname => 'me.artist' }
      => 2 ],

    # outher WHERE
    [ { sqlt_datatype => 'integer', dbic_colname => 'me.artist' }
      => 2 ],
  ],
  'Expected SQL on correlated realiased subquery'
);

# test for subselect identifier leakage
# NOTE - the hodge-podge mix of literal and regular identifuers is *deliberate*
for my $quote_names (0,1) {
  my $schema = DBIO::Test->init_schema(no_deploy => 1);

  if ($quote_names) {
    $schema->storage->{_sql_maker_opts}{quote_char} = '"';
    $schema->storage->{_sql_maker_opts}{name_sep} = '.';
  }

  my ($ql, $qr) = $schema->storage->sql_maker->_quote_chars;

  my $art_rs = $schema->resultset('Artist')->search ({}, {
    order_by => 'me.artistid',
    prefetch => 'cds',
    rows => 2,
  });

  my $inner_lim_bindtype = { sqlt_datatype => 'integer' };

  for my $inner_relchain (qw( cds_unordered cds ) ) {

    my $stupid_latest_competition_release_query = $schema->resultset('Artist')->search(
      { 'competition.artistid' => { '!=', { -ident => 'me.artistid' } } },
      { alias => 'competition' },
    )->search_related( $inner_relchain, {}, {
      rows => 1, order_by => 'year', columns => { year => \'year' }, distinct => 1
    })->get_column(\'year')->max_rs;

    my $final_query = $art_rs->search( {}, {
      '+columns' => { max_competition_release => \[
        @${ $stupid_latest_competition_release_query->as_query }
      ]},
    });

    # the decomposition to sql/bind is *deliberate* in both instances
    # we want to ensure this keeps working for lietral sql, even when
    # as_query switches to return an overloaded dq node
    my ($sql, @bind) = @${ $final_query->as_query };

    my $correlated_sql = qq{ (
      SELECT MAX( year )
        FROM (
          SELECT year
            FROM ${ql}artist${qr} ${ql}competition${qr}
            JOIN cd ${ql}${inner_relchain}${qr}
              ON ${ql}${inner_relchain}${qr}.${ql}artist${qr} = ${ql}competition${qr}.${ql}artistid${qr}
          WHERE ${ql}competition${qr}.${ql}artistid${qr} != ${ql}me${qr}.${ql}artistid${qr}
          GROUP BY year
          ORDER BY MIN( ${ql}year${qr} )
          LIMIT ?
        ) ${ql}${inner_relchain}${qr}
    )};

    is_same_sql_bind(
      $sql,
      \@bind,
      qq{ (
        SELECT  ${ql}me${qr}.${ql}artistid${qr}, ${ql}me${qr}.${ql}name${qr}, ${ql}me${qr}.${ql}rank${qr}, ${ql}me${qr}.${ql}charfield${qr},
                $correlated_sql,
                ${ql}cds${qr}.${ql}cdid${qr}, ${ql}cds${qr}.${ql}artist${qr}, ${ql}cds${qr}.${ql}title${qr}, ${ql}cds${qr}.${ql}year${qr}, ${ql}cds${qr}.${ql}genreid${qr}, ${ql}cds${qr}.${ql}single_track${qr}
          FROM (
            SELECT  ${ql}me${qr}.${ql}artistid${qr}, ${ql}me${qr}.${ql}name${qr}, ${ql}me${qr}.${ql}rank${qr}, ${ql}me${qr}.${ql}charfield${qr},
                    $correlated_sql
              FROM ${ql}artist${qr} ${ql}me${qr}
              ORDER BY ${ql}me${qr}.${ql}artistid${qr}
              LIMIT ?
          ) ${ql}me${qr}
          LEFT JOIN cd ${ql}cds${qr}
            ON ${ql}cds${qr}.${ql}artist${qr} = ${ql}me${qr}.${ql}artistid${qr}
        ORDER BY ${ql}me${qr}.${ql}artistid${qr}
      ) },
      [
        [ $inner_lim_bindtype
          => 1 ],
        [ $inner_lim_bindtype
          => 1 ],
        [ { sqlt_datatype => 'integer' }
          => 2 ],
      ],
      "No leakage of correlated subquery identifiers (quote_names => $quote_names, inner alias '$inner_relchain')"
    );
  }
}

done_testing;
