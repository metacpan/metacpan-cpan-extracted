#!/usr/local/bin/perl

use Test::More tests => 4;

my $class  = 'CPAN::PackageDetails::Header';
my $method = 'format_date';

use_ok( $class ) or BAIL_OUT( "$class did not load" );
can_ok( $class, $method ) or BAIL_OUT( "$class cannot $method" );

my %CPANPM_regexes = (
	'1.9201' => qr/ (\d+) (\w+) (\d+) (\d+):(\d+):(\d+) /,
	);
	
my $date = $class->format_date;
foreach my $key ( keys %CPANPM_regexes )
	{
	my $regex = $CPANPM_regexes{ $key };
	is( ref $regex, ref qr//, "Value for $key is a regex" );
	ok( $date =~ m/$regex/, "Matches regex for $key" );
	}
	
