use strict;
use warnings;
use Test::More;

use DBIO::Generate::Relationships;

my $r = DBIO::Generate::Relationships->new;

# Simple belongs_to + has_many from a single FK
#   books.author_id → authors.id

my $class_for = {
  Book   => 'My::Schema::Result::Book',
  Author => 'My::Schema::Result::Author',
};

my $pk_for = {
  Book   => [qw/id/],
  Author => [qw/id/],
};

# tables: [ [ moniker, \@fk_info, \@uniq_info ], ... ]
# fk_info items have remote_moniker (pre-resolved) not remote_table
my $tables = [
  [ 'Book',
    [ {
        local_columns  => [qw/author_id/],
        remote_moniker => 'Author',
        remote_columns => [qw/id/],
        attrs          => {},
      }
    ],
    [],
  ],
  [ 'Author', [], [] ],
];

my $code = $r->generate_code($tables, $class_for, $pk_for);

# Book side: belongs_to 'author'
my @book_rels = @{ $code->{Book} // [] };
is scalar(@book_rels), 1, 'Book has one rel';
is $book_rels[0]{method}, 'belongs_to', 'Book→Author is belongs_to';
is $book_rels[0]{args}[0], 'author', 'belongs_to rel name is "author"';
is $book_rels[0]{args}[1], 'My::Schema::Result::Author', 'remote class correct';

# Author side: has_many 'books'
my @author_rels = @{ $code->{Author} // [] };
is scalar(@author_rels), 1, 'Author has one rel';
is $author_rels[0]{method}, 'has_many', 'Author→Book is has_many';
is $author_rels[0]{args}[0], 'books', 'has_many rel name is "books"';
is $author_rels[0]{args}[1], 'My::Schema::Result::Book', 'remote class correct';

done_testing;