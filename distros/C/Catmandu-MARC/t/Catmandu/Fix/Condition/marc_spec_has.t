#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use Catmandu::Fix;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::marc_spec_has';
    use_ok $pkg;
}

require_ok $pkg;


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
