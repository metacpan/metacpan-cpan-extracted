package DBIO::ClickHouse::Diff::View;
# ABSTRACT: Diff operations for ClickHouse views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Diff::Op ();
use DBIO::Exception ();
use DBIO::ClickHouse::DDL ();
use DBIO::ClickHouse::DDL::Emit qw(create_view drop_view);

__PACKAGE__->mk_diff_accessors(qw/view_name definition storage/);


sub diff {
  my ($class, $source_tables, $declared_views, $storage, $target_tables) = @_;
  return () unless ref $declared_views eq 'HASH';
  $source_tables  ||= {};
  $target_tables  ||= {};

  my @live_views = grep { (($source_tables->{$_} || {})->{kind} // '') eq 'view' }
    sort keys %$source_tables;

  # data first: a refusal is thrown before an operation exists
  my @held = grep { ($source_tables->{$_}{engine} // '') =~ /\A(?:Materialized|Live|Window)View\z/ }
    @live_views;
  if (@held) {
    DBIO::Exception->throw(join "\n",
      'upgrade refused, no statement was executed:',
      (map {
        my $engine = $source_tables->{$_}{engine};
        exists $declared_views->{$_}
          ? "view `$_` is a $engine and holds data, but the schema declares a plain view of that name; "
            . "the upgrade will not replace it"
          : "view `$_` is a $engine and holds data, but the schema does not declare it; "
            . "the upgrade will not drop it"
      } @held),
      'Handle it by hand (DROP VIEW ... after saving what it holds), or declare it, then run the upgrade again',
    );
  }

  my %held = map { $_ => 1 } @held;
  my @ops;

  # A reader goes before what it reads: the reverse of the order they are
  # written in, read from the live definitions (karr k43).
  my %dropped = map { $_ => $source_tables->{$_}{definition} // '' }
    grep { !exists $declared_views->{$_} } @live_views;
  push @ops, map {
    $class->new(action => 'drop', view_name => $_, storage => $storage)
  } reverse DBIO::ClickHouse::DDL->view_order(\%dropped);

  # Written after the views they read (a cycle ends the diff here, before an
  # operation is rendered).
  for my $name (DBIO::ClickHouse::DDL->view_order($declared_views)) {
    my $live = $source_tables->{$name};
    if (!$live) {
      push @ops, $class->new(
        action => 'create', view_name => $name,
        definition => $declared_views->{$name}, storage => $storage,
      );
      next;
    }
    next unless ($live->{kind} // '') eq 'view';
    next unless defined $live->{definition};

    my $target = $target_tables->{$name} || {};
    my $want = defined $target->{definition}
      ? _normalise($target->{definition}, $target->{database})
      : _normalise($declared_views->{$name});
    next if _normalise($live->{definition}, $live->{database}) eq $want;

    push @ops, $class->new(
      action => 'alter', view_name => $name,
      definition => $declared_views->{$name}, storage => $storage,
    );
  }

  return @ops;
}

# The text the server holds, without what differs between two databases that
# hold the same view: the database in front of a name, the quoting marks, the
# white space.
sub _normalise {
  my ($sql, $database) = @_;
  $sql =~ s/`//g;
  $sql =~ s/(?<![\w.])\Q$database\E\.(?=\w)//g if defined $database && length $database;
  $sql =~ s/\s+/ /g;
  $sql =~ s/\A\s+//;
  $sql =~ s/\s*;?\s*\z//;
  return $sql;
}


sub as_sql {
  my ($self) = @_;
  my $guard = DBIO::Diff::Op::should_emit_if_exists($self->storage) ? 1 : 0;
  return drop_view(name => $self->view_name, if_exists => $guard)
    if $self->action eq 'drop';
  return create_view(
    name          => $self->view_name,
    definition    => $self->definition,
    or_replace    => ($self->action eq 'alter' ? 1 : 0),
    if_not_exists => $guard,
  );
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

DBIO::ClickHouse::Diff::View - Diff operations for ClickHouse views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The view operations the upgrade knows, against the views the schema declares:

=over 4

=item * C<CREATE VIEW> for a declared view the live database lacks;

=item * C<CREATE OR REPLACE VIEW> for a declared view whose live definition
differs (core case C<diff-view-definition-changed>);

=item * C<DROP VIEW> for a live view the schema no longer declares (core case
C<diff-view-dropped>). A view holds no data, so there is no opt-in.

=back

The declared views are the schema's own (L<DBIO::ClickHouse::DDL/declared_views>,
the selection C<install_ddl> uses) and the statements are rendered by
L<DBIO::ClickHouse::DDL::Emit>, the functions the install DDL uses. Without
declared views (the C<declared_views> argument of the diff is missing) the diff
has no opinion about views and produces none.

=head2 The order

A view is created or replaced after the views its C<SELECT> reads, and dropped
before them (the reverse order); among views that read each other not at all, by
name. The order comes from the text of the definitions, the declared ones for
create and replace, the live ones for drop; the limits of that reading, and the
refusal of a cycle (before any statement), are those of
L<DBIO::ClickHouse::DDL/view_order>.

=head2 What "differs" means

The two sides are compared as the B<server> holds them: the live view's
C<SELECT> as read from C<system.tables.create_table_query>
(L<DBIO::ClickHouse::Introspect::Tables>, C<definition>), and the view of the
target model, which L<DBIO::ClickHouse::Deploy> builds by installing the schema
into a scratch database and reading it back the same way. ClickHouse reformats
a view's C<SELECT> on creation (quotes dropped, tables qualified with their
database), so the raw declared text would never equal what is stored. Both texts
are therefore normalised before comparing: the database name in front of a
table, the quoting marks and the white space do not count. A target without a
definition (a hand-built model) is compared by the declared text, normalised
the same way; a live view whose definition is unknown is never replaced on a
guess.

=head2 Materialized views are refused

A materialized view holds data (its own table, filled by every insert). The
statements above would delete or rebuild that data, so a live materialized view
(or live or window view) that the schema does not declare, or declares as a plain
view, ends the diff with a L<DBIO::Exception> naming it and the way out, raised
while the operation list is built -- before any statement of the plan runs.

This includes one created by hand and never declared: it blocks C<upgrade> (the
refusal is deliberate, not a defect) until it is declared or dropped by hand.

=head1 METHODS

=head2 diff

    my @ops = DBIO::ClickHouse::Diff::View->diff(
        $source_tables, $declared_views, $storage, $target_tables,
    );

C<$source_tables> is the live model's C<tables> section (views included),
C<$declared_views> is C<< { name =E<gt> $select_sql } >>, C<$target_tables> the
desired model's. Returns the drop operations, then the create and
replace operations, each in the order of L</The order>. Throws for a materialized view as above.

=head2 as_sql

C<CREATE VIEW `name` AS ...;> for a create (with C<IF NOT EXISTS> when the
storage declares the capability, exactly as the table ops do), C<CREATE OR
REPLACE VIEW `name` AS ...;> for a replace and C<DROP VIEW `name`;> (with
C<IF EXISTS> under the same capability) for a drop.

=head2 summary

One line naming the view that is created (C<+>), replaced (C<~>) or dropped
(C<->).

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Diff> - the orchestrator that drives this

=item * L<DBIO::ClickHouse::DDL::Emit> - the statement template rendered here

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
