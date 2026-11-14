package DBIO::Test::ExtensionSet;
# ABSTRACT: Commutativity test for a set of database extension classes (ADR 0066)

use strict;
use warnings;

our $VERSION = '0.900005';

use DBIO::Util ();
use Test::More ();
use DBIO::Exception;
use DBIO::Extension;
use DBIO::Extension::Protocol;

use Exporter 'import';

our @EXPORT_OK = qw(
  extension_set_ok
  extension_set_violations
  extension_set_orders
);


sub extension_set_orders {
  my (@names) = @_;
  return ([]) unless @names;

  if (@names <= 5) {
    my @out;
    my $permute; $permute = sub {
      my ($done, $rest) = @_;
      return push @out, $done unless @$rest;
      for my $i (0 .. $#$rest) {
        my @rest = @$rest;
        my ($pick) = splice @rest, $i, 1;
        $permute->([ @$done, $pick ], \@rest);
      }
    };
    $permute->([], \@names);
    undef $permute;
    return @out;
  }

  my (%seen, @out);
  for my $base (\@names, [ reverse @names ]) {
    for my $shift (0 .. $#$base) {
      my @order = (@$base[ $shift .. $#$base ], @$base[ 0 .. $shift - 1 ]);
      push @out, \@order unless $seen{ join "\0", @order }++;
    }
  }
  return @out;
}

sub _dump { require Data::Dumper; local $Data::Dumper::Sortkeys = 1; local $Data::Dumper::Indent = 0; local $Data::Dumper::Terse = 1; Data::Dumper::Dumper($_[0]) }

# The driver is handed over as a class name and loaded here; an object is used
# as it is. A class that cannot be loaded is an exception, not a violation.
sub _load_driver {
  my ($driver) = @_;
  return if ref $driver;
  return if $driver->can('new');

  (my $file = "$driver.pm") =~ s{::}{/}g;
  return if $INC{$file};
  return if eval { require $file; 1 };

  my $error = $@;
  DBIO::Exception->throw(
    $error =~ /^Can't locate \Q$file\E in \@INC/
      ? "extension_set: the driver class $driver is not installed"
      : "extension_set: the driver class $driver does not load: $error"
  );
}

sub _entries {
  my ($args) = @_;
  my (@entries, @violations);
  for my $item (@{ $args->{extensions} || [] }) {
    my $entry = ref $item eq 'HASH' ? { %$item } : { class => $item };
    my $class = $entry->{class};
    $entry->{name} //= eval { $class->name };
    unless (defined $entry->{name}) {
      push @violations, "Extension class $class states no name; it cannot be put into a set";
      next;
    }
    $entry->{options} ||= {};
    if (my $state = ($args->{installed} || {})->{ $entry->{name} }) {
      @{$entry}{keys %$state} = values %$state;
    }
    else {
      $entry->{installed} //= 1;
    }
    eval { DBIO::Extension->check_interface($class); 1 } or push @violations, "$@";
    push @entries, $entry;
  }
  return (\@entries, \@violations);
}

sub _run {
  my ($args, $entries, $order) = @_;

  my $driver = $args->{driver};
  my $deploy = ref $driver ? $driver : $driver->new;
  my $protocol = DBIO::Extension::Protocol->new(
    entries           => $entries,
    driver            => $deploy->_extension_driver_helpers,
    connection_schema => $deploy->_extension_connection_schema,
    restricted        => $deploy->_extension_restricted,
    run_order         => $order,
    verify_input      => 1,
    trace             => 1,
  );

  my %out;
  $out{states} = $protocol->inspect($args->{dbh});
  my ($source, $target) = $protocol->extend_models($deploy, $args->{source}, $args->{target});
  $out{source} = $source;
  $out{target} = $target;

  my $statements;
  if (my $diff = $args->{diff}) {
    $statements = $diff->($source, $target, $protocol);
  }
  elsif (my $class = eval { $deploy->_diff_class }) {
    my @sql = $class->new(source => $source, target => $target, extensions => $protocol)->as_sql;
    $statements = @sql == 1 && ref $sql[0] eq 'ARRAY' ? $sql[0] : \@sql;
  }
  $out{statements} = $statements;

  $out{verdicts}   = [ map { $protocol->verdict($_) } @{ $args->{changes} || [] } ];
  $out{refusals}   = [ $protocol->refusals ];
  if (my @conflicts = $protocol->conflicts) {
    DBIO::Exception->throw("The extensions contradict each other: " . join('; ', @conflicts));
  }
  $out{activation} = $protocol->activation;

  my $trace = $protocol->trace;
  $out{"extension '$_'"} = $trace->{$_} for sort keys %$trace;
  return \%out;
}


sub extension_set_violations {
  my (%args) = @_;
  DBIO::Exception->throw('extension_set: driver is required') unless $args{driver};
  DBIO::Exception->throw('extension_set: source and target models are required')
    unless $args{source} && $args{target};

  _load_driver($args{driver});

  my ($entries, $violations) = _entries(\%args);
  return @$violations if @$violations;

  my @names = sort map { $_->{name} } @$entries;
  my ($reference, $reference_label);
  my @out;

  for my $order (extension_set_orders(@names)) {
    my $label = @$order ? join(' > ', @$order) : '(no extensions)';
    for my $run (1, 2) {
      my $here = "order [$label]" . ($run == 2 ? ', repeated' : '');
      my $result = eval { _run(\%args, $entries, @$order ? $order : undef) };
      if (!$result) {
        my $error = "$@";
        $error =~ s/\s+$//;
        push @out, "$here: $error";
        next;
      }
      if (!$reference) {
        ($reference, $reference_label) = ($result, $here);
        next;
      }
      for my $part (sort keys %$result) {
        next if DBIO::Util::canonical_text($result->{$part}) eq DBIO::Util::canonical_text($reference->{$part});
        push @out, "$here differs from $reference_label in $part: "
          . _dump($result->{$part}) . ' versus ' . _dump($reference->{$part});
      }
    }
  }
  return @out;
}


sub extension_set_ok {
  my (%args) = @_;
  my $tb   = delete $args{builder} || Test::More->builder;
  my $name = delete $args{name} // 'the extension set commutes';
  my @violations = extension_set_violations(%args);
  my $ok = $tb->ok(!@violations, $name);
  $tb->diag("  $_") for @violations;
  return $ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::ExtensionSet - Commutativity test for a set of database extension classes (ADR 0066)

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

In the test of a driver, or of an extension distribution:

  use DBIO::Test::ExtensionSet qw(extension_set_ok);

  extension_set_ok(
    driver     => 'DBIO::PostgreSQL::Deploy',
    extensions => [
      'DBIO::PostgreSQL::Age::Extension',
      'DBIO::PostgreSQL::PostGIS::Extension',
    ],
    source     => $live_model,
    target     => $target_model,
    dbh        => $fake_dbh,
    changes    => [ { kind => 'column_type', table => ..., column_name => ..., old_info => {...}, new_info => {...} } ],
    name       => 'AGE and PostGIS commute',
  );

=head1 DESCRIPTION

The protocol of L<DBIO::Extension::Protocol> hands every extension of a phase
the same input and merges the answers by unions with a refusal on conflict, so
the result does not depend on the order. It cannot ensure that an extension
stays inside the protocol: one that changes its input, keeps state between
calls, or answers differently depending on what ran before breaks the property
(ADR 0066 section 2.4, rule 6 of L<DBIO::Extension/WRITING AN EXTENSION>). This
module checks exactly that.

Given a driver (a L<DBIO::Deploy::Base> subclass: it applies claims and
annotations to the model and may supply the diff class), a set of extension
classes and an offline fixture -- a source and a target model, a stand-in for
the database handle that the extensions' C<inspect> reads, and optionally
changes to ask C<verdict> about -- it runs the phases in B<every permutation>
of the set (all permutations up to five extensions; above, every rotation of
the name order and of its reverse), overriding the name order only here, and
runs each order twice. It asserts

=over 4

=item * the same post-phase source and target model,

=item * the same diff statements, the same verdicts and refusals,

=item * the same activation and the same C<inspect> states,

=item * per extension the same output of every phase in every position and in
the repeated run (an extension with state between calls differs from itself),

=item * that every extension got a copy of its input and the copy came back
unchanged (the input and the context).

=back

An exception from the protocol (an annotate conflict, a malformed answer, a
driver that cannot apply what the set claims, a wrong interface version) is a
violation as well: a set that cannot run does not commute.

A driver runs it over the extensions of its family; an extension distribution
runs it over itself and every extension it names as a peer.

=head1 METHODS

=head2 extension_set_orders

  my @orders = extension_set_orders(@names);

The orders the test runs, each an array reference of names. All permutations
for up to five names; above that every rotation of C<@names> and of its
reverse (duplicates removed).

=head2 extension_set_violations

  my @violations = extension_set_violations(%args);

Runs the test and returns the violations as strings; empty when the set
commutes. Arguments:

=over 4

=item C<driver>

A class name or object of a L<DBIO::Deploy::Base> subclass. A class name is
loaded by the test; a class that cannot be loaded throws a
L<DBIO::Exception> naming it. The class needs no
schema for the hooks the protocol uses (C<_apply_extension_claims>,
C<_apply_extension_annotations>, C<_apply_extension_states>,
C<_extension_driver_helpers>, C<_extension_connection_schema>,
C<_extension_restricted>, C<_diff_class>). It is built with C<< ->new >> without
arguments. Required.

=item C<extensions>

An array reference of extension classes, or of entries
C<< { class, name, options, installed, version, schema } >>. The name is the
class's C<name> unless the entry gives one. An entry without installed state
counts as installed; C<installed> (below) overrides.

=item C<installed>

Optional: name to C<< { installed, version, schema } >>.

=item C<source>, C<target>

The offline fixture: the source (live) model and the target model, in the
driver's shape. Required. They are copied; the test never changes them.

=item C<dbh>

What C<< $ctx->{dbh} >> is in C<inspect>: a hash or fake object the extensions
read. Optional.

=item C<changes>

Optional: array reference of changes to ask C<verdict> about, in the driver's
form.

=item C<diff>

Optional code reference C<< ($source, $target, $protocol) >> returning the
diff statements as an array reference, for a driver whose diff is not a plain
C<< _diff_class->new(source =>, target =>, extensions =>)->as_sql >>. Default: that.

=back

=head2 extension_set_ok

  extension_set_ok(%args, name => 'the set commutes');

L</extension_set_violations> as a test: one C<ok> that fails with the
violations as diagnostics. Returns the result of the test. C<builder> may name
a L<Test::Builder> to report to (default: the one of L<Test::More>).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
