use strict;
use warnings;
use Test::More;

use App::Presto::Client::ContentHandlers::JSON;
use App::Presto::Client::ContentHandlers::HTML;
use App::Presto::Client::ContentHandlers::XMLSimple;

my %types = (
	JSON      => ['JSON.pm', 'application/json'],
	HTML      => ['HTML/FormatText/WithLinks.pm', 'text/html'],
	XMLSimple => ['XML/Simple.pm', 'application/xml'],
);

foreach my $t(keys %types){
	my $class = "App::Presto::Client::ContentHandlers::$t";
	my $ch = $class->new;
	isa_ok $ch, $class;
	my($file, $mime) = @{ $types{$t} };
	if ( $INC{$file} ) {
		ok $ch->can_deserialize($mime), "can deserialize $mime";
	} else {
		ok !$ch->can_deserialize($mime), "can not deserialize $mime";
	}
}

done_testing;
