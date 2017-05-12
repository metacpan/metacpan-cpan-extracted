package Acme::IsItJSON;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/is_it_json/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
use JSON::Parse qw/parse_json valid_json/;
use JSON::Create 'create_json';
our $VERSION = '0.02';

my @responses = (
    "That seems to be {X}.",
    "That might be {X}.",
    "I'm not sure whether that is {X}.",
    "It could be {X}.",
    "OK, it's definitely {X}. Maybe.",
);

sub babble
{
    my ($what) = @_;
    my $response = $responses[int (rand (scalar (@responses)))];
    $response =~ s/\{X\}/$what/;
    if (rand (2) > 1) {
	$response = create_json ($response);
    }
    print "$response\n";
}

sub is_it_json
{
    my ($input) = @_;
    if (valid_json ($input)) {
	babble ('JSON');
    }
    else {
	babble ('a Perl data structure');
    }
}

1;
