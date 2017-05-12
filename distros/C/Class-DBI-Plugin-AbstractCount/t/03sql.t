#!/usr/bin/perl -I.
# vim:set tabstop=2 shiftwidth=2 expandtab filetype=perl:
use strict;
use warnings;

use Test::More tests => 21;
use SQL::Abstract::Test import => [qw( is_same_sql is_same_bind )];
{
  no warnings 'once';
  $SQL::Abstract::Test::parenthesis_significant = ''; # false
}

$main::sql = "";

sub set_sql
{
  my ( $class, $name, $sql ) = @_;
  no strict 'refs';
  *{ "$class\::sql_$name" } =
    sub
    {
      my ( $class, $where ) = @_;
      ( $main::sql = sprintf $sql, $where ) =~ s/^\s+//mg;
      return $class;
    };
}

sub retrieve_from_sql {} # Make plugin believe we're inheriting from Class::DBI

sub select_val
{
  shift;
  return @_;
}

sub columns { return qw( artist title release updated ) }

sub _croak
{
  shift;
  die ": _croak(): '@_'\n";
}

# If we can't be free, at least we can be cheap...
{
  package artist;
  sub accessor { return 'artist_name' }
}
{
  package title;
  sub accessor { return 'album_title' }
}
{
  package release;
  sub accessor { return 'release_date' }
}
{
  package updated;
  sub accessor { return 'last_change' }
}

use_ok('Class::DBI::Plugin::AbstractCount');

# Test simple where-clause
my @bind_params = __PACKAGE__->count_search_where({
  artist => 'Frank Zappa'
});
is_same_sql(
  $main::sql,
  'SELECT COUNT(*) FROM __TABLE__ WHERE ( artist = ? )',
  'sql statement 1',
);
is_same_bind( \@bind_params, [ 'Frank Zappa' ], 'bind param list 1' );

# Test more complex where-clause
@bind_params = __PACKAGE__->count_search_where({
  artist  => 'Frank Zappa',
  title   => { like => '%Shut Up \'n Play Yer Guitar%' },
  release => { between => [ 1980, 1982 ] },
});
is_same_sql(
  $main::sql, q{
    SELECT COUNT(*)
    FROM __TABLE__
    WHERE ( ( artist = ? AND ( release BETWEEN ? AND ? ) AND title LIKE ? ) )
  },
  'sql statement 2',
);
is_same_bind(
  \@bind_params, [
    'Frank Zappa',
    '1980',
    '1982',
    '%Shut Up \'n Play Yer Guitar%',
  ],
  'bind param list 2',
);

# Test where-clause with accessors
@bind_params = __PACKAGE__->count_search_where({
  artist_name  => 'Steve Vai',
  album_title  => { like => 'Flexable%' },
  release_date => { between => [ 1983, 1984 ] },
});
is_same_sql(
  $main::sql, q{
    SELECT COUNT(*)
    FROM __TABLE__
    WHERE ( ( artist = ? AND ( release BETWEEN ? AND ? ) AND title LIKE ? ) )
  },
  'sql statement 3',
);
is_same_bind(
  \@bind_params, [
    'Steve Vai',
    '1983',
    '1984',
    'Flexable%',
  ],
  'bind param list 3',
);

# Test where-clause with simple function-call on column name
@bind_params = __PACKAGE__->count_search_where({
  artist            => 'Adrian Belew',
  'YEAR( release )' => { '=', 2005 },
});
is_same_sql(
  $main::sql, q{
    SELECT COUNT(*)
    FROM __TABLE__
    WHERE ( ( YEAR( release ) = ? AND artist = ? ) )
  },
  'sql statement 4',
);
is_same_bind(
  \@bind_params, [
    '2005',
    'Adrian Belew'
  ],
  'bind param list 4',
);

# Test where-clause with more complex (nested) function-call on column name
@bind_params = __PACKAGE__->count_search_where({
  artist                       => 'Adrian Belew',
  'COALESCE( release, NOW() )' => { '=', 2005 },
});
is_same_sql(
  $main::sql, q{
    SELECT COUNT(*)
    FROM __TABLE__
    WHERE ( ( COALESCE( release, NOW() ) = ? AND artist = ? ) )
  },
  'sql statement 5',
);
is_same_bind(
  \@bind_params, [
    '2005',
    'Adrian Belew'
  ],
  'bind param list 5',
);

# Test where-clause with simple function-call on accessor
@bind_params = __PACKAGE__->count_search_where({
  artist_name            => 'Adrian Belew',
  'YEAR( release_date )' => { '=', 2005 },
});
is_same_sql(
  $main::sql, q{
    SELECT COUNT(*)
    FROM __TABLE__
    WHERE ( ( YEAR( release ) = ? AND artist = ? ) )
  },
  'sql statement 6',
);
is_same_bind(
  \@bind_params, [
    '2005',
    'Adrian Belew'
  ],
  'bind param list 6',
);

# Test where-clause with more complex (nested) function-call on accessor
@bind_params = __PACKAGE__->count_search_where({
  artist_name                       => 'Adrian Belew',
  'COALESCE( release_date, NOW() )' => { '=', 2005 },
});
is_same_sql(
  $main::sql, q{
    SELECT COUNT(*)
    FROM __TABLE__
    WHERE ( ( COALESCE( release, NOW() ) = ? AND artist = ? ) )
  },
  'sql statement 7',
);
is_same_bind(
  \@bind_params, [
    '2005',
    'Adrian Belew'
  ],
  'bind param list 7',
);

# Test where-clause with more complex (nested) function-call on multiple
# column names
@bind_params = __PACKAGE__->count_search_where({
  artist                                => 'Adrian Belew',
  'COALESCE( release, updated, NOW() )' => { '=', 2005 },
});
is_same_sql(
  $main::sql, q{
    SELECT COUNT(*)
    FROM __TABLE__
    WHERE ( ( COALESCE( release, updated, NOW() ) = ? AND artist = ? ) )
  },
  'sql statement 8',
);
is_same_bind(
  \@bind_params, [
    '2005',
    'Adrian Belew'
  ],
  'bind param list 8',
);

# Test where-clause with more complex (nested) function-call on mixed
# column and accessor names
@bind_params = __PACKAGE__->count_search_where({
  artist                                    => 'Adrian Belew',
  'COALESCE( release, last_change, NOW() )' => { '=', 2005 },
});
is_same_sql(
  $main::sql, q{
    SELECT COUNT(*)
    FROM __TABLE__
    WHERE ( ( COALESCE( release, updated, NOW() ) = ? AND artist = ? ) )
  },
  'sql statement 9',
);
is_same_bind(
  \@bind_params, [
    '2005',
    'Adrian Belew'
  ],
  'bind param list 9',
);

# Test complex where-clause
@bind_params = __PACKAGE__->count_search_where(
  -and => [
    artist => 'System Of A Down',
    -nest  => [
      -and => [
        title   => { like => '%ize' },
        release => 2005,
      ],
      -and => [
        title   => { like => '%ize' },
        release => 2006,
      ],
    ],
  ],
);
is_same_sql(
  $main::sql, q{
    SELECT COUNT(*)
    FROM __TABLE__
    WHERE ( ( artist = ? AND ( ( title LIKE ? AND release = ? )
                            OR ( title LIKE ? AND release = ? ) ) ) )
  },
  'sql statement 10',
);
is_same_bind(
  \@bind_params, [
    'System Of A Down',
    '%ize',
    '2005',
    '%ize',
    '2006',
  ],
  'bind param list 10',
);

__END__
