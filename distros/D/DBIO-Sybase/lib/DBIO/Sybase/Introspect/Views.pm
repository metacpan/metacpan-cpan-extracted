package DBIO::Sybase::Introspect::Views;
# ABSTRACT: Introspect Sybase ASE view definitions

use strict;
use warnings;

our $VERSION = '0.900004';


sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  $tables //= {};
  my %is_view = map { $_ => 1 }
    grep { ($tables->{$_}{kind} // '') eq 'view' } keys %$tables;

  my $rows = $dbh->selectall_arrayref(q{
    SELECT o.name AS view_name, m.colid2, m.colid, m.text
    FROM syscomments m
    JOIN sysobjects  o ON o.id = m.id
    JOIN sysusers    u ON u.uid = o.uid
    WHERE o.type = 'V' AND u.name = ?
    ORDER BY o.name, m.colid2, m.colid
  }, { Slice => {} }, $schema);

  my %text;
  for my $row (sort {
         $a->{view_name} cmp $b->{view_name}
      || ($a->{colid2} // 0) <=> ($b->{colid2} // 0)
      || ($a->{colid}  // 0) <=> ($b->{colid}  // 0)
    } @$rows) {
    next unless $is_view{ $row->{view_name} };
    $text{ $row->{view_name} } .= $row->{text} // '';
  }

  my $deps = $dbh->selectall_arrayref(q{
    SELECT DISTINCT o.name AS view_name, r.name AS depends_on
    FROM sysdepends d
    JOIN sysobjects o ON o.id = d.id
    JOIN sysusers   u ON u.uid = o.uid
    JOIN sysobjects r ON r.id = d.depid
    WHERE o.type = 'V' AND r.type = 'V' AND u.name = ?
  }, { Slice => {} }, $schema);

  my %depends;
  for my $dep (@$deps) {
    next unless $is_view{ $dep->{view_name} } && $is_view{ $dep->{depends_on} };
    next if $dep->{view_name} eq $dep->{depends_on};
    $depends{ $dep->{view_name} }{ $dep->{depends_on} } = 1;
  }

  my %views;
  for my $name (keys %is_view) {
    next unless exists $text{$name};
    $views{$name} = {
      view_name  => $name,
      definition => strip_head($text{$name}),
      depends_on => [ sort keys %{ $depends{$name} // {} } ],
    };
  }

  return \%views;
}


sub strip_head {
  my ($def) = @_;
  $def =~ s/\A\s*create\s+view\s+.*?\s+as\s+//is;
  $def =~ s/^\s+//;
  $def =~ s/\s+\z//;
  $def =~ s/\s*;\s*\z//;
  return $def;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Introspect::Views - Introspect Sybase ASE view definitions

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches the definition of every view from C<syscomments> and the views each one
reads from from C<sysdepends>. ASE keeps the whole C<CREATE VIEW>
statement as typed, split over rows of at most 255 characters -- C<colid>
numbers the rows, C<colid2> the groups of them -- so the rows are joined in
that order and the C<CREATE VIEW ... AS> head is stripped: what is compared and
what C<CREATE VIEW> is written from is the part after C<AS>.

The views are also listed, with C<kind> C<view>, in the C<tables> of the model
(L<DBIO::Sybase::Introspect::Tables>), their columns in C<columns>; this class
adds what the diff needs to create, drop and order them.

=head1 METHODS

=head2 fetch

    my $views = DBIO::Sybase::Introspect::Views->fetch($dbh, $schema, $tables);

Returns a hashref keyed by view name, one entry for every view in C<$tables>
(C<kind> C<view>): C<view_name>, C<definition> (the text after C<AS>, without a
trailing C<;>), and C<depends_on>, the sorted names of the other views of the
list the view reads from (C<sysdepends>; the tables it reads are not listed).

=head2 strip_head

    my $select = DBIO::Sybase::Introspect::Views::strip_head($syscomments_text);

The text after the C<CREATE VIEW name [(columns)] AS> head, trimmed, without a
trailing C<;>. Used by L<DBIO::Sybase::Introspect/view_definition> as well.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
