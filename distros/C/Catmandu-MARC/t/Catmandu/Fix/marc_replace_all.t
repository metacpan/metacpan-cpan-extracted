#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::marc_replace_all';
    use_ok $pkg;
}

require_ok $pkg;

#---
{
	my $fixer = Catmandu::Fix->new(fixes => [q|marc_replace_all('100a','Tobias','John')|,q|marc_map('100a','test')|]);
	my $importer = Catmandu::Importer::MARC->new( file => 't/camel.mrc', type => "ISO" );
	my $record = $fixer->fix($importer->first);

	like $record->{test}, qr/^Martinsson, John,$/, q|fix: marc_replace_all('100a','Tobias','John')|;
}

#---
{
	my $fixer = Catmandu::Fix->new(fixes => [q|marc_replace_all('630','Active','Silly')|,q|marc_map('630a','test.$append')|]);
	my $importer = Catmandu::Importer::MARC->new( file => 't/camel.mrc', type => "ISO" );
	my $record = $fixer->fix($importer->first);

	is_deeply $record->{test}, [
        'Silly server pages.' ,
        'SillyX.'
    ], q|fix: marc_replace_all('630a','Active','Silly')|;
}


#---
{
	my $fixer = Catmandu::Fix->new(fixes => [q|marc_replace_all('630','(Active)','{$1}')|,q|marc_map('630a','test.$append')|]);
	my $importer = Catmandu::Importer::MARC->new( file => 't/camel.mrc', type => "ISO" );
	my $record = $fixer->fix($importer->first);

	is_deeply $record->{test}, [
        '{Active} server pages.' ,
        '{Active}X.'
    ], q|fix: marc_replace_all('630a','Active','{Active}')|;
}

done_testing;
