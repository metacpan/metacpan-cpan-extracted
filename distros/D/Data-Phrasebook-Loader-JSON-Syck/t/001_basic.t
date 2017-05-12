#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use FindBin;
use Data::Phrasebook;

BEGIN {
    use_ok('Data::Phrasebook::Loader::JSON::Syck');
}

my $pb = Data::Phrasebook->new(
    class  => 'Plain',
    loader => 'JSON::Syck',
    file   => File::Spec->catdir($FindBin::Bin, 'basic.json'),
);    
isa_ok($pb, 'Data::Phrasebook::Plain');

is($pb->fetch('bar', { my => 'JSON', place => 'world' }), 
   'Welcome to JSON world. It is a nice world.', 
   '... got the right text back');

$pb->delimiters( qr{ \[% \s* (\w+) \s* %\] }x );

is($pb->fetch('foo', { my => 'private', place => 'delusion' }), 
   'Welcome to private world. It is a nice delusion.', 
   '... got the right text back');