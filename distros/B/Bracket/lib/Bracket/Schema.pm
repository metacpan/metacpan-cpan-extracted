package Bracket::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(result_namespace => 'Result',);

# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-02-28 11:54:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9Mvnns/DJ5m0MpQNixu/qQ

# You can replace this text with custom content, and it will be preserved on regeneration

sub create_initial_data {
  my ($schema, $config, $custom_values) = @_;

  $custom_values ||= {
    admin_first_name => 'Admin',
    admin_last_name  => 'User',
    admin_email      => "admin\@localhost.org",
    admin_password   => 'admin',
  };

  my @players = $schema->populate(
    'Player',
    [
      [qw/ email password first_name last_name /],
      [ 'no-reply@huntana.com', 'unknown', 'Perfect', 'Player', ],
      [
        $custom_values->{admin_email},      $custom_values->{admin_password},
        $custom_values->{admin_first_name}, $custom_values->{admin_last_name},
      ],
    ]
  );

  my @roles = $schema->populate('Role', [ [qw/ role /], ['admin'], ['basic'] ]);

  # Set admin account up with admin role.  admins are able to edit the
  # perfect bracket among other things.
  my @player_roles =
    $schema->populate('PlayerRole',
    [ [qw/role player/], [ $roles[0]->id, $players[1]->id ], ]);
    
  create_new_year_data($schema);
}

sub create_new_year_data {
  my ($schema,) = @_;

  # Regions
  my @regions = $schema->populate(
    'Region',
    [
      [qw/ id name /],
      [ 1, 'West' ],
      [ 2, 'South' ],
      [ 3, 'East' ],
      [ 4, 'Midwest' ],
    ]
  );

  # Teams
  my @teams = $schema->populate(
    'Team',
    [
      [qw/ id seed name region /],
      [ 1,  1,  'Gonzaga',     1 ],
      [ 2,  16, "Georgia St",     1 ],
      [ 3,  8,  'Boise St',    1 ],
      [ 4,  9,  'Memphis',  1 ],
      [ 5,  5,  'UConn',         1 ],
      [ 6,  12, 'New Mexico St',   1 ],
      [ 7,  4,  'Arkansas',        1 ],
      [ 8,  13, 'Vermont',       1 ],
      [ 9,  6,  'Alabama',     1 ],
      [ 10, 11, 'Rutg/ND',      1 ],
      [ 11, 3,  'Texas Tech',   1 ],
      [ 12, 14, 'Montana St', 1 ],
      [ 13, 7,  'Michigan St',  1 ],
      [ 14, 10, 'Davidson',    1 ],
      [ 15, 2,  'Duke',      1 ],
      [ 16, 15, 'Fullerton',  1 ],

      [ 17, 1,  'Arizona',         2 ],
      [ 18, 16, 'WRST/BRY', 2 ],
      [ 19, 8,  'Seton Hall',          2 ],
      [ 20, 9,  'TCU',       2 ],
      [ 21, 5,  'Houston',       2 ],
      [ 22, 12, 'UAB',          2 ],
      [ 23, 4,  'Illinois',     2 ],
      [ 24, 13, 'Chattanooga',         2 ],
      [ 25, 6,  'Colorado St',   2 ],
      [ 26, 11, 'Michigan',       2 ],
      [ 27, 3,  'Tennessee',         2 ],
      [ 28, 14, 'Longwood',     2 ],
      [ 29, 7,  "Ohio St",      2 ],
      [ 30, 10, 'Loyola Chicago',     2 ],
      [ 31, 2,  'Villanova',        2 ],
      [ 32, 15, 'Delaware',     2 ],

      [ 33, 1,  'Baylor',          3 ],
      [ 34, 16, 'Norfolk St',        3 ],
      [ 35, 8,  'North Carolina',          3 ],
      [ 36, 9,  'Marquette',     3 ],
      [ 37, 5,  'Saint Mary',         3 ],
      [ 38, 12, 'Indiana', 3 ],
      [ 39, 4,  'UCLA',    3 ],
      [ 40, 13, 'Akron',  3 ],
      [ 41, 6,  'Texas',           3 ],
      [ 42, 11, 'Virginia Tech',         3 ],
      [ 43, 3,  'Purdue',        3 ],
      [ 44, 14, 'Yale',    3 ],
      [ 45, 7,  'Murray St',           3 ],
      [ 46, 10, 'San Francisco',              3 ],
      [ 47, 2,  'Kentucky',        3 ],
      [ 48, 15, 'Saint Peter',         3 ],

      [ 49, 1,  'Kansas', 4 ],
      [ 50, 16, 'Texas Southern',     4 ],
      [ 51, 8,  'San Diego St',    4 ],
      [ 52, 9,  'Creighton',  4 ],
      [ 53, 5,  'Iowa', 4 ],
      [ 54, 12, 'Richmond',     4 ],
      [ 55, 4,  'Providence', 4 ],
      [ 56, 13, 'S Dakota St',   4 ],
      [ 57, 6,  'LSU',       4 ],
      [ 58, 11, 'Iowa St',     4 ],
      [ 59, 3,  'Wisconsin',        4 ],
      [ 60, 14, 'Colgate',      4 ],
      [ 61, 7,  'USC',       4 ],
      [ 62, 10, 'Miami', 4 ],
      [ 63, 2,  'Auburn',    4 ],
      [ 64, 15, 'Jacksonville St',     4 ],
    ]
  );

  # Games
  my @games = $schema->populate(
    'Game',
    [
      [qw/ id round /],
      [ 1,  1 ],
      [ 2,  1 ],
      [ 3,  1 ],
      [ 4,  1 ],
      [ 5,  1 ],
      [ 6,  1 ],
      [ 7,  1 ],
      [ 8,  1 ],
      [ 9,  2 ],
      [ 10, 2 ],
      [ 11, 2 ],
      [ 12, 2 ],
      [ 13, 3 ],
      [ 14, 3 ],
      [ 15, 4 ],
      [ 16, 1 ],
      [ 17, 1 ],
      [ 18, 1 ],
      [ 19, 1 ],
      [ 20, 1 ],
      [ 21, 1 ],
      [ 22, 1 ],
      [ 23, 1 ],
      [ 24, 2 ],
      [ 25, 2 ],
      [ 26, 2 ],
      [ 27, 2 ],
      [ 28, 3 ],
      [ 29, 3 ],
      [ 30, 4 ],
      [ 31, 1 ],
      [ 32, 1 ],
      [ 33, 1 ],
      [ 34, 1 ],
      [ 35, 1 ],
      [ 36, 1 ],
      [ 37, 1 ],
      [ 38, 1 ],
      [ 39, 2 ],
      [ 40, 2 ],
      [ 41, 2 ],
      [ 42, 2 ],
      [ 43, 3 ],
      [ 44, 3 ],
      [ 45, 4 ],
      [ 46, 1 ],
      [ 47, 1 ],
      [ 48, 1 ],
      [ 49, 1 ],
      [ 50, 1 ],
      [ 51, 1 ],
      [ 52, 1 ],
      [ 53, 1 ],
      [ 54, 2 ],
      [ 55, 2 ],
      [ 56, 2 ],
      [ 57, 2 ],
      [ 58, 3 ],
      [ 59, 3 ],
      [ 60, 4 ],
      [ 61, 5 ],
      [ 62, 5 ],
      [ 63, 6 ],
    ]
  );
}

1

__END__
# 2014 data
  my @teams = $schema->populate(
    'Team',
    [
      [qw/ id seed name region /],
      [ 1,  1,  'Florida',     1 ],
      [ 2,  16, 'Play-in',     1 ],
      [ 3,  8,  'Colorado',    1 ],
      [ 4,  9,  'Pittsburgh',  1 ],
      [ 5,  5,  'VCU',         1 ],
      [ 6,  12, 'SF Austin',   1 ],
      [ 7,  4,  'UCLA',        1 ],
      [ 8,  13, 'Tulsa',       1 ],
      [ 9,  6,  'Ohio St',     1 ],
      [ 10, 11, 'Dayton',      1 ],
      [ 11, 3,  'Syracuse.',   1 ],
      [ 12, 14, 'W. Michigan', 1 ],
      [ 13, 7,  'New Mexico',  1 ],
      [ 14, 10, 'Stanford',    1 ],
      [ 15, 2,  'Kansas',      1 ],
      [ 16, 15, 'Eastern KY',  1 ],

      [ 17, 1,  'Virginia',         2 ],
      [ 18, 16, 'Coastal Carolina', 2 ],
      [ 19, 8,  'Memphis',          2 ],
      [ 20, 9,  'Geo. Wash.',       2 ],
      [ 21, 5,  'Cincinnati',       2 ],
      [ 22, 12, 'Harvard',          2 ],
      [ 23, 4,  'Michigan St.',     2 ],
      [ 24, 13, 'Delaware',         2 ],
      [ 25, 6,  'North Carolina',   2 ],
      [ 26, 11, 'Providence',       2 ],
      [ 27, 3,  'Iowa St.',         2 ],
      [ 28, 14, 'N.C. Central',     2 ],
      [ 29, 7,  'Connecticut',      2 ],
      [ 30, 10, 'Saint Joseph',     2 ],
      [ 31, 2,  'Villanova',        2 ],
      [ 32, 15, 'UW Milwaukee',     2 ],

      [ 33, 1,  'Arizona',          3 ],
      [ 34, 16, 'Weber St.',        3 ],
      [ 35, 8,  'Gonzaga',          3 ],
      [ 36, 9,  'Oklahoma St.',     3 ],
      [ 37, 5,  'Oklahoma',         3 ],
      [ 38, 12, 'North Dakota St.', 3 ],
      [ 39, 4,  'San Diego St.',    3 ],
      [ 40, 13, 'New Mexico St.',   3 ],
      [ 41, 6,  'Baylor',           3 ],
      [ 42, 11, 'Nebraska',         3 ],
      [ 43, 3,  'Creighton',        3 ],
      [ 44, 14, 'UL Layfayette',    3 ],
      [ 45, 7,  'Oregon',           3 ],
      [ 46, 10, 'BYU',              3 ],
      [ 47, 2,  'Wisconsin',        3 ],
      [ 48, 15, 'American',         3 ],

      [ 49, 1,  'Witchita St', 4 ],
      [ 50, 16, 'Play-in',     4 ],
      [ 51, 8,  'Kentucky',    4 ],
      [ 52, 9,  'Kansas St.',  4 ],
      [ 53, 5,  'Saint Louis', 4 ],
      [ 54, 12, 'Play-in',     4 ],
      [ 55, 4,  'Louisiville', 4 ],
      [ 56, 13, 'Manhattan',   4 ],
      [ 57, 6,  'UMass',       4 ],
      [ 58, 11, 'Play-in',     4 ],
      [ 59, 3,  'Duke',        4 ],
      [ 60, 14, 'Mercer',      4 ],
      [ 61, 7,  "Texas",       4 ],
      [ 62, 10, 'Arizona St.', 4 ],
      [ 63, 2,  'Michigan',    4 ],
      [ 64, 15, 'Wofford',     4 ],
    ]
  );
# 2010 data
    # Regions
    my @regions =
      $schema->populate('Region',
        [ [qw/ id name /], [ 1, 'Midwest' ], [ 2, 'West' ], [ 3, 'East' ], [ 4, 'South' ], ]);

    # Teams
    my @teams = $schema->populate(
        'Team',
        [
            [qw/ id seed name region /],
            [ 1,  1,  'Kansas',           1 ],
            [ 2,  16, 'Lehigh',           1 ],
            [ 3,  8,  'UNLV',             1 ],
            [ 4,  9,  'Northern Iowa',    1 ],
            [ 5,  5,  'Michigan St.',     1 ],
            [ 6,  12, 'New Mexico St.',   1 ],
            [ 7,  4,  'Maryland',         1 ],
            [ 8,  13, 'Houston',          1 ],
            [ 9,  6,  'Tennessee',        1 ],
            [ 10, 11, 'San Diego St.',    1 ],
            [ 11, 3,  'Georgetown',       1 ],
            [ 12, 14, 'Ohio',             1 ],
            [ 13, 7,  'Oklahoma St.',     1 ],
            [ 14, 10, 'Georgia Tech',     1 ],
            [ 15, 2,  'Ohio St.',         1 ],
            [ 16, 15, 'UCSB',             1 ],
            [ 17, 1,  'Syracuse',         2 ],
            [ 18, 16, 'Vermont',          2 ],
            [ 19, 8,  'Gonzaga',          2 ],
            [ 20, 9,  'Florida St.',      2 ],
            [ 21, 5,  'Butler',           2 ],
            [ 22, 12, 'UTEP',             2 ],
            [ 23, 4,  'Vanderbilt',       2 ],
            [ 24, 13, 'Murray St.',       2 ],
            [ 25, 6,  'Xavier',           2 ],
            [ 26, 11, 'Minnesota',        2 ],
            [ 27, 3,  'Pittsburgh',       2 ],
            [ 28, 14, 'Oakland',          2 ],
            [ 29, 7,  'BYU',              2 ],
            [ 30, 10, 'Florida',          2 ],
            [ 31, 2,  'Kansas St.',       2 ],
            [ 32, 15, 'North Texas',      2 ],
            [ 33, 1,  'Kentucky',         3 ],
            [ 34, 16, 'E. Tennessee St.', 3 ],
            [ 35, 8,  'Texas',            3 ],
            [ 36, 9,  'Wake Forest',      3 ],
            [ 37, 5,  'Temple',           3 ],
            [ 38, 12, 'Cornell',          3 ],
            [ 39, 4,  'Wisconsin',        3 ],
            [ 40, 13, 'Wofford',          3 ],
            [ 41, 6,  'Marquette',        3 ],
            [ 42, 11, 'Washington',       3 ],
            [ 43, 3,  'New Mexico',       3 ],
            [ 44, 14, 'Montana',          3 ],
            [ 45, 7,  'Clemson',          3 ],
            [ 46, 10, 'Missouri',         3 ],
            [ 47, 2,  'West Virginia',    3 ],
            [ 48, 15, 'Morgan St.',       3 ],
            [ 49, 1,  'Duke',             4 ],
            [ 50, 16, 'Ark-PB/Winthrop',  4 ],
            [ 51, 8,  'California',       4 ],
            [ 52, 9,  'Louisville',       4 ],
            [ 53, 5,  'Texas A&M',        4 ],
            [ 54, 12, 'Utah St.',         4 ],
            [ 55, 4,  'Purdue',           4 ],
            [ 56, 13, 'Siena',            4 ],
            [ 57, 6,  'Notre Dame',       4 ],
            [ 58, 11, 'Old Dominion',     4 ],
            [ 59, 3,  'Baylor',           4 ],
            [ 60, 14, 'Sam Houston St.',  4 ],
            [ 61, 7,  'Richmond',         4 ],
            [ 62, 10, "St. Mary's",       4 ],
            [ 63, 2,  'Villanova',        4 ],
            [ 64, 15, 'Robert Morris',    4 ],
        ]
    );

# 2011 Data
    my @regions = $schema->populate(
        'Region',
        [
            [qw/ id name /],
            [ 1, 'East' ],
            [ 2, 'West' ],
            [ 3, 'SouthWest' ],
            [ 4, 'SouthEast' ],
        ]
    );

    # Teams
    my @teams = $schema->populate(
        'Team',
        [
            [qw/ id seed name region /],
            [ 1,  1,  'Ohio St.',       1 ],
            [ 2,  16, 'UTSA/Bama St',   1 ],
            [ 3,  8,  'George Mason',   1 ],
            [ 4,  9,  'Villanova',      1 ],
            [ 5,  5,  'West Virginia',  1 ],
            [ 6,  12, 'UAB/Clemson',    1 ],
            [ 7,  4,  'Kentucky',       1 ],
            [ 8,  13, 'Princeton',      1 ],
            [ 9,  6,  'Xavier',         1 ],
            [ 10, 11, 'Marquette',      1 ],
            [ 11, 3,  'Syracuse',       1 ],
            [ 12, 14, 'Indiana St.',    1 ],
            [ 13, 7,  'Washington',     1 ],
            [ 14, 10, 'Georgia',        1 ],
            [ 15, 2,  'North Carolina', 1 ],
            [ 16, 15, 'Long Island',    1 ],
            [ 17, 1,  'Duke',           2 ],
            [ 18, 16, 'Hampton',        2 ],
            [ 19, 8,  'Michigan',       2 ],
            [ 20, 9,  'Tennessee',      2 ],
            [ 21, 5,  'Arizona',        2 ],
            [ 22, 12, 'Memphis',        2 ],
            [ 23, 4,  'Texas',          2 ],
            [ 24, 13, 'Oakland',        2 ],
            [ 25, 6,  'Cincinnati',     2 ],
            [ 26, 11, 'Missouri',       2 ],
            [ 27, 3,  'Connecticut',    2 ],
            [ 28, 14, 'Bucknell',       2 ],
            [ 29, 7,  'Temple',         2 ],
            [ 30, 10, 'Penn St.',       2 ],
            [ 31, 2,  'San Diego St.',  2 ],
            [ 32, 15, 'No. Colorado',   2 ],
            [ 33, 1,  'Kansas',         3 ],
            [ 34, 16, 'Boston U.',      3 ],
            [ 35, 8,  'UNLV',           3 ],
            [ 36, 9,  'Illinois',       3 ],
            [ 37, 5,  'Vanderbilt',     3 ],
            [ 38, 12, 'Richmond',       3 ],
            [ 39, 4,  'Louisville',     3 ],
            [ 40, 13, 'Morehead St.',   3 ],
            [ 41, 6,  'Georgetown',     3 ],
            [ 42, 11, 'USC/VCU',        3 ],
            [ 43, 3,  'Purdue',         3 ],
            [ 44, 14, "St. Peter's",    3 ],
            [ 45, 7,  'Texas A&M',      3 ],
            [ 46, 10, 'Florida St.',    3 ],
            [ 47, 2,  'Notre Dame',     3 ],
            [ 48, 15, 'Akron',          3 ],
            [ 49, 1,  'Pittsburgh',     4 ],
            [ 50, 16, 'NC-Ash/Ark-LR',  4 ],
            [ 51, 8,  'Butler',         4 ],
            [ 52, 9,  'Old Dominion',   4 ],
            [ 53, 5,  'Kansas St.',     4 ],
            [ 54, 12, 'Utah St.',       4 ],
            [ 55, 4,  'Wisconsin',      4 ],
            [ 56, 13, 'Belmont',        4 ],
            [ 57, 6,  "St. John's",      4 ],
            [ 58, 11, 'Gonzaga',        4 ],
            [ 59, 3,  'BYU',            4 ],
            [ 60, 14, 'Wofford',        4 ],
            [ 61, 7,  'UCLA',           4 ],
            [ 62, 10, "Michigan St.",   4 ],
            [ 63, 2,  'Florida',        4 ],
            [ 64, 15, 'UC Santa Barb.', 4 ],
        ]
    );
