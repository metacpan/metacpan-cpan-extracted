use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;

# How many statements a multicreate takes.
#
# The INSERT counts say that rows a create converges on -- the same new genre
# under two cds, the same new artist at both ends of a chain -- are written
# once, and that a row object handed in is not written again.
#
# The SELECT counts say that a multicreate reads nothing. That holds where it
# has nothing to look up: children of the row being created, and related rows
# handed in as objects. It does not hold where a related row is given as data:
# DBIO::Row looks for it with find() before it decides to create it, once
# when the row is built (__new_related_find_or_new_helper) and once more when
# it is inserted (insert). Those counts are TODO -- the claim stays, and it
# was the reason this whole file used to be switched off.
#
# Each count covers the create alone: what a case needs from the database
# beforehand is read before the counters are cleared.

my $TODO_selects =
  'multicreate looks up a related row given as data with find() before '
  . 'creating it, in DBIO::Row::__new_related_find_or_new_helper and again '
  . 'in DBIO::Row::insert; no SELECTs needs a multicreate written in terms '
  . 'of subqueries';

my $TODO_nested =
  'data nested under a related row that already exists is dropped -- the '
  . 'same case as the TODO in t/multi_create/existing_in_chain.t';

my $schema = DBIO::SQLite::Test->init_schema();

my $query_stats;
$schema->storage->debugcb (sub { push @{$query_stats->{$_[0]}}, $_[1] });
$schema->storage->debug (1);

lives_ok (sub {
  undef $query_stats;
  $schema->resultset('Artist')->create ({
    name => 'poor artist',
    cds => [
      {
        title => 'cd1',
        year => 2001,
      },
      {
        title => 'cd2',
        year => 2002,
      },
    ],
  });

  is ( @{$query_stats->{INSERT} || []}, 3, 'number of inserts during creation of artist with 2 cds' );
  is ( @{$query_stats->{SELECT} || []}, 0, 'number of selects during creation of artist with 2 cds' )
    || $ENV{DBIO_MULTICREATE_DEBUG} && diag join "\n", @{$query_stats->{SELECT} || []};
});


lives_ok (sub {
  undef $query_stats;
  $schema->resultset('Artist')->create ({
    name => 'poorer artist',
    cds => [
      {
        title => 'cd3',
        year => 2003,
        genre => { name => 'vague genre' },
      },
      {
        title => 'cd4',
        year => 2004,
        genre => { name => 'vague genre' },
      },
    ],
  });

  is ( @{$query_stats->{INSERT} || []}, 4, 'number of inserts during creation of artist with 2 cds, converging on the same genre' );
  {
    local $TODO = $TODO_selects;
    is ( @{$query_stats->{SELECT} || []}, 0, 'number of selects during creation of artist with 2 cds, converging on the same genre' )
      || $ENV{DBIO_MULTICREATE_DEBUG} && diag join "\n", @{$query_stats->{SELECT} || []};
  }
});


lives_ok (sub {
  my $genre = $schema->resultset('Genre')->first;
  undef $query_stats;
  $schema->resultset('Artist')->create ({
    name => 'poorest artist',
    cds => [
      {
        title => 'cd5',
        year => 2005,
        genre => $genre,
      },
      {
        title => 'cd6',
        year => 2004,
        genre => $genre,
      },
    ],
  });

  is ( @{$query_stats->{INSERT} || []}, 3, 'number of inserts during creation of artist with 2 cds, converging on the same existing genre' );
  is ( @{$query_stats->{SELECT} || []}, 0, 'number of selects during creation of artist with 2 cds, converging on the same existing genre' )
    || $ENV{DBIO_MULTICREATE_DEBUG} && diag join "\n", @{$query_stats->{SELECT} || []};
});


lives_ok (sub {
  undef $query_stats;
  $schema->resultset('Artist')->create ({
    name => 'poorer than the poorest artist',
    cds => [
      {
        title => 'cd7',
        year => 2007,
        cd_to_producer => [
          {
            producer => {
              name => 'jolly producer',
              producer_to_cd => [
                {
                  cd => {
                    title => 'cd8',
                    year => 2008,
                    artist => {
                      name => 'poorer than the poorest artist',
                    },
                  },
                },
              ],
            },
          },
        ],
      },
    ],
  });

  is ( @{$query_stats->{INSERT} || []}, 6, 'number of inserts during creation of artist->cd->producer->cd->same_artist' );
  {
    local $TODO = $TODO_selects;
    is ( @{$query_stats->{SELECT} || []}, 0, 'number of selects during creation of artist->cd->producer->cd->same_artist' )
      || $ENV{DBIO_MULTICREATE_DEBUG} && diag join "\n", @{$query_stats->{SELECT} || []};
  }
});

lives_ok (sub {
  my $artist = $schema->resultset ('Artist')->find(1);
  undef $query_stats;
  $artist->create_related (cds => {
    title => 'cd9',
    year => 2009,
    cd_to_producer => [
      {
        producer => {
          name => 'jolly producer',
          producer_to_cd => [
            {
              cd => {
                title => 'cd10',
                year => 2010,
                artist => {
                  name => 'poorer than the poorest artist',
                },
              },
            },
          ],
        },
      },
    ],
  });

  # cd9 and its link are written; cd10 and its link, nested under the producer
  # the case before this one created, are not
  {
    local $TODO = $TODO_nested;
    is ( @{$query_stats->{INSERT} || []}, 4, 'number of inserts during creation of existing_artist->cd->existing_producer->cd->existing_artist2' );
  }
  {
    local $TODO = $TODO_selects;
    is ( @{$query_stats->{SELECT} || []}, 0, 'number of selects during creation of existing_artist->cd->existing_producer->cd->existing_artist2' )
      || $ENV{DBIO_MULTICREATE_DEBUG} && diag join "\n", @{$query_stats->{SELECT} || []};
  }
});

lives_ok (sub {
  my $artist = $schema->resultset ('Artist')->first;
  my $producer = $schema->resultset ('Producer')->first;

  undef $query_stats;

  $schema->resultset ('CD')->create ({
    title => 'cd11',
    year => 2011,
    artist => $artist,
    cd_to_producer => [
      {
        producer => $producer,
      },
    ],
  });

  is ( @{$query_stats->{INSERT} || []}, 2, 'number of inserts during creation of artist_object->cd->producer_object' );
  is ( @{$query_stats->{SELECT} || []}, 0, 'number of selects during creation of artist_object->cd->producer_object' )
    || $ENV{DBIO_MULTICREATE_DEBUG} && diag join "\n", @{$query_stats->{SELECT} || []};
});

done_testing;
