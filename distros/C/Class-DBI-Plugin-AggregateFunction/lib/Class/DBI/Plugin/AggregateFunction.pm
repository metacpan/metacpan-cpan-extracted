package Class::DBI::Plugin::AggregateFunction;
use strict;
use vars qw/$VERSION/;
$VERSION = '0.02';

use SQL::Abstract;

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

    $class->set_sql( "AggregateFunction_$aggregate_func" => <<__SQL__ );
  SELECT $aggregate_func( %s )
  FROM   __TABLE__
  WHERE  %s
__SQL__

    no strict 'refs';
    *{"$class\::$alias"} = sub {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $aggregate_column = shift;

	my $where = (ref $_[0]) ? $_[0]          : { @_ };
	my $attr  = (ref $_[0]) ? $_[1]          : undef;

	my $sql = SQL::Abstract->new(%$attr);
	my($phrase, @bind) = $sql->where($where);
	$phrase =~ s/^\s*WHERE\s*//i;
	$phrase = ' 1 = 1 ' unless $phrase;

	my $sql_method = "sql_AggregateFunction_$aggregate_func";
	my $sth = $class->$sql_method( $aggregate_column, $phrase );

	return $sth->select_val( @bind );
    }
}

1;
__END__

=head1 NAME

Class::DBI::Plugin::AggregateFunction - aggregate function for Class::DBI

=head1 SYNOPSYS

  package MyData::CD;
  use base qw/Class::DBI/;
  use Class::DBI::Plugin::AggregateFunction;
  __PACKAGE__->mk_aggregate_function('sum');
  __PACKAGE__->mk_aggregate_function( max => 'maximum');
  
  package main;
  # SELECT MAX(price) FROM __TABLE__
  $max = MyData::CD->maximum( 'price' );
  
  # SELECT SUM(price) FROM __TABLE__ WHERE artist = 'foo'
  $sum = MyData::CD->sum( 'price', artist => 'foo', );
  $sum = MyData::CD->sum( 'price', {
  	price => {'>=', 1000},
  });

=head1 DESCRIPTION

This module is for using an aggregate function easily by Class::DBI.

=head1 HOW TO USE

=head2 Make Metod of Aggregate Function

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

It is the same as the search_where method of Class::DBI::AbstractSearch
after the 2nd argument.

  # SELECT SUM(price) FROM __TABLE__ WHERE artist = 'foo'
  $total_price = MyData::CD->sum( 'price',
  	'artist' => 'foo',
  );

or 

  # SELECT SUM(price) FROM __TABLE__ WHERE price >= 1000
  $total_price = MyData::CD->sum( 'price', {
  	'price' => {'>=', 1000},
  });


=head1 AUTHOR

ASAKURA Takuji <asakura.takuji+cpan@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI::AbstractSearch>, L<Class::DBI>

=cut
