use 5.010;
use strict;
use warnings;

use Acme::What;
use URI::FromHash qw(uri);
use XML::LibXML 1.70;

sub WHAT
{
	my @args = $_[0] =~ m{\w+}g;
	
	my $woeid = pop @args;
	$woeid = do {
		warn "If you want to know the weather $woeid, "
			. "define the YAHOO_WOEID environment variable. "
			. "Assuming you live where TOBYINK lives"
			unless exists $ENV{YAHOO_WOEID}
				 && defined $ENV{YAHOO_WOEID};
		($ENV{YAHOO_WOEID} // 26191)
	} if $woeid =~ m{^(outside|here)$}i;
	
	my $unit = ($ENV{LC_MEASUREMENT}//"" =~ /^.._(US|BZ)/i) ? "F" : "C";
	
	my $xml_location = uri(
		scheme => 'http',
		host   => 'weather.yahooapis.com',
		path   => '/forecastrss',
		query  => { w => $woeid, u => lc $unit },
		query_separator => '&',  ## URI::FromHash has stupid defaults
	);
	
	my ($temperature) = XML::LibXML
		-> load_xml(location => $xml_location)
		-> findnodes('//yweather:condition/@temp')
		-> map(sub { $_->value });	
	
	return "$temperature $unit";
}

local $^F = 1;
my $temperature=what? (i mean outside);
say "The temperature is $temperature";
