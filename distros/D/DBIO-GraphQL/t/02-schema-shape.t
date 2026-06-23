use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use My::Schema;
use My::Test qw(deploy_schema);
use DBIO::GraphQL;

my $db = My::Schema->connect('dbi:SQLite:dbname=:memory:');
deploy_schema($db);

my $result = DBIO::GraphQL->to_graphql($db);

# Return shape
ok(ref $result eq 'HASH', 'to_graphql returns a hashref');
ok($result->{schema},     'hashref has a schema key'    );
ok($result->{context},    'hashref has a context key'   );
isa_ok($result->{schema}, 'GraphQL::Schema'             );

my $schema = $result->{schema};

# Query type
my $query = $schema->query;
ok($query, 'schema has a Query type');

my $qf = $query->fields;
ok(exists $qf->{author},           'Query has singular "author" field'  );
ok(exists $qf->{book},             'Query has singular "book" field'    );
ok(exists $qf->{allAuthors},       'Query has plural "allAuthors" field');
ok(exists $qf->{allBooks},         'Query has plural "allBooks" field'  );
ok(exists $qf->{author}{args}{id}, 'author query has id arg'            );
ok(exists $qf->{book}{args}{id},   'book query has id arg'              );

# Mutation type
my $mutation = $schema->mutation;
ok($mutation, 'schema has a Mutation type');

my $mf = $mutation->fields;
for my $source (qw( Author Book )) {
  ok(exists $mf->{"create$source"}, "Mutation has create$source");
  ok(exists $mf->{"update$source"}, "Mutation has update$source");
  ok(exists $mf->{"delete$source"}, "Mutation has delete$source");
}

# createAuthor arg nullability
my $create_args = $mf->{createAuthor}{args};

# name: non-nullable, no default, not auto-inc => NonNull
isa_ok($create_args->{name}{type}, 'GraphQL::Type::NonNull',
  'createAuthor.name is NonNull');

# id: auto-increment => not NonNull
ok(!$create_args->{id}{type}->isa('GraphQL::Type::NonNull'),
  'createAuthor.id is not NonNull (auto-increment)');

# active: has default_value => not NonNull
ok(!$create_args->{active}{type}->isa('GraphQL::Type::NonNull'),
  'createAuthor.active is not NonNull (has default)');

# updateAuthor / deleteAuthor include unique constraint col
for my $mut (qw( updateAuthor deleteAuthor )) {
  ok(exists $mf->{$mut}{args}{id},    "$mut has id arg (PK)");
  ok(exists $mf->{$mut}{args}{email}, "$mut has email arg (unique constraint)");
}

# Scalar types on Author
my $author_fields = $qf->{author}{type}->fields;

is($author_fields->{id}{type}->name,     'Int',     'Author.id is Int'        );
is($author_fields->{name}{type}->name,   'String',  'Author.name is String'   );
is($author_fields->{rating}{type}->name, 'Float',   'Author.rating is Float'  );
is($author_fields->{active}{type}->name, 'Boolean', 'Author.active is Boolean');

# Relationship fields
ok(exists $author_fields->{books}, 'Author type has a books field');
isa_ok($author_fields->{books}{type}, 'GraphQL::Type::List',
  'Author.books is a List type');

my $book_fields = $qf->{book}{type}->fields;
ok(exists $book_fields->{author}, 'Book type has an author field');
ok(!$book_fields->{author}{type}->isa('GraphQL::Type::List'),
  'Book.author is singular (non-list)');

# allBooks returns a connection type, not a bare list
my $all_books = $qf->{allBooks};
ok($all_books, 'allBooks query exists');
isa_ok($all_books->{type}, 'GraphQL::Type::Object',
  'allBooks returns a connection Object type');
is($all_books->{type}->name, 'BookConnection',
  'allBooks type is named BookConnection');

my $conn_fields = $all_books->{type}->fields;
ok(exists $conn_fields->{nodes},       'BookConnection has nodes field'      );
ok(exists $conn_fields->{total},       'BookConnection has total field'      );
ok(exists $conn_fields->{nextCursor},  'BookConnection has nextCursor field' );
ok(exists $conn_fields->{hasNextPage}, 'BookConnection has hasNextPage field');

# allBooks has filter, page, cursor, orderBy args
my $all_args = $all_books->{args};
ok(exists $all_args->{filter},  'allBooks has filter arg' );
ok(exists $all_args->{page},    'allBooks has page arg'   );
ok(exists $all_args->{cursor},  'allBooks has cursor arg' );
ok(exists $all_args->{orderBy}, 'allBooks has orderBy arg');

done_testing;
