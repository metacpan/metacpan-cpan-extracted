#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Text::CSV;
use LWP::UserAgent;
use IO::String;
use PDL::Factor;

use Data::Frame;
use Data::Frame::Rlike;

my $url = 'http://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data';

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
	or die "Cannot use CSV: ".Text::CSV->error_diag ();

my $fh = IO::String->new( LWP::UserAgent->new->get($url)->decoded_content );
my @column_names = ( 'sepal length', 'sepal width', 'petal length', 'petal width', 'species');
$csv->column_names( @column_names );

my $column_data;
while (my $data = $csv->getline($fh)) {
	if( @$data == @column_names ) {
		$data->[4] =~ s/^Iris-//;
		push @{ $column_data->[$_] }, $data->[$_] for 0..@column_names-1;
	}
}

my $df =  Data::Frame->new(
	columns => [
		( map { $column_names[$_] => pdl(  $column_data->[$_] ) } 0..3 ),
		$column_names[4] => PDL::Factor->new(  $column_data->[4] )
	]
);

print $df, "\n";

print $df->subset( sub { ( $_->('sepal length') > 6.0 ) & ( $_->('petal width') < 2 ) }  ), "\n";

#use DDP; p $df->column('species')->string;

