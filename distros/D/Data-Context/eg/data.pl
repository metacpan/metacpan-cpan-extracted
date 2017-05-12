#!/usr/bin/perl

# Created on: 2012-07-19 20:40:11
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use FindBin qw/$Bin/;
use Path::Tiny;
use AnyEvent;
use AnyEvent::HTTP;
use Data::Context;

my $path = path($0)->parent->child('dc');
my $dc   = Data::Context->new( path => "$path" );

# process the template index.dc.js with context data
my $data = $dc->get(
    'index',
    {
        test => {
            value => [
                'first',
                'second',
            ],
        },
    }
);

# print out data which is a combination of
# the local context
# index.dc.js
# _default.dc.js
# and module processing
print Dumper $data;

# config specifies MODULE to be main so that this method will be called
sub get_data {
    my ($self, $data ) = @_;

    my $cv = AnyEvent->condvar;

    http_get $data->{url}, sub { $cv->send( length $_[0] ); };

    return $cv;
}

