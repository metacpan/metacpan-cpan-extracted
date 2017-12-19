use strict;
use warnings;
use Catmandu::Util;
use Test::More tests => 16;

use Catmandu::Fix::marc_map as => 'marc_map';
use Catmandu::Fix::marc_add as => 'marc_add';
use Catmandu::Fix::marc_set as => 'marc_set';
use Catmandu::Fix::marc_remove as => 'marc_remove';
use Catmandu::Fix::marc_xml as => 'marc_xml';

use Catmandu::Importer::JSON;

my $importer = Catmandu::Importer::JSON->new( file => 't/old_new.json' );

my $fixer = Catmandu::Fix->new(fixes => [
	q|add_field(my.deep.field,foo)|,
	q|add_field(my.deep.array.$append,red)|,
	q|add_field(my.deep.array.$append,green)|,
	q|add_field(my.deep.array.$append,blue)|,
]);

my $records = $fixer->fix($importer)->to_array;

ok(@$records == 2 , "Found 2 records");

{
	is marc_map($records->[0],'245a','title')->{title}, q|ActivePerl with ASP and ADO /|, q|marc_map(245a)|;
	is marc_map($records->[0],'001','id')->{id} , q|fol05731351| , q|marc_map(001)|;
	ok ! defined(scalar marc_map($records->[0],'191','test')->{test}) , q|marc_map(191) not defined|;
	ok ! defined(scalar marc_map($records->[0],'245x','test')->{test}) , q|marc_map(245x) not defined|;
}

{
	my $res = marc_map($records->[0],'630','test.$append')->{test};
	ok(Catmandu::Util::is_array_ref($res), q|marc_map(630)|);
}

{
	marc_add($records->[0],'900', a => 'test');
	is scalar marc_map($records->[0],'900a','test')->{test}, q|test|, q|marc_add(900)|;
}

{
	marc_add($records->[0],'901', a => '$.my.deep.field');
	is scalar marc_map($records->[0],'901a','test2')->{test2}, q|foo|, q|marc_add(901)|;
}

{
	marc_add($records->[0],'902', a => '$.my.deep.array');
	is scalar marc_map($records->[0],'902a','test3')->{test3}, q|redgreenblue|, q|marc_add(902)|;
}

{
	marc_set($records->[0],'010b', 'test');
	is scalar marc_map($records->[0],'010b','test4')->{test4}, q|test|, q|marc_set(010)|;
}

{
	marc_set($records->[0],'010b', '$.my.deep.field');
	is scalar marc_map($records->[0],'010b','test5')->{test5}, q|foo|, q|marc_set(010)|;
}

{
	marc_remove($records->[0],'900');
	ok ! defined scalar marc_map($records->[0],'900a','test6')->{test6} , q|marc_map(900) removed|;
}

{
	my $f050 = marc_map($records->[0],'050ba','test7',-pluck=>1)->{test7};
	is $f050 , "M33 2000QA76.73.P22" , q|pluck test|;
}

{
	my $f260c = marc_map($records->[0],'260c','test8',-value=>'OK')->{test8};
	is $f260c , "OK" , q|value test|;
}

{
	my $f260h = marc_map($records->[0],'260h','test9',-value=>'BAD')->{test9};
	ok ! $f260h , q|value test|;
}

{
	my $xml = marc_xml($records->[0],'record')->{record};
	like $xml , qr/.*xmlns.*/ , q|marc_xml|;
}
