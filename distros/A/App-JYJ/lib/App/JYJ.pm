package App::JYJ;

use strict;
use warnings;

our $VERSION = '0.0.2';

use JSON::PP;
use YAML::PP;
use IO::All;
use Mo;

sub run {
    my $input = io('-')->utf8->all;
    my $output;
    my $json = JSON::PP->new->pretty->indent_length(2);
    my $yaml = YAML::PP->new;
    if ($input =~ /\A\s*[\{\[]/) {
        my $data = $json->decode($input);
        $output = $yaml->dump($data);
    }
    else {
        my $data = $yaml->load_string($input);
        $output = $json->encode($data);
    }
    $output .= "\n" unless $output =~ /\n\z/;
    binmode(STDOUT, ":utf8");
    print $output;
}

1;
