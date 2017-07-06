#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;


my $fixes = <<EOF;
if marc_spec_has('LDR{/6=\\a}{/7=\\a|/7=\\c|/7=\\d|/7=\\m}')
  add_field(type,'Book')
end

if marc_spec_has('LDR{/6=\\a}{/7=\\b}')
  set_field(type,'Other')
end

EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);
my $importer = Catmandu::Importer::MARC->new( file => 't/camel9.mrc' );
my $records = $fixer->fix($importer)->to_array;

is $records->[0]->{type}, 'Book';

done_testing;
