#!/usr/bin/env perl

use strict;
use warnings;

use Data::Kramerius::Object;

my $obj = Data::Kramerius::Object->new(
        'id' => 'foo',
        'name' => 'Foo Kramerius',
        'url' => 'https://foo.example.com',
        'version' => 4,
);

# Print out.
print 'Id: '.$obj->id."\n";
print 'Name: '.$obj->name."\n";
print 'URL: '.$obj->url."\n";
print 'Version: '.$obj->version."\n";

# Output:
# Id: foo
# Name: Foo Kramerius
# URL: https://foo.example.com
# Version: 4