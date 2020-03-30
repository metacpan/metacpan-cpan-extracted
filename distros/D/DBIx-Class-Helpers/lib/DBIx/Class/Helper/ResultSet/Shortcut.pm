package DBIx::Class::Helper::ResultSet::Shortcut;
$DBIx::Class::Helper::ResultSet::Shortcut::VERSION = '2.036000';
# ABSTRACT: Shortcuts to common searches (->order_by, etc)

use strict;
use warnings;

use parent (qw(
   DBIx::Class::Helper::ResultSet::Shortcut::AddColumns
   DBIx::Class::Helper::ResultSet::Shortcut::Columns
   DBIx::Class::Helper::ResultSet::Shortcut::Distinct
   DBIx::Class::Helper::ResultSet::Shortcut::GroupBy
   DBIx::Class::Helper::ResultSet::Shortcut::HasRows
   DBIx::Class::Helper::ResultSet::Shortcut::HRI
   DBIx::Class::Helper::ResultSet::Shortcut::Limit
   DBIx::Class::Helper::ResultSet::Shortcut::OrderByMagic
   DBIx::Class::Helper::ResultSet::Shortcut::Prefetch
   DBIx::Class::Helper::ResultSet::Shortcut::LimitedPage
   DBIx::Class::Helper::ResultSet::Shortcut::RemoveColumns
   DBIx::Class::Helper::ResultSet::Shortcut::ResultsExist
   DBIx::Class::Helper::ResultSet::Shortcut::Rows
   DBIx::Class::Helper::ResultSet::Shortcut::Page
   DBIx::Class::Helper::ResultSet::Shortcut::Search
));

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut - Shortcuts to common searches (->order_by, etc)

=head1 SYNOPSIS

 package MyApp::Schema::ResultSet::Foo;

 __PACKAGE__->load_components(qw{Helper::ResultSet::Shortcut});

 ...

 1;

And then elsewhere:

 # let's say you grab a resultset from somewhere else
 my $foo_rs = get_common_rs()
 # but I'd like it sorted!
   ->order_by({ -desc => 'power_level' })
 # and without those other dumb columns
   ->columns([qw/cromulence_ratio has_jimmies_rustled/])
 # but get rid of those duplicates
   ->distinct
 # and put those straight into hashrefs, please
   ->hri
 # but only give me the first 3
   ->rows(3);

=head1 DESCRIPTION

This helper provides convenience methods for resultset modifications.

See L<DBIx::Class::Helper::ResultSet/NOTE> for a nice way to apply it to your
entire schema.

=head1 SEE ALSO

This component is actually a number of other components put together.  It will
get more components added to it over time.  If you are worried about all the
extra methods you won't use or something, using the individual shortcuts is
a simple solution.  All the documentation will remain here, but the individual
components are:

=over 2

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::HRI>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::OrderBy>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::OrderByMagic>

(adds the "magic string" functionality to
C<DBIx::Class::Helper::ResultSet::Shortcut::OrderBy>))

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::GroupBy>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Distinct>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Rows>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Limit>

(inherits from C<DBIx::Class::Helper::ResultSet::Shortcut::Rows>)

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::HasRows>

(inherits from C<DBIx::Class::Helper::ResultSet::Shortcut::Rows>)

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Columns>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::AddColumns>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::Page>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::LimitedPage>

(inherits from C<DBIx::Class::Helper::ResultSet::Shortcut::Page> and
L<DBIx::Class::Helper::ResultSet::Shortcut::Rows>)

=item * L<DBIx::Class::Helper::ResultSet::Shortcut::ResultsExist>

=back

=head1 METHODS

=head2 distinct

 $foo_rs->distinct

 # equivalent to...
 $foo_rs->search(undef, { distinct => 1 });

=head2 group_by

 $foo_rs->group_by([ qw/ some column names /])

 # equivalent to...
 $foo_rs->search(undef, { group_by => [ qw/ some column names /] });

=head2 order_by

 $foo_rs->order_by({ -desc => 'col1' });

 # equivalent to...
 $foo_rs->search(undef, { order_by => { -desc => 'col1' } });

You can also specify the order as a "magic string", e.g.:

 $foo_rs->order_by('!col1')       # ->order_by({ -desc => 'col1' })
 $foo_rs->order_by('col1,col2')   # ->order_by([qw(col1 col2)])
 $foo_rs->order_by('col1,!col2')  # ->order_by([{ -asc => 'col1' }, { -desc => 'col2' }])
 $foo_rs->order_by(qw(col1 col2)) # ->order_by([qw(col1 col2)])

Can mix it all up as well:

 $foo_rs->order_by(qw(col1 col2 col3), 'col4,!col5')

=head2 hri

 $foo_rs->hri;

 # equivalent to...
 $foo_rs->search(undef, {
    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
 });

=head2 rows

 $foo_rs->rows(10);

 # equivalent to...
 $foo_rs->search(undef, { rows => 10 })

=head2 limit

This is an alias for C<rows>.

  $foo_rs->limit(10);

  # equivalent to...
  $foo_rs->rows(10);

=head2 has_rows

A lighter way to check the resultset contains any data rather than
calling C<< $rs->count >>.

=head2 page

 $foo_rs->page(2);

 # equivalent to...
 $foo_rs->search(undef, { page => 2 })

=head2 limited_page

 $foo_rs->limited_page(2, 3);

 # equivalent to...
 $foo_rs->search(undef, { page => 2, rows => 3 })

=head2 columns

 $foo_rs->columns([qw/ some column names /]);

 # equivalent to...
 $foo_rs->search(undef, { columns => [qw/ some column names /] });

=head2 add_columns

 $foo_rs->add_columns([qw/ some column names /]);

 # equivalent to...
 $foo_rs->search(undef, { '+columns' => [qw/ some column names /] });

=head2 remove_columns

 $foo_rs->remove_columns([qw/ some column names /]);

 # equivalent to...
 $foo_rs->search(undef, { remove_columns => [qw/ some column names /] });

=head2 prefetch

 $foo_rs->prefetch('bar');

 # equivalent to...
 $foo_rs->search(undef, { prefetch => 'bar' });

=head2 results_exist($cond?)

 my $results_exist = $schema->resultset('Bar')->search({...})->results_exist;

 # there is no easily expressable equivalent, so this is not exactly a
 # shortcut. Nevertheless kept in this class for historical reasons

Uses C<EXISTS> SQL function to check if the query would return anything.
Usually much less resource intensive the more common C<< foo() if $rs->count >>
idiom.

The optional C<$cond> argument can be used like in C<search()>.

=head2 results_exist_as_query($cond?)

 ...->search(
    {},
    { '+columns' => {
       subquery_has_members => $some_correlated_rs->results_exist_as_query
    }},
 );

 # there is no easily expressable equivalent, so this is not exactly a
 # shortcut. Nevertheless kept in this class for historical reasons

The query generator behind L</results_exist>. Can be used standalone in
complex queries returning a boolean result within a larger query context.

=head2 null(@columns || \@columns)

 $rs->null('status');
 $rs->null(['status', 'title']);

=head2 not_null(@columns || \@columns)

 $rs->not_null('status');
 $rs->not_null(['status', 'title']);

=head2 like($column || \@columns, $cond)

 $rs->like('lyrics', '%zebra%');
 $rs->like(['lyrics', 'title'], '%zebra%');

=head2 not_like($column || \@columns, $cond)

 $rs->not_like('lyrics', '%zebra%');
 $rs->not_like(['lyrics', 'title'], '%zebra%');

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
