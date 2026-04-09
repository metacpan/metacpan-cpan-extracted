# Prefer numeric version for backwards compatibility
BEGIN { require 5.010000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Data::Table::Gherkin;

$Data::Table::Gherkin::VERSION = 'v1.0.0';

use Scalar::Util qw( openhandle );

sub _is_unique ( $ );

sub parse {
  my $options = ( ref $_[ -1 ] eq 'HASH' ) ? pop : {};
  my ( $class, $table ) = @_;

  my $self = bless { no_columns => 0, no_rows => 0, rows => [] }, $class;

  # By default split() strips trailing empty fields. This is a perfect
  # behaviour in the paragraph mode use case
  my @rows = split /\n/, openhandle $table ? do { local $/ = ''; scalar <$table> } : $table;

  # Optional header row parsing
  my $column_headers;
  if ( delete $options->{ has_header } ) {
    return unless defined( $column_headers = $self->_parse_row( shift @rows ) );
    _is_unique $column_headers
      or _carpf( 'Column headers are not unique (row number %d)', $self->no_rows ), return
  }

  # Data row parsing
  my $rows = $self->{ rows };
  for my $row ( @rows ) {
    ++$self->{ no_rows };
    return unless defined( my $columns = $self->_parse_row( $row ) );
    push @$rows, $column_headers ? { map { $column_headers->[ $_ ] => $columns->[ $_ ] } 0 .. $#$column_headers } : $columns
  }

  $self
}

{
  my %unescape = ( 'n' => "\n", '|' => '|', '\\' => '\\' );

  sub _parse_row {
    my ( $self, $row ) = @_;

    # Keep trailing empty fields
    my @columns = split /(?<!\\)(?:\\\\)*\K\|/, $row, -1;
    my @error;
    {
      # The first and the last column has to be empty or a sequence of spaces
      ( shift @columns ) =~ m/\A *\z/
        or @error = ( 'Wrong start of row (row number %d)', $self->no_rows ), last;
      ( pop @columns ) =~ m/\A *\z/
        or @error = ( 'Wrong end of row (row number %d)', $self->no_rows ), last;
      # All rows have to have the same number of columns
      if ( $self->no_columns != 0 ) {
        @columns == $self->no_columns
          or @error = ( 'Wrong number of columns in row (row number %d)', $self->no_rows ),
          last
      } else {
        $self->{ no_columns } = scalar @columns
      }
    }
    @error and _carpf( @error ), return;
    for ( @columns ) {
      s/\A *//;
      s/ *\z//;
      s/\\([n|\\])/$unescape{ $1 }/g
    }

    \@columns
  }
}

sub no_columns { shift->{ no_columns } }
sub no_rows    { shift->{ no_rows } }
# Clone (deep shallow copy) the "rows" before returning them
sub rows {
  [ map { ref eq 'HASH' ? { %$_ } : [ @$_ ] } @{ shift->{ rows } } ]
}

sub _carpf ( @ ) {
  require Carp;
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', warned' );
  goto &Carp::carp
}

sub _is_unique ( $ ) {
  my %seen;
  for ( @{ +shift } ) { return 0 if $seen{ $_ }++ }
  1
}

1
