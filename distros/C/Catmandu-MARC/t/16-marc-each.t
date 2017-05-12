#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Bind::marc_each';
    use_ok $pkg;
}
require_ok $pkg;

my $fixer = Catmandu::Fix->new(fixes => [q|
	do marc_each()
		if marc_match("***a",'Perl')
			add_field(has_perl,true)
		end
		if marc_match("100",'.*')
			reject()
		end
		if marc_match(245a,'.*')
			marc_remove(245)
		end
	end
	marc_map("100",mainentry)
	marc_map("245",title)
|]);

my $importer = Catmandu::Importer::MARC->new( file => 't/camel.mrc', type => "ISO" );

$fixer->fix($importer)->each(sub {
	my $record = $_[0];
	my $id = $record->{_id};

	ok exists $record->{record}, "created a marc record $id";
	is $record->{has_perl}, 'true', "created has_dlc tag $id";
	ok ! exists $record->{mainentry} , "field 100 deleted $id";
	ok ! exists $record->{title} , "field 245 deleted $id";
});

done_testing;