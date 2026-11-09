package DBIO::Sybase::Diff::View;
# ABSTRACT: Diff Sybase ASE views

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Diff::Op ();
use DBIO::Exception ();
use DBIO::Sybase::Quote ();


sub diff {
  my ($class, $source, $target) = @_;
  $source //= {};
  $target //= {};

  my (%drop, %create);
  for my $name (keys %$source) {
    $drop{$name} = 1 unless exists $target->{$name};
  }
  for my $name (keys %$target) {
    if (!exists $source->{$name}) {
      $create{$name} = 1;
    }
    elsif (_normalize($source->{$name}{definition}) ne _normalize($target->{$name}{definition})) {
      $drop{$name} = $create{$name} = 1;
    }
  }

  my @ops;
  # A dropped view is dropped before the views it reads from.
  push @ops, map {
    DBIO::Sybase::Diff::View::Drop->new(action => 'drop', view => $source->{$_})
  } _order(\%drop, sub {
    my ($n) = @_;
    return grep { $_ ne $n && grep { $_ eq $n } @{ $source->{$_}{depends_on} // [] } }
      keys %drop;
  }, 'dropped');
  # A created view is created after the views it reads from.
  push @ops, map {
    DBIO::Sybase::Diff::View::Create->new(action => 'create', view => $target->{$_})
  } _order(\%create, sub {
    my ($n) = @_;
    return grep { $create{$_} } @{ $target->{$n}{depends_on} // [] };
  }, 'created');

  return @ops;
}

sub _normalize {
  my ($sql) = @_;
  $sql //= '';
  $sql =~ s/\s+/ /g;
  $sql =~ s/\A //;
  $sql =~ s/ \z//;
  return $sql;
}

# The names of %$set in an order where every name comes after the names
# $before->($name) returns; name order otherwise. A cycle throws.
sub _order {
  my ($set, $before, $what) = @_;
  my (@out, %state);
  my $visit; $visit = sub {
    my ($n, @path) = @_;
    return if ($state{$n} // '') eq 'done';
    if (($state{$n} // '') eq 'open') {
      my @cycle = (@path[ (grep { $path[$_] eq $n } 0 .. $#path)[0] .. $#path ], $n);
      DBIO::Exception->throw(
        'DBIO::Sybase: the views to be ' . $what . ' depend on each other in a '
        . 'cycle (' . join(' -> ', @cycle) . '), no order creates or drops them');
    }
    $state{$n} = 'open';
    $visit->($_, @path, $n) for sort $before->($n);
    $state{$n} = 'done';
    push @out, $n;
  };
  $visit->($_) for sort keys %$set;
  undef $visit;
  return @out;
}

package DBIO::Sybase::Diff::View::Create;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(view));

sub as_sql {
  my $self = shift;
  my $view = $self->view;
  sprintf 'CREATE VIEW %s AS %s;',
    DBIO::Sybase::Quote::quote_ident($view->{view_name}), $view->{definition};
}
sub summary {
  my $self = shift;
  'CREATE VIEW ' . $self->view->{view_name};
}

package DBIO::Sybase::Diff::View::Drop;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(view));

sub as_sql {
  my $self = shift;
  'DROP VIEW ' . DBIO::Sybase::Quote::quote_ident($self->view->{view_name}) . ';';
}
sub summary {
  my $self = shift;
  'DROP VIEW ' . $self->view->{view_name};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Diff::View - Diff Sybase ASE views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Compares two view sets (the C<views> of the models
L<DBIO::Sybase::Introspect> produces) and generates the view operations:

=over 4

=item * a view only in the target: C<CREATE VIEW name AS ...>;

=item * a view only in the source: C<DROP VIEW name>;

=item * a view on both sides with another definition: C<DROP VIEW> and
C<CREATE VIEW>. ASE has no C<ALTER VIEW>.

=back

The definitions are compared as the text after C<AS>
(L<DBIO::Sybase::Introspect::Views>) with every run of white space reduced to
one blank, so a view deployed with another layout is not a change. Nothing else
is normalised: a different spelling of the same query is a change, and the view
is dropped and created again.

L<DBIO::Sybase::Diff> puts the drops before the changes to tables and the
creates after them: a removed or changed view must not be there when the table
under it is dropped or altered, and a new or changed one needs the tables and
columns it reads. Between views the order follows C<depends_on> (C<sysdepends>):
a view that reads from another is created after it and dropped before it. A
cycle cannot exist on a server; in a model that has one the diff refuses with a
L<DBIO::Exception> naming the views.

Only the removed and the changed views are dropped. A view on a changed view
that is itself unchanged is left alone; when the server refuses to create the
changed one because of it, that error is the answer, it is not caught. A table
changing kind (table to view or the other way) is not handled: the C<CREATE
VIEW> or C<DROP VIEW> runs against an object of the other kind and the server
refuses it.

Each op's C<as_sql> ends in C<;>, so L<DBIO::Sybase::Deploy/apply> sends every
view statement as a batch of its own, which C<CREATE VIEW> needs (see
L<DBIO::Sybase::Diff/EVERY STATEMENT ENDS IN ;>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::Sybase::Diff::View->diff($source_views, $target_views);

The ops, the drops first (dependents before what they read from), then the
creates (what a view reads from first); each in name order where the
dependencies leave a choice.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
