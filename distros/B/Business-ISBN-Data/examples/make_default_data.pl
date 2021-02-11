#!/usr/bin/perl
use v5.10;
use open qw(:std :utf8);

use lib qw(lib);
use Business::ISBN::Data;



my $file = $ARGV[0];

my $data = Business::ISBN::Data::_parse_range_message( $file );

my $string = "\t(\n";

foreach my $key ( sort grep /^_/, keys %$data ) {
	my $value = "'$data->{$key}'";
	$value = '__FILE__' if $key eq '_source';
	$key   = '_data_date' if $key eq '_date';
	$string .= sprintf "\t%-10s => %s,\n", $key, $value;
	}

$string .= "\t978 => \{\n%%978%%\n\t\},\n\t979 => \{\n%%979%%\n\t\},\n\t);";

foreach my $k ( qw(978 979) ) {
	my $s = "\t\t" . join "\n\t\t",
		map {
			my $group = $data->{$k}{$_}[0];
			$group =~ s/'/\\'/g;

			my $numbers = join ", ", map { qq('$_') } $data->{$k}{$_}[1]->@*;

			my $s = sprintf q(%-5s => [ %-30s => [ %s ] ],), $_, qq('$group'), $numbers;
			$s;
			}
		sort { $a <=> $b }
		keys $data->{$k}->%*;

	$string =~ s/%%$k%%/$s/;
	}


say $string;


__END__

		     _date => Tue, 12 Jan 2021 10:43:54 GMT,
		   _serial => 0c5e7d67-d086-48c1-80f9-55319988b0c0,
		   _source => lib/Business/ISBN/RangeMessage.xml,
	(

