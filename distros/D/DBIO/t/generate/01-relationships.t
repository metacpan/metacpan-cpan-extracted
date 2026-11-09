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
# ---------------------------------------------------------------------------
# karr k215: many_to_many bridges follow DBIx::Class::Schema::Loader.
#
# Loader (RelBuilder::_generate_m2ms, 0.07053) treats a table as a link table
# when it has exactly two belongs_to, its primary key equals the union of the
# two foreign keys, and -- unless allow_extra_m2m_cols is set -- it has no
# column beyond that key. allow_extra_m2m_cols RELAXES the last condition: it
# makes MORE bridges, never fewer. Ours had it inverted (a true value skipped
# every bridge, a false one bridged any two-FK table), and the bridge named the
# link table's belongs_to instead of the has_many that leads to the link table.
# ---------------------------------------------------------------------------

my %m2m_class_for = (
  Book    => 'My::Schema::Result::Book',
  Tag     => 'My::Schema::Result::Tag',
  BookTag => 'My::Schema::Result::BookTag',
  Loan    => 'My::Schema::Result::Loan',
);
my %m2m_pk_for = (
  Book    => [qw/id/],
  Tag     => [qw/id/],
  BookTag => [qw/book_id tag_id/],
  Loan    => [qw/id/],
);

sub link_tables {
  my $fk = sub { +{ local_columns => [ $_[0] ], remote_moniker => $_[1], remote_columns => [qw/id/], attrs => {} } };
  return [
    [ 'BookTag', [ $fk->('book_id', 'Book'), $fk->('tag_id', 'Tag') ], [] ],
    [ 'Loan',    [ $fk->('book_id', 'Book'), $fk->('tag_id', 'Tag') ], [] ],
    [ 'Book', [], [] ],
    [ 'Tag',  [], [] ],
  ];
}

sub m2ms_of {
  my ($code, $moniker) = @_;
  return [ map { $_->{args} } grep { $_->{method} eq 'many_to_many' } @{ $code->{$moniker} // [] } ];
}

sub has_many_to {
  my ($code, $moniker, $class) = @_;
  my ($rel) = grep { $_->{method} eq 'has_many' && $_->{args}[1] eq $class } @{ $code->{$moniker} };
  return $rel && $rel->{args}[0];
}

{
  my %cols_for = (
    BookTag => [qw/book_id tag_id/],
    Loan    => [qw/id book_id tag_id/],
  );
  my $code = DBIO::Generate::Relationships->new
    ->generate_code(link_tables(), \%m2m_class_for, \%m2m_pk_for, \%cols_for);

  my $bridge = has_many_to($code, 'Book', 'My::Schema::Result::BookTag');
  ok $bridge, 'Book has a has_many to the link table';
  is_deeply m2ms_of($code, 'Book'), [ [ 'tags', $bridge, 'tag' ] ],
    'pure link table (PK = both FKs, no extra column): bridged by default, '
    . 'through the has_many on Book and the belongs_to on the link table '
    . '(and Loan, a two-FK table with its own surrogate key, is not bridged)';
}

{
  my %cols_for = (
    BookTag => [qw/book_id tag_id added_at/],
    Loan    => [qw/id book_id tag_id/],
  );

  my $default = DBIO::Generate::Relationships->new
    ->generate_code(link_tables(), \%m2m_class_for, \%m2m_pk_for, \%cols_for);
  is_deeply m2ms_of($default, 'Book'), [],
    'link table with an extra column: no bridge by default';

  my $allowed = DBIO::Generate::Relationships->new(allow_extra_m2m_cols => 1)
    ->generate_code(link_tables(), \%m2m_class_for, \%m2m_pk_for, \%cols_for);
  is_deeply m2ms_of($allowed, 'Book'),
    [ [ 'tags', has_many_to($allowed, 'Book', 'My::Schema::Result::BookTag'), 'tag' ] ],
    'allow_extra_m2m_cols => 1 bridges the link table despite the extra column, '
    . 'and still requires PK = union of the FKs (Loan stays unbridged)';
}

{
  my $unknown = DBIO::Generate::Relationships->new
    ->generate_code(link_tables(), \%m2m_class_for, \%m2m_pk_for);
  is_deeply m2ms_of($unknown, 'Book'), [],
    'without column info extra columns cannot be ruled out: no bridge by default';
}

done_testing;
