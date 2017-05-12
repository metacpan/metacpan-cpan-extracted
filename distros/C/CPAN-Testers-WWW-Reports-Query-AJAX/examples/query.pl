#!/usr/bin/perl -w
use strict;

use lib qw(lib);

use Data::Dumper;
use CPAN::Testers::WWW::Reports::Query::AJAX;

# various argument sets for examples

my @args = (
    { 
        dist    => 'App-Maisha',
        version => '0.15',  # optional, will default to latest version
        format  => 'txt'
    },
    { 
        dist    => 'App-Maisha',
        version => '0.15',  # optional, will default to latest version
        format  => 'xml'
    },
    { 
        dist    => 'App-Maisha',
        version => '0.15',  # optional, will default to latest version
        format  => 'html'
    },
    { 
        dist    => 'App-Maisha',
        version => '0.15',  # optional, will default to latest version
        # default format = xml
    },
    { 
        dist    => 'App-Maisha',
        format  => 'txt'
    },
    { 
        dist    => 'App-Maisha',
        format  => 'xml'
    },
    { 
        dist    => 'App-Maisha',
        format  => 'html'
    },
    { 
        dist    => 'App-Maisha',
        # default format = xml
    }
);

my $query = CPAN::Testers::WWW::Reports::Query::AJAX->new( %{ $args[0] } );

exit    unless($query);

my $raw  = $query->raw();
my $data = $query->data();

print Dumper($raw);
print Dumper($data);
