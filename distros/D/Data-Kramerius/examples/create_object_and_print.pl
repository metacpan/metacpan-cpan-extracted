#!/usr/bin/env perl

use strict;
use warnings;

use Data::Kramerius::Object;

my $obj = Data::Kramerius::Object->new(
        'active' => 1,
        'id' => 'foo',
        'name' => 'Foo Kramerius',
        'url' => 'https://foo.example.com',
        'version' => 4,
);

# Print out.
print 'Active: '.$obj->active."\n";
print 'Id: '.$obj->id."\n";
print 'Name: '.$obj->name."\n";
print 'URL: '.$obj->url."\n";
print 'Version: '.$obj->version."\n";

# Output:
# Active: 1
# Id: foo
# Name: Foo Kramerius
# URL: https://foo.example.com
# Version: 4