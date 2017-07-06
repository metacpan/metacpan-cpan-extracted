#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MAB2;
use Catmandu::Fix;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Bind::mab_each';
    use_ok $pkg;
}
require_ok $pkg;

my $fixer = Catmandu::Fix->new(fixes => [q|
	do mab_each()
		if mab_match("03.",'ger')
			add_field(is_ger,true)
		end
	end
|]);

my $importer = Catmandu::Importer::MAB2->new( file => './t/mab2.xml', type => "XML" );
my $record = $fixer->fix($importer->first);

ok exists $record->{record}, 'created a MAB2 record';
is $record->{is_ger}, 'true', 'created is_ger tag';

done_testing;