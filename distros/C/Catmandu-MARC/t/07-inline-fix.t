use strict;
use warnings;
use Catmandu::Util;
use Test::More;

use Catmandu::Fix::Inline::marc_map qw(marc_map);
use Catmandu::Fix::Inline::marc_add qw(marc_add);
use Catmandu::Fix::Inline::marc_set qw(marc_set);
use Catmandu::Fix::Inline::marc_remove qw(marc_remove);
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
	is scalar marc_map($records->[0],'245a'), q|ActivePerl with ASP and ADO /|, q|marc_map(245a)|;
	is scalar marc_map($records->[0],'001') , q|fol05731351| , q|marc_map(001)|;
	ok ! defined(scalar marc_map($records->[0],'191')) , q|marc_map(191) not defined|;
	ok ! defined(scalar marc_map($records->[0],'245x')) , q|marc_map(245x) not defined|;
}

{
	my @res = marc_map($records->[0],'630');
	is_deeply \@res , [ 'Active server pages.' , 'ActiveX.' ] , q|marc_map(630) as array|;

    my $res = marc_map($records->[0],'630');
    is $res , 'Active server pages.ActiveX.' , q|marc_map(630) as string|;

    my $res2 = marc_map($records->[0],'630', -join => "; ");
    is $res2 , 'Active server pages.; ActiveX.' , q|marc_map(630) as string joined|;
}

{
	my $rec = marc_add($records->[0],'900', a => 'test');
	is scalar marc_map($rec,'900a'), q|test|, q|marc_add(900)|;
}

{
	my $rec = marc_add($records->[0],'901', a => '$.my.deep.field');
	is scalar marc_map($rec,'901a'), q|foo|, q|marc_add(901)|;
}

{
	my $rec = marc_add($records->[0],'902', a => '$.my.deep.array');
	is scalar marc_map($rec,'902a'), q|redgreenblue|, q|marc_add(902)|;
}

{
	my $rec = marc_set($records->[0],'010b', 'test');
	is scalar marc_map($rec,'010b'), q|test|, q|marc_set(010)|;
}

{
	my $rec = marc_set($records->[0],'010b', '$.my.deep.field');
	is scalar marc_map($rec,'010b'), q|foo|, q|marc_set(010)|;
}

{
	my $rec = marc_remove($records->[0],'900');
	ok ! defined scalar marc_map($rec,'900a') , q|marc_map(900) removed|;
}

{
	my $f050 = marc_map($records->[0],'050ba',-pluck=>1);
	is $f050 , "M33 2000QA76.73.P22" , q|pluck test|;
}

{
	my $f260c = marc_map($records->[0],'260c',-value=>'OK');
	is $f260c , "OK" , q|value test|;
}

{
	my $f260h = marc_map($records->[0],'260h',-value=>'BAD');
	ok ! $f260h , q|value test|;
}

{
	my @arr = marc_map($records->[0],'245a/0-3',-split=>1);
	is $arr[0][0] , q|Acti|;
}

{
	my @arr = marc_map($records->[0],'630',-split=>1);
	ok @arr == 2;
    is ref($arr[0]) , 'ARRAY' , 'got an array of arrays';
}

{
	my @arr = marc_map($records->[0],'630',-split=>1, '-nested_arrays' => 0);
	ok @arr == 2;
    is ref($arr[0]) , '' , 'got an array of strings';
}

{
	my @arr = marc_map($records->[1],'020a',-split=>1);
	ok @arr == 2;
}

{
	my @arr = marc_map($records->[1],'300bxa', -split=>1 , -pluck=>1);

    is_deeply \@arr , [[
         'ill. ;' ,
         undef ,
         'xxi, 289 p. :',
    ]] , 'marc_map(300bxa, split:1 , pluck: 1)';
}

{
	my @arr = marc_map($records->[1],'630xa', -split=>1 , -pluck=>1);

    is_deeply \@arr , [
         [ undef ,
           'Active server pages.',
         ] ,
         [ undef,
           'ActiveX.'
         ] ,
    ] , 'marc_map(630xa, split:1 , pluck:1)';
}

done_testing;
