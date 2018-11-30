use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use lib 't/lib';
use TestFor::DBIx::Class::Smooth::Schema;
use experimental qw/postderef/;

my $schema = TestFor::DBIx::Class::Smooth::Schema->connect();

isa_ok $schema, 'DBIx::Class::Schema';

my $relationships = [sort $schema->Book->result_source->relationships];
is_deeply ($relationships, [sort qw/editions book_authors/], 'Books relationships') or diag explain $relationships;

my $relationship_info = $schema->Book->result_source->relationship_info('editions');
my $expected_relationship_info = {
    'attrs' => {
        'accessor' => 'multi',
        'cascade_copy' => 1,
        'cascade_delete' => 1,
        'is_depends_on' => 0,
        'join_type' => 'LEFT'
    },
    'class' => 'TestFor::DBIx::Class::Smooth::Schema::Result::Edition',
    'cond' => {
        'foreign.book_id' => 'self.id'
    },
    'source' => 'TestFor::DBIx::Class::Smooth::Schema::Result::Edition'
};
is_deeply ($relationship_info, $expected_relationship_info, 'Got expected relationship info') or diag explain $relationship_info;



$relationships = [sort $schema->BookAuthor->result_source->relationships];
is_deeply ($relationships, [sort qw/book author/], 'BookAuthor relationships') or diag explain $relationships;

$relationship_info = $schema->BookAuthor->result_source->relationship_info('author');
is ($relationship_info->{'class'}, 'TestFor::DBIx::Class::Smooth::Schema::Result::Author', 'BookAuthor->author') or diag explain $relationship_info;

my $rev_relationship_info = $schema->BookAuthor->result_source->reverse_relationship_info('author');
is ($rev_relationship_info->{'book_authors'}{'class'}, 'TestFor::DBIx::Class::Smooth::Schema::Result::BookAuthor', 'BookAuthor<-author') or diag explain $rev_relationship_info;

done_testing;
