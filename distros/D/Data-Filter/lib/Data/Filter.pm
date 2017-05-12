package Data::Filter;

# $Id: Filter.pm 20 2006-09-02 20:49:06Z matt $

use strict;
use warnings;

use vars qw(@ISA @EXPORT $VERSION %Filters);

$VERSION = 1.020;
@ISA = qw(Exporter);
@EXPORT = qw(hashToArray arrayToHash filterData);

use constant OP_OR  => 1;
use constant OP_AND => 2;
use constant OP_NOT => 3;

BEGIN
{
  %Filters = (
    # equals
    "eq"        => \&_filterEqual,
    "=="        => \&_filterEqualInt,

    # not equals
    "ne"        => \&_filterNotEqual,
    "!="        => \&_filterNotEqualInt,

    # regex
    "re"        => \&_filterRegex,
    "=~"        => \&_filterRegex,

    # not-regex
    "nre"       => \&_filterNotRegex,
    "!~"        => \&_filterNotRegex,

    # less than
    "lt"        => \&_filterLessThan,
    "<"         => \&_filterLessThanInt,

    # less than, or equal to
    "le"        => \&_filterLessThanOrEqual,
    "<="        => \&_filterLessThanOrEqualInt,

    # greater than
    "gt"        => \&_filterGreaterThan,
    ">"         => \&_filterGreaterThanInt,

    # greater than, or equal to
    "ge"        => \&_filterGreaterThanOrEqual,
    ">="        => \&_filterGreaterThanOrEqualInt,

    # "between" (inclusive)
    "between"   => \&_filterBetween,
  );
}

sub filterData
{
  my ( $data, $filter ) = @_;

  if ( ! UNIVERSAL::isa ( $data, 'HASH' ) )
  {
    $data = arrayToHash ( $data );
  }

  return _evalBranch ( $data, $filter );
}

sub hashToArray
{
  my $hash = shift;
  my @array = ();

  foreach ( sort keys %$hash )
  {
    push @array, $hash->{ $_ };
  }

  return \@array;
}

sub arrayToHash
{
  my $array = shift;

  return unless UNIVERSAL::isa ( $array, 'ARRAY' );

  my %data;
  my $index = 0;

  foreach ( @$array )
  {
    $data { $index++ } = $_;
  }

  return \%data;
}

sub _evalBranch
{
  my ( $data, $filters ) = @_;

  my %data = %$data;
  my @filters = @$filters;

  my $op = shift @filters;

  # is this a filter?

  if ( defined $Filters { $op } )
  {
    # yes
    my $sub = $Filters { $op };

    # apply filter to each of the elements of %data
    foreach ( keys %data )
    {
      delete $data { $_ } unless &$sub ( $data { $_ }, \@filters );
    }
  }
  else
  {
    # no!
    if ( $op == OP_OR )
    {
      # run each op and merge the results
      my %passed;
      foreach ( @filters )
      {
        # these pass
        _setMerge ( \%passed, _evalBranch ( \%data, $_ ) );
      }
      %data = %passed;
    }
    elsif ( $op == OP_NOT )
    {
      _setSubtract ( \%data, _evalBranch ( \%data, $filters [ 0 ] ) );
    }
    elsif ( $op == OP_AND )
    {
      foreach ( @filters )
      {
        %data = %{ _evalBranch ( \%data, $_ ) };
      }
    }
    else
    {
      die ( "Couldn't identify a filter, or operation" );
    }
  }

  return \%data;
}

sub _setSubtract
{
  my ( $dest, $source ) = @_;

  # remove all of $source from $dest
  foreach ( keys %$source )
  {
    delete $dest->{ $_ };
  }
}

sub _setUnion
{
  my ( $dest, $source ) = @_;

  # union of the 2
  foreach ( keys %$dest )
  {
    delete $dest->{ $_ } unless defined $source->{ $_ };
  }
}

sub _setMerge
{
  my ( $dest, $source ) = @_;

  # merge source into destination making sure duplicates aren't merged in
  foreach ( keys %$source )
  {
    $dest->{ $_ } = $source->{ $_ } unless defined $dest->{ $_ };
  }
}

sub _filterEqual
{
  my ( $data, $filters ) = @_;

  return $data->{ $filters->[ 0 ] } eq $filters->[ 1 ];
}

sub _filterEqualInt
{
  my ( $data, $filters ) = @_;

  return $data->{ $filters->[ 0 ] } == $filters->[ 1 ];
}

sub _filterNotEqual
{
  my ( $data, $filters ) = @_;

  return $data->{ $filters->[ 0 ] } ne $filters->[ 1 ];
}

sub _filterNotEqualInt
{
  my ( $data, $filters ) = @_;

  return $data->{ $filters->[ 0 ] } != $filters->[ 1 ];
}

sub _filterRegex
{
  my ( $data, $filters ) = @_;
  return $data->{ $filters->[ 0 ] } =~ /$filters->[ 1 ]/;
}

sub _filterNotRegex
{
  my ( $data, $filters ) = @_;
  return $data->{ $filters->[ 0 ] } !~ /$filters->[ 1 ]/;
}

sub _filterLessThan
{
  my ( $data, $filters ) = @_;
  return $data->{ $filters->[ 0 ] } lt $filters->[ 1 ];
}

sub _filterLessThanInt
{
  my ( $data, $filters ) = @_;
  return $data->{ $filters->[ 0 ] } < $filters->[ 1 ];
}

sub _filterLessThanOrEqual
{
  my ( $data, $filters ) = @_;
  return $data->{ $filters->[ 0 ] } le $filters->[ 1 ];
}

sub _filterLessThanOrEqualInt
{
  my ( $data, $filters ) = @_;
  return $data->{ $filters->[ 0 ] } <= $filters->[ 1 ];
}

sub _filterGreaterThan
{
  my ( $data, $filters ) = @_;
  return $data->{ $filters->[ 0 ] } gt $filters->[ 1 ];
}

sub _filterGreaterThanInt
{
  my ( $data, $filters ) = @_;
  return $data->{ $filters->[ 0 ] } > $filters->[ 1 ];
}

sub _filterGreaterThanOrEqual
{
  my ( $data, $filters ) = @_;

  return $data->{ $filters->[ 0 ] } ge $filters->[ 1 ];
}

sub _filterGreaterThanOrEqualInt
{
  my ( $data, $filters ) = @_;

  return $data->{ $filters->[ 0 ] } >= $filters->[ 1 ];
}

sub _filterBetween
{
  my ( $data, $filters ) = @_;

  my $value = $data->{ $filters->[ 0 ] };

  return ( $value >= $filters->[ 1 ] && $value <= $filters->[ 2 ] );
}

1;

=head1 NAME

Data::Filter - filter data structures with structured filters.

=head1 SYNOPSIS

  use Data::Filter;

  my %dataSet = (
    0 => {
      name   => 'Data::Filter',
      author => 'Matt Wilson',
    },
    1 => {
      name   => 'Pod::XML',
      author => 'Matt Wilson,
    },
    # ... etc.
  );

  my @filter = [
    Data::Filter::OP_AND,
    [
      're',
      'name',
      '^Pod',
    ],
    [
      're',
      'name',
      'XML$',
    ],
  ];

  my %result = %{ filterData ( \%dataSet, \%filter ) };

=head1 DESCRIPTION

The structure of the data set is rarely in this format. However, I decided
that this was the easiest method to determine (and guarantee) that recursive
filters did not confuse the difference between records (as each record has
it's own unique key). If, as is more likely, your data set is in an array
format, like so;

  my @dataSet = (
    {
      name   => 'Data::Filter',
      author => 'Matt Wilson',
    },
    {
      name   => 'Pod::XML',
      author => 'Matt Wilson,
    },
    # ... etc.
  );

A helper function is provided to convert your array into the required hash
reference form;

  my %dataSet = %{ arrayToHash ( \@dataSet ) };

Where arrayToHash obviously returns a hash reference.

Similarly, the filterData subroutine returns a hash reference in the same form
as the provided data set (hash reference, rather than array). As such, there
is also a utility subroutine, hashToArray, to deal with such circumstances.

Next, let's take a look at the format of the filtering array, as that's fairly
important if you'd like to create any meaningful results!

A filter is of the form;

[
  op,
  column,
  value,
  ( value2, value3, ... ),
]

or, more complex;

[
  OP_AND,
  [
    (see above),
  ],
  [
  ],
],

or, possibly;

[
  OP_AND,
  [
    OP_NOT,
    [
      OP_EQ,
      column,
      value,
    ],
  ],
  [
    # ...
  ],
]

=head1 CREATING OPERATORS

It's possible to create your own operator functions (such as the "equals"
operator). To do this, simply add a new entry to the Data::Filter::Filters
hash, where the key is the name of the operator, and the value is a code
reference to the function to call. For instance, the "equals" operator looks
like so;

  $Data::Filter::Filters { 'eq' } = \&_filterEqual;

The subroutine takes two parameters, a hash reference which represents the
entry being checked, and an array reference of the filter being executed. The
return value is whether or not the data hash reference passes this filter. For
example, the _filterEqual subroutine looks like so;

  sub _filterEqual
  {
    my ( $data, $filters ) = @_;

    return $data->{ $filters->[ 0 ] } eq $filters->[ 1 ];
  }

Where the $filters array reference contains the elements [ column, value ].

=head1 METHODS

=over 2

=item \%filteredData = filterData(\%dataSet,\@filter)

Perform the actual filtering work using the filter described by @filter on the
hash %dataSet. More information can be found in the description section of
this POD.

=item \@data = hashToArray(\%data)

Convert a internal data representation along the lines of;

  %data = (
    0 => {
      # column => value pairs
    },
    1 => { 
      # column => value pairs
    },
  )

To an array equivalent;

  @data = (
    {
      # column => value pairs
    },
    {
      # column => value pairs
    },
  )

=item \%data = arrayToHash(\@data)

This subroutine has the opposite effect of the hashToArray subroutine
described above.

=back

=head1 AUTHOR

Matt Wilson E<lt>matt AT mattsscripts DOT co DOT ukE<gt>

=head1 LICENSE

This is free software, you may use it a distribute it under the same terms as
Perl itself.

=cut
