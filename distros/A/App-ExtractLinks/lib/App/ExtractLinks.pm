package App::ExtractLinks;

# ABSTRACT: extract href's in HTML docs to stdout

use strict;
use warnings;

use HTML::Parser;

our $VERSION;

BEGIN {
    $VERSION = '0.0.3';
}

my $parser = HTML::Parser->new(api_version => 3);

sub handler {
    my ($attr) = @_;

    foreach my $key (keys %{$attr}) {
        my $val = ${$attr}{$key};

        if ($key eq 'href' || $key eq 'src') {
            chomp $val;
            $val ne '' && print "$val\n";
        }
    }
}

sub run {
    $parser->handler(start => \&handler, 'attr');

    while (<>) {
        $parser->parse($_); 
    }

    $parser->eof;
}

1;

=head1 NAME

ExtractLinks

=head1 DESCRIPTION

Extract hrefs from HTML documents to stdout.

