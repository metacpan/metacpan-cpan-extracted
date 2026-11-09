package DBIO::DuckDB::Diff::View;
# ABSTRACT: Diff operations for DuckDB views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::DuckDB::DDL::Emit qw(quote_ident);

__PACKAGE__->mk_diff_accessors(qw/view_name view_info replaced/);


sub _comparable {
  my ($def) = @_;
  $def //= '';
  $def =~ s/\A\s+//;
  $def =~ s/[\s;]+\z//;
  return $def;
}

# what is compared: the query of the statement, not the spelling of the name
# it was created under (a database deployed before every name was quoted holds
# CREATE VIEW v, the target CREATE VIEW "v")
sub _body {
  my ($def) = @_;
  $def = _comparable($def);
  $def =~ s/\A CREATE \s+ (?: OR \s+ REPLACE \s+ )? (?: (?:LOCAL|GLOBAL)? \s* TEMP(?:ORARY)? \s+ )?
            VIEW \s+ (?: IF \s+ NOT \s+ EXISTS \s+ )?
            (?: "(?:[^"]|"")*" | [\w\$.]+ ) \s+ //xi;
  return $def;
}

sub diff {
  my ($class, $source, $target) = @_;
  $source //= {};
  $target //= {};

  my %seen;
  my @ops;
  for my $name (sort grep { !$seen{$_}++ } keys %$source, keys %$target) {
    my ($old, $new) = ($source->{$name}, $target->{$name});

    next if $old && $new
      && _body($old->{view_definition}) eq _body($new->{view_definition});

    push @ops, $class->new(
      action    => 'drop',
      view_name => $name,
      view_info => $old,
      replaced  => ($new ? 1 : 0),
    ) if $old;

    push @ops, $class->new(
      action    => 'create',
      view_name => $name,
      view_info => $new,
    ) if $new;
  }
  return @ops;
}


sub as_sql {
  my ($self) = @_;

  return sprintf 'DROP VIEW %s;', quote_ident($self->view_name)
    if $self->action eq 'drop';

  my $def = _comparable(($self->view_info // {})->{view_definition});
  die sprintf "Cannot create view %s: the target model holds no definition "
    . "for it, and a view cannot be written from its columns\n", $self->view_name
    unless length $def;

  return "$def;";
}


sub summary {
  my ($self) = @_;
  return sprintf '%s view: %s', $self->summary_prefix, $self->view_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Diff::View - Diff operations for DuckDB views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a view-level diff operation: C<CREATE VIEW> or C<DROP VIEW>.

L<DBIO::DuckDB::Introspect::Tables> lists a view under C<tables> with
C<< kind => 'view' >>, and the diff used to take it for a table: C<DROP TABLE>
for a view that had gone (C<Existing object ... is of type View, trying to drop
type Table>), C<ALTER TABLE ... ADD COLUMN> for one that selects another column
(C<Can only modify view with ALTER VIEW statement>), and a view that was new
was created as a table. A view is created as a view and removed as a view, and
no column or index op is ever written for one.

Two views of one name are the same view when the text DuckDB keeps of their
query (C<view_definition>, a complete C<CREATE VIEW> statement) has the same query
once the spelling of the name, surrounding whitespace and a closing semicolon
are set aside. Both sides are read from DuckDB, so the same
declaration gives the same text. A changed view is a C<drop> followed by a
C<create>; the C<drop> is marked C<replaced>, which
L<DBIO::Diff::Base/classify> counts as changing, not destructive.

=head1 ATTRIBUTES

=head2 view_name

The name of the view.

=head2 view_info

The view's entry in the C<tables> section of the model it comes from: the
target's for a C<create>, the source's for a C<drop>. A C<create> needs its
C<view_definition>.

=head2 replaced

True on the C<drop> of a changed view.

=head1 METHODS

=head2 diff

    my @ops = DBIO::DuckDB::Diff::View->diff($source_views, $target_views);

Hashrefs of view entries keyed by name. A C<drop> for a view only the source
has, a C<create> for one only the target has, both (C<drop> first) for a view
whose definition changed. Sorted by name.

=head2 as_sql

C<DROP VIEW "name";>, or the target's own C<CREATE VIEW> statement. A C<create> whose C<view_info> holds no definition throws: a view
cannot be written from its columns.

=head2 summary

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
