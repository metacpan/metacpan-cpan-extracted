#!/usr/bin/perl
# $Id$

use strict;
use warnings;

use File::Basename 'dirname';
use Test::More;

use WebService::ISBNDB::API;

plan tests => 26;

my $dir = dirname $0;
do "$dir/DUMMY.pm";

WebService::ISBNDB::API->set_default_api_key('X');
WebService::ISBNDB::API->set_default_protocol('DUMMY');

use_ok('Catalyst::Model::ISBNDB');
ok(my $isbndb = Catalyst::Model::ISBNDB->new, 'created model');

ok(my $author = $isbndb->find_author('poe_edgar_allan'), 'fetched author');
isa_ok($author, 'WebService::ISBNDB::API::Authors');
is($author->get_name, 'Poe, Edgar Allan', 'Author name');

ok(my $book = $isbndb->find_book('0596002068'), 'fetched book by ISBN');
isa_ok($book, 'WebService::ISBNDB::API::Books');
is($book->get_title, 'Programming Web services with Perl', 'Book title');

ok(my $cat = $isbndb->find_category('science'), 'fetched category');
isa_ok($cat, 'WebService::ISBNDB::API::Categories');
is($cat->get_name, 'Science', 'Category name');

ok(my $pub = $isbndb->find_publisher('oreilly'), 'fetched publisher');
isa_ok($pub, 'WebService::ISBNDB::API::Publishers');
is($pub->get_name, "O'Reilly", 'Publisher name');

ok(my $subj = $isbndb->find_subject('perl_computer_program_language'),
   'fetched subject');
isa_ok($subj, 'WebService::ISBNDB::API::Subjects');
is($subj->get_name, 'Perl (Computer program language)', 'Subject name');

undef $isbndb;
delete Catalyst::Model::ISBNDB->config->{agent};
Catalyst::Model::ISBNDB->config(access_key => 'XXX');

ok($isbndb = Catalyst::Model::ISBNDB->new, 'created model');
isa_ok(my $agent = $isbndb->get_agent, 'WebService::ISBNDB::API');
is($agent->get_api_key, 'XXX', 'Catalyst-configured API key');
ok($book = $isbndb->find_book('programming_web_services_with_perl'),
   'fetched book by ID');
isa_ok($book, 'WebService::ISBNDB::API::Books');
is($book->get_title, 'Programming Web services with Perl', 'Book title');

ok(my $iter = $isbndb->search_books({ author => $author }), 'search_books');
isa_ok($iter, 'WebService::ISBNDB::Iterator');
is($iter->get_total_results, 252, 'Iterator results-set size');

exit;
