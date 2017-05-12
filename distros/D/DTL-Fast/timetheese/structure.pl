#!/usr/bin/perl -I../lib/

use Benchmark qw(:all);
use DTL::Fast qw(get_template);
use Storable qw(freeze);
use Compress::Zlib;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $tpl = get_template(
#    'root.txt',
    'parent.txt',
    'dirs' => [ './tpl' ]
);
print Dumper($tpl);

open OF, '>', 'structure.cache';
binmode OF;
print OF Compress::Zlib::memGzip(freeze($tpl));
close OF;