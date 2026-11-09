package DBIO::Firebird::Diff::View;
# ABSTRACT: Diff operations for Firebird views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();
use DBIO::Firebird::DDL qw(_firebird_quote_ident);


__PACKAGE__->mk_diff_accessors(qw/view_name view_source old_source replaced/);


sub normalize {
  my ($class, $source) = @_;
  return '' unless defined $source;
  $source =~ s/\s+/ /g;
  $source =~ s/^ //;
  $source =~ s/ \z//;
  $source =~ s/\s*;\z//;
  return $source;
}

sub _is_view { ($_[0] // {})->{kind} && $_[0]{kind} eq 'view' }

# The views $name reads (by quoted name; an unquoted reference reads the upper
# case name), for ordering only.
sub _reads {
  my ($source, @others) = @_;
  return [ grep {
    my $o = $_;
    $source =~ /"\Q$o\E"/ || ($o eq uc($o) && $source =~ /(?<![\w\$])\Q$o\E(?![\w\$])/i)
  } @others ];
}


sub diff {
  my ($class, $source, $target) = @_;
  $source ||= {};
  $target ||= {};

  my (%old, %new);
  for my $name (keys %$source) {
    next unless _is_view($source->{$name});
    next if exists $target->{$name} && !_is_view($target->{$name});
    $old{$name} = $source->{$name}{view_source};
  }
  for my $name (keys %$target) {
    next unless _is_view($target->{$name});
    next if exists $source->{$name} && !_is_view($source->{$name});
    $new{$name} = $target->{$name}{view_source};
  }

  my @gone = grep { !exists $new{$_} } keys %old;
  my @make = grep { !exists $old{$_} || $class->normalize($old{$_}) ne $class->normalize($new{$_}) }
             keys %new;
  my %replaced = map { $_ => 1 } grep { exists $old{$_} } @make;
  my @unmake = (@gone, grep { $replaced{$_} } @make);

  my @drops = reverse DBIO::Diff::Op::_order_by_dependency(
    sub { _reads($old{ $_[0] } // '', @unmake) }, @unmake);
  my @creates = DBIO::Diff::Op::_order_by_dependency(
    sub { _reads($new{ $_[0] } // '', @make) }, @make);

  return (
    drops => [ map { $class->new(
      action => 'drop', view_name => $_, view_source => $old{$_},
      replaced => ($replaced{$_} ? 1 : 0),
    ) } @drops ],
    creates => [ map { $class->new(
      action      => (exists $old{$_} ? 'change' : 'create'),
      view_name   => $_,
      view_source => $new{$_},
      old_source  => $old{$_},
    ) } @creates ],
  );
}


sub as_sql {
  my ($self) = @_;
  my $name = _firebird_quote_ident($self->view_name);
  return sprintf 'DROP VIEW %s;', $name if $self->action eq 'drop';
  my $def = $self->view_source;
  DBIO::Exception->throw(sprintf 'view %s: the model holds no definition (view_source) to write it from', $name)
    unless defined $def && length $def;
  $def =~ s/\s*;\s*\z//;
  return sprintf 'CREATE VIEW %s AS %s;', $name, $def;
}


sub summary {
  my ($self) = @_;
  return sprintf '~ view: %s (dropped, created again after the tables)', $self->view_name
    if $self->action eq 'drop' && $self->{replaced};
  return sprintf '%s view: %s', $self->summary_prefix, $self->view_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Diff::View - Diff operations for Firebird views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

View-level diff operations in Firebird: C<CREATE VIEW> for a view
the schema has and the database lacks (C<create>), C<DROP VIEW> for a view
only the database has (C<drop>). A view the database has with another
definition is dropped (C<drop>, C<replaced>) before the tables are touched and
created again (C<change>) after them, so a column the new definition no longer
reads can be dropped in the same diff. The definition is C<rdb$relations.rdb$view_source> of the
introspected model (the C<view_source> key of the C<tables> section).

Two definitions are the same when they are equal after leading and trailing
whitespace is cut and every run of whitespace is one blank. Nothing else is
normalised: a different spelling of the same query is a change, and
dropping and creating the same query again is harmless.

The diff does not guess what the server will accept. A view other objects
depend on, or whose new definition is refused for another reason, fails when
the statement runs, with the server's own error; nothing is left out. In
particular, an I<unchanged> view that reads a changed view is not dropped with
it: the server refuses the C<DROP VIEW> of the changed one, loudly.

=head1 METHODS

=head2 normalize

    my $text = DBIO::Firebird::Diff::View->normalize($view_source);

The comparison form of a definition: whitespace runs collapsed, ends cut.

=head2 diff

    my %ops = DBIO::Firebird::Diff::View->diff($source_tables, $target_tables);

Returns C<< ( drops => [ ... ], creates => [ ... ] ) >>, two lists of
operations. The drops (removed views and changed ones) are to run before the
tables are touched, the creates (new views and changed ones, created again)
after them. A view that reads another is dropped
before and created after it, where its definition names the other by its
name. A name that is a table on one side and a view on the other is not
handled here (L<DBIO::Firebird::Diff::Table/refusal>).

=head2 as_sql

C<DROP VIEW "name";> or C<CREATE VIEW "name" AS E<lt>definitionE<gt>;>

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
