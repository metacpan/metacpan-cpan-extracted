package DBIO::MSSQL::Diff::View;
# ABSTRACT: Diff operations for MSSQL views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();
use DBIO::MSSQL::DDL qw(_quote_table);


__PACKAGE__->mk_diff_accessors(qw/view_name definition/);


sub body {
  my ($class, $def) = @_;
  return undef unless defined $def;
  my $text = $def;
  pos($text) = 0;
  # comments before the header are not part of it
  1 while $text =~ /\G(?:\s+|--[^\n]*\n|\/\*.*?\*\/)/gcs;
  if ($text =~ /\GCREATE\s+(?:OR\s+ALTER\s+)?VIEW\s+/gci) {
    # the name: up to three parts, each [bracketed], "quoted" or plain
    my $part = qr/(?:\[(?:[^\]]|\]\])*\]|"[^"]*"|[^\s.(\[\]"]+)/;
    if ($text =~ /\G$part(?:\.$part){0,2}/gc) {
      while (pos($text) < length $text) {
        if    ($text =~ /\GAS\b/gci)                 { last }
        elsif ($text =~ /\G\[(?:[^\]]|\]\])*\]/gc)   { }
        elsif ($text =~ /\G"[^"]*"/gc)               { }
        elsif ($text =~ /\G\w+/gc)                   { }
        else  { $text =~ /\G./gcs }
      }
      $def = substr $text, pos($text);
    }
  }
  $def =~ s/\A\s+//;
  $def =~ s/[\s;]+\z//;
  return $def;
}


sub normalize {
  my ($class, $def) = @_;
  my $body = $class->body($def);
  return undef unless defined $body;
  $body =~ s/\s+/ /g;
  return $body;
}


sub diff {
  my ($class, $source, $target) = @_;
  my $views = sub {
    my ($tables) = @_;
    return +{ map { $_ => $tables->{$_} } grep {
      ref $tables->{$_} eq 'HASH' && ($tables->{$_}{kind} // '') eq 'view'
    } keys %{ $tables // {} } };
  };
  my ($src, $tgt) = ($views->($source), $views->($target));

  my (@ops, @drops);
  for my $name (sort keys %$tgt) {
    my $def = $tgt->{$name}{definition};
    my $new = $class->normalize($def);
    my $action;
    if (!exists $src->{$name}) {
      $action = 'create';
    }
    else {
      my $old = $class->normalize($src->{$name}{definition});
      next if defined $new && defined $old && $new eq $old;
      next unless defined $new;
      $action = 'alter';
    }
    DBIO::Exception->throw("DBIO::MSSQL: the view '$name' is declared without a "
      . 'definition, so there is nothing to CREATE VIEW') unless defined $new;
    push @ops, $class->new(action => $action, view_name => $name, definition => $def);
  }
  for my $name (sort keys %$src) {
    next if exists $tgt->{$name};
    push @drops, $class->new(action => 'drop', view_name => $name,
      definition => $src->{$name}{definition});
  }

  # a view that reads another view comes after it when written, before it
  # when dropped (karr k82)
  @ops   = $class->_in_dependency_order(\@ops,   $tgt);
  @drops = reverse $class->_in_dependency_order(\@drops, $src);
  return (@ops, @drops);
}

# The ops put in the order of the views they read, from the depends_on of
# the model entries (the views a view reads, by model key). Only the views the
# ops are about are ordered among themselves; a view that is read and not part
# of the ops is there already (or stays). A view read that the model does not
# know, and a cycle, are refused before any statement.
sub _in_dependency_order {
  my ($class, $ops, $views) = @_;
  my %op = map { $_->view_name => $_ } @$ops;
  my (@out, %state);
  my $visit; $visit = sub {
    my ($name, @path) = @_;
    return if ($state{$name} // 0) == 2;
    DBIO::Exception->throw(sprintf
      'DBIO::MSSQL: the views %s read each other in a cycle; the order to '
      . 'write them in cannot be found, refused', join ' -> ', @path, $name)
      if ($state{$name} // 0) == 1;
    $state{$name} = 1;
    for my $dep (sort @{ $views->{$name}{depends_on} // [] }) {
      DBIO::Exception->throw(sprintf
        "DBIO::MSSQL: the view '%s' reads the view '%s', which the model does "
        . 'not know (a schema that was not introspected?); the order cannot be '
        . 'found, refused', $name, $dep)
        unless exists $views->{$dep};
      $visit->($dep, @path, $name) if $op{$dep};
    }
    $state{$name} = 2;
    push @out, $op{$name};
  };
  $visit->($_) for sort keys %op;
  return @out;
}


sub as_sql {
  my ($self) = @_;
  my $name = _quote_table($self->view_name);
  return "DROP VIEW $name;" if $self->action eq 'drop';
  return sprintf "CREATE OR ALTER VIEW %s AS\n%s;", $name,
    $self->body($self->definition);
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

DBIO::MSSQL::Diff::View - Diff operations for MSSQL views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<CREATE OR ALTER VIEW> for a view the classes declare that the database lacks
or holds with another definition, C<DROP VIEW> for a live view the classes do
not declare. A view is C<< kind => 'view' >> in the C<tables> section of the
model, with its stored text in C<definition>
(L<DBIO::MSSQL::Introspect::Views>); a name C<schema.view> is a view of that
schema, quoted on both parts.

Every statement is a batch of its own for the server: C<CREATE VIEW> has to be
the only statement of its batch, and the deploy runs the statements one at a
time. L<DBIO::MSSQL::Diff> puts the drops before the tables are dropped and
the creations after the tables, columns and keys exist.

Two definitions are the same when the text after C<AS> is the same with its
white space folded (L</body>); the part before it (the name, a column list,
C<WITH SCHEMABINDING>) is not compared. A definition is never compared by case:
a keyword written another way is another text.

=head1 METHODS

=head2 body

    my $body = DBIO::MSSQL::Diff::View->body($definition);

The part of a stored definition after the C<AS> of its header, trimmed, a
trailing C<;> taken off, as written (white space inside is kept). The header is
C<CREATE [OR ALTER] VIEW name [(columns)] [WITH options] AS>; the C<AS> is the
first one outside brackets and double quotes after the name. A text that is no
such header is its own body. C<undef> gives C<undef>.

=head2 normalize

The body with every run of white space folded to one blank. This is what two
definitions are compared by.

=head2 diff

    my @ops = DBIO::MSSQL::Diff::View->diff($source_tables, $target_tables);

The operations for the entries of the two C<tables> sections that are views:
C<create> for a view of the target that the source lacks, C<alter> for one both
have whose bodies differ (when the source gives no definition it counts as
different), C<drop> for one of the source the target lacks. A declared view
without a definition cannot be written and throws a L<DBIO::Exception>.
Creations and replacements come first, each view after the views it reads
(C<depends_on> of the model entry, from C<sys.sql_expression_dependencies>), then
the drops, each view before the views it reads; among views that do not read
each other, by name. A cycle, or a view read that the model does not know,
is refused (L<DBIO::Exception>, "refused") before any statement is written.

=head2 as_sql

C<CREATE OR ALTER VIEW [schema].[name] AS body;> for C<create> and C<alter>,
C<DROP VIEW [schema].[name];> for C<drop>.

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
