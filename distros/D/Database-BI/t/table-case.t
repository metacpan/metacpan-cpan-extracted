#!/usr/bin/env perl

# A table whose file name has a capital letter.  table:<name> was looked up in
# lower case only, so BandMusic.csv opened on its own page (/view/BandMusic)
# and nowhere else: a pivot, chart, merge or column list of table:BandMusic
# was a 404.  The name as written is tried first, then lower case, which every
# reader used to ask for, so table:SHOP still opens shop.csv.
#
#   prove -l t/table-case.t

use strict;
use warnings;

use File::Temp qw(tempdir);
use Mojo::File;
use Test::Most;
use Test::Mojo;

my $data_dir  = Mojo::File->new(tempdir(CLEANUP => 1));
my $model_dir = tempdir(CLEANUP => 1);
$data_dir->child('BandMusic.csv')->spew("id,title,kind\n1,March,5\n2,Waltz,8\n3,Polka,5\n");
$data_dir->child('shop.csv')->spew("id,kind,label\n1,5,brass\n2,8,reed\n");

# macOS and Windows find BandMusic.csv by any case, so lower case there is
# that file, and table:SHOP is SHOP.csv.
my $folds_case = -f $data_dir->child('bandmusic.csv');

my $t = Test::Mojo->new('Database::BI', { data_dir => $data_dir->to_string, model_dir => $model_dir });

subtest 'a capital in the file name' => sub {
	$t->get_ok('/view/BandMusic')->status_is(200, 'its own page, as before');
	$t->get_ok('/pivot?l=table:BandMusic&rows=kind&m=id:count:n')->status_is(200, 'a pivot')
		->content_like(qr/<td[^>]*>5<\/td>/);
	$t->get_ok('/bar?l=table:BandMusic&cat=kind&val=id')->status_is(200, 'a chart');
	$t->get_ok('/api/columns?table=BandMusic')->status_is(200, 'its columns')
		->json_has('/columns');
	$t->get_ok('/join?l=table:BandMusic&j=' . Mojo::Util::url_escape('table:shop|kind|kind'))
		->status_is(200, 'merged with another table')->content_like(qr/brass/);
	$t->get_ok('/join?l=table:shop&j=' . Mojo::Util::url_escape('table:BandMusic|kind|kind'))
		->status_is(200, 'and as the table merged in')->content_like(qr/Waltz/);
};

subtest 'lower case as before' => sub {
	$t->get_ok('/pivot?l=table:SHOP&rows=kind&m=id:count:n')->status_is(200, 'table:SHOP opens shop.csv');
	$t->get_ok('/api/columns?table=Shop')->status_is(200, 'and so does table=Shop');
	SKIP: {
		skip 'the filesystem ignores case', 2 if $folds_case;
		$t->get_ok('/pivot?l=table:bandmusic&rows=kind&m=id:count:n')->status_is(404,
			'lower case does not find a file named with capitals: the name is not folded the other way');
	}
	$t->get_ok('/pivot?l=table:Nosuch&rows=kind&m=id:count:n')->status_is(404, 'no file is still a 404');
};

subtest '_table_stem' => sub {
	my $stem = \&Database::BI::Controller::Dashboard::_table_stem;
	is($stem->($data_dir, 'BandMusic'), 'BandMusic', 'as written');
	is($stem->($data_dir, 'SHOP'), $folds_case ? 'SHOP' : 'shop', 'else lower case');
	is($stem->($data_dir, 'nosuch'), undef, 'else none');
	is($stem->($data_dir, 'BandMusic', 'json'), undef, 'only with the extensions asked for');
};

done_testing();
