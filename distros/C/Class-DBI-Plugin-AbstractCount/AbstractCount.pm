package Class::DBI::Plugin::AbstractCount;
# vim:set tabstop=2 shiftwidth=2 expandtab:

use strict;
use base 'Class::DBI::Plugin';
use SQL::Abstract;

our $VERSION = '0.08';

sub init
{
  my $class = shift;
  $class->set_sql( count_search_where => qq{
      SELECT COUNT(*)
      FROM __TABLE__
      %s
    } );
}

sub count_search_where : Plugged
{
  my $class = shift;
  my %where = ();
  my $rh_attr = {};
  if ( ref $_[0] ) {
    $class->_croak( "where-clause must be a hashref it it's a reference" )
      unless ref( $_[0] ) eq 'HASH';
    %where = %{ $_[0] };
    $rh_attr = $_[1];
  }
  else {
    $rh_attr = pop if @_ % 2;
    %where = @_;
  }
  delete $rh_attr->{order_by};

  $class->can( 'retrieve_from_sql' )
    or $class->_croak( "$class should inherit from Class::DBI >= 0.95" );
  
  my ( %columns, %accessors ) = ();
  for my $column ( $class->columns ) {
    ++$columns{ $column };
    $accessors{ $column->accessor } = $column;
  }

  COLUMN: for my $column ( keys %where ) {
    # Column names are (of course) OK
    next COLUMN if exists $columns{ $column };

    # Accessor names are OK, but replace them with corresponding column name
    $where{ $accessors{ $column }} = delete $where{ $column }, next COLUMN
      if exists $accessors{ $column };

    # SQL::Abstract keywords are OK
    next COLUMN
      if $column =~ /^-(?:and|or|nest|(?:(not_)?(?:like|between)))$/;

    # Check for functions
    if ( index( $column, '(' ) > 0
      && index( $column, ')' ) > 1 )
    {
      my @tokens = ( $column =~ /(-?\w+(?:\s*\(\s*)?|\W+)/g );
      TOKEN: for my $token ( @tokens ) {
        if ( $token !~ /\W/ ) { # must be column or accessor name
          next TOKEN if exists $columns{ $token };
          $token = $accessors{ $token }, next TOKEN
            if exists $accessors{ $token };
          $class->_croak(
            qq{"$token" is not a column/accessor of class "$class"} );
        }
      }

      my $normalized = join "", @tokens;
      $where{ $normalized } = delete $where{ $column }
        if $normalized ne $column;
      next COLUMN;
    }

    $class->_croak( qq{"$column" is not a column/accessor of class "$class"} );
  }

  my ( $phrase, @bind ) = SQL::Abstract
    -> new( %$rh_attr )
    -> where( \%where );
  $class
    -> sql_count_search_where( $phrase )
    -> select_val( @bind );
}

1;
__END__

=head1 NAME

Class::DBI::Plugin::AbstractCount - get COUNT(*) results with abstract SQL

=head1 SYNOPSIS

  use base 'Class::DBI';
  use Class::DBI::Plugin::AbstractCount;
  
  my $count = Music::Vinyl->count_search_where(
    { artist   => 'Frank Zappa'
    , title    => { like    => '%Shut Up 'n Play Yer Guitar%' }
    , released => { between => [ 1980, 1982 ] }
    });

=head1 DESCRIPTION

This Class::DBI plugin combines the functionality from
Class::DBI::Plugin::CountSearch (counting objects without having to use an
array or an iterator), and Class::DBI::AbstractSearch, which allows complex
where-clauses a la SQL::Abstract.

=head1 METHODS

=head2 count_search_where

Takes a hashref with the abstract where-clause. An additional attribute hashref
can be passed to influence the default behaviour: arrayrefs are OR'ed, hashrefs
are AND'ed.

=head1 TODO

More tests, more doc.

=head1 SEE ALSO

=over

=item SQL::Abstract for details about the where-clause and the attributes.

=item Class::DBI::AbstractSearch

=item Class::DBI::Plugin::CountSearch

=back

=head1 AUTHOR

Jean-Christophe Zeus, E<lt>mail@jczeus.comE<gt> with some help from
Tatsuhiko Myagawa and Todd Holbrook.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jean-Christophe Zeus

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
