package Class::DBI::Sweet::Pie;
use strict;
use vars qw/$VERSION/;
$VERSION = '0.04';

sub import {
    my $class = shift;
    my $pkg = caller(0);

    no strict 'refs';
    *{"$pkg\::mk_aggregate_function"} = \&mk_aggregate_function;
}

sub mk_aggregate_function {
    my $class = shift;
    my ($aggregate_func, $alias) = @_;
    $alias ||= $aggregate_func;

    ## create aggregate function
    my $sql_aggregate = "sql_Join_AggregateFunction_$alias";
    $class->set_sql( "Join_AggregateFunction_$alias" => <<__SQL__ );
  SELECT $aggregate_func( %s )
  FROM   %s
  WHERE  %s
__SQL__

    no strict 'refs';
    *{"$class\::$alias"} = sub {
	my $self = shift;
	my $aggregate_column = shift;
	return $self->_attr( $alias ) unless defined $aggregate_column;

	my $class = ref $self || $self;
	my ($criteria, $attributes) = $class->_search_args(@_);

	$aggregate_column =~ s/^ (distinct) \s+ //ix;
	my $distinct = $1 || '';

	if ($aggregate_column eq "*") {
	    ;
	}
	elsif ($aggregate_column =~ /^(\w+)\.(.+)$/) {
	    my $join = $1;
	    $aggregate_column = "*" if $2 eq '*';

	    if (ref $self) {
	        $attributes->{prefetch} = [ $join ];
	        foreach my $pcol ($self->primary_column) {
	            $criteria->{ $pcol } = $self->$pcol;
	        }
	    }
	    else {
	        $criteria->{ $join } = \"IS NOT NULL"
	        	unless exists $criteria->{ $join };
	    }
	}
	else {
	    $aggregate_column = "me.$aggregate_column";
	}

	$aggregate_column = "$distinct $aggregate_column" if $distinct;

	# make sure we take copy of $attribues since it can be reused
	my $agfunc_attr = { %{$attributes} };

	# no need for LIMIT/OFFSET and ORDER BY in AGGREGATE_FUNC()
	delete @{$agfunc_attr}{qw( rows offset order_by )};

	my ($sql_parts, $classes, $columns, $values) = $class->_search( $criteria, $agfunc_attr );

	my $sth = $class->$sql_aggregate( $aggregate_column, @{$sql_parts}{qw/ from where /} );

	$class->_bind_param( $sth, $columns );
	return $sth->select_val(@$values);
    };

    ## create search with aggregate function
    my $sql_with_aggregate = "sql_Join_Retrieve_$alias";
    $class->set_sql( "Join_Retrieve_$alias" => <<__SQL__ );
  SELECT __ESSENTIAL(me)__, $aggregate_func( %s ) AS $alias
  FROM   %s
  WHERE  %s
  GROUP BY __ESSENTIAL(me)__
  %s %s
__SQL__

    *{"$class\::search_with_$alias"} = sub {
	my $self = shift;
	my $class = ref($self) || $self;
	my $aggregate_column = shift;
	my ($criteria, $attributes) = $class->_search_args(@_);

	$aggregate_column =~ s/^ (distinct) \s+ //ix;
	my $distinct = $1 || '';

	if ($aggregate_column eq "*") {
	    ;
	}
	elsif ($aggregate_column =~ /^(\w+)\.(.+)$/) {
	    my $join = $1;
	    $aggregate_column = "*" if $2 eq '*';

	    $criteria->{ $join } = \"IS NOT NULL"
	    	unless exists $criteria->{ $join };
	}
	else {
	    $aggregate_column = "me.$aggregate_column";
	}

	$aggregate_column = "$distinct $aggregate_column" if $distinct;

	my ($sql_parts, $classes, $columns, $values) = $class->_search( $criteria, $attributes );

	my $sth = $class->$sql_with_aggregate( $aggregate_column, @{$sql_parts}{qw/ from where order_by limit /} );

        $self->sth_to_objects( $sth, $values );
    };
}

1;
__END__

=head1 NAME

Class::DBI::Sweet::Pie - aggregate function for Class::DBI::Sweet

=head1 SYNOPSYS

  package MyData::CD;
  use base qw/Class::DBI::Sweet/;
  __PACKAGE__->has_a( artist => 'MyData::Artist' );
  use Class::DBI::Sweet::Pie;
  __PACKAGE__->mk_aggregate_function('sum');
  __PACKAGE__->mk_aggregate_function( max => 'maximum');
  
  package MyData::Artist;
  use base qw/Class::DBI::Sweet/;
  __PACKAGE__->has_many( cds => 'MyData::CD' );
  use Class::DBI::Sweet::Pie;
  __PACKAGE__->mk_aggregate_function('min');
  __PACKAGE__->mk_aggregate_function( max => 'maximum');
  
  package main;
  
  $max_price = MyData::CD->maximum( 'price' );
  
  $total_price = MyData::CD->sum( 'price',
  	{ 'artist.name' => 'foo', }
  );

  $artist = MyData::Artist->search( name => 'foo' );
  $min_price = $artist->min('cds.price');

=head1 DESCRIPTION

This module is for using an aggregate function easily by Class::DBI::Sweet.

=head1 HOW TO USE

=head2  Make Metod of Aggregate Function

The aggregate function is added by using the mk_aggregate_function method. 

The 1st argument is an aggregate function used by SQL. 

The 2nd argument is a method name.
When it is omitted, the aggregate function becomes a method name. 

  __PACKAGE__->mk_aggregate_function( 'max' );

or

  __PACKAGE__->mk_aggregate_function( 'max' => 'maximum' );

=head2 Use Metod of Aggregate Function

The 1st argument of the aggregate function method is the target column name.

  $max_price = MyData::CD->maximum( 'price' );

It is the same as the search method of Class::DBI::Sweet
after the 2nd argument.

  # SELECT SUM(price) FROM __TABLE__ WHERE artist = 'foo'
  $total_price = MyData::CD->sum( 'price',
  	'artist' => 'foo',
  );

or 

  # SELECT SUM(price) FROM __TABLE__ WHERE price >= 1000
  $total_price = MyData::CD->sum( 'price',
      {
  	'price' => {'>=', 1000},
      }
  );


  $max_price = MyData::Artist->maximum( 'cds.price' );


  $artist = MyData::Artist->search( name => 'foo' );
  $min_price = $artist->min('cds.price');


=head2 search_with_*

  my @artists = MyData::Artist->search( $criteria );
  foreach my $artist (@artists) {
    print $artist->name, "\t", $artist->maximum('cds.price'), "\n";
  }

  my @artists = MyData::Artist->search_with_maximum( 'cds.price', $criteria );
  foreach my $artist (@artists) {
    print $artist->name, "\t", $artist->maximum, "\n";
  }

  my @artists = MyData::Artist->search_with_maximum( 'cds.price',
  	$criteria,
  	{order_by => 'maximum DESC'}
  );


=head1 AUTHOR

ASAKURA Takuji <asakura.takuji+cpan@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI::Sweet>

L<Class::DBI::Plugin::AggregateFunction>

=cut
