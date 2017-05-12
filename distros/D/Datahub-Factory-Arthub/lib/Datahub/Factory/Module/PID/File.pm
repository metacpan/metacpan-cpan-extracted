package Datahub::Factory::Module::PID::File;

use strict;
use warnings;

use Catmandu;
use Moose::Role;

use URI::Split qw(uri_split);

has path => (is => 'lazy');

sub netloc {
    my ($self, $base_url) = @_;
    my @url = uri_split($base_url);
    if ($url[0] =~ /^https/) {
        return sprintf('%s:443', $url[1]);
    } else {
        return sprintf('%s:80', $url[1]);
    }
}

1;