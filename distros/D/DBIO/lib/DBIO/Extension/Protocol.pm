package DBIO::Extension::Protocol;
# ABSTRACT: Runs the phases of the extension interface over the active extensions and merges their answers

use strict;
use warnings;

our $VERSION = '0.900004';

use Storable ();
use DBIO::Exception;
use DBIO::Util ();

# Canonical text of a plain structure: sorted keys, no module beyond core Perl.
sub _canon {
  my ($x) = @_;
  return 'undef' unless defined $x;
  return '[' . join(',', map { _canon($_) } @$x) . ']' if ref $x eq 'ARRAY';
  return '{' . join(',', map { _canon($_) . '=>' . _canon($x->{$_}) } sort keys %$x) . '}' if ref $x eq 'HASH';
  return ref($x) . '()' if ref $x;
  (my $s = "$x") =~ s{(["\\])}{\\$1}g;
  return qq{"$s"};
}


sub new {
  my ($class, %args) = @_;
  my %entry = map { $_->{name} => $_ } @{ $args{entries} || [] };
  my @names = sort keys %entry;

  my @run = @names;
  if (my $order = $args{run_order}) {
    my %known = map { $_ => 1 } @names;
    DBIO::Exception->throw('Extension protocol: run_order must name exactly the active extensions')
      unless @$order == @names && !grep { !$known{$_} } @$order;
    @run = @$order;
  }

  return bless {
    entry        => \%entry,
    names        => \@names,
    run          => \@run,
    driver       => $args{driver} || {},
    connection   => $args{connection_schema},
    restricted   => $args{restricted} ? 1 : 0,
    verify_input => $args{verify_input},
    trace_on     => $args{trace},
    state        => {},
    trace        => {},
    refusals     => [],
    conflicts    => [],
    models       => undef,
  }, $class;
}


sub names { @{ $_[0]{names} } }


sub trace { Storable::dclone($_[0]{trace}) }


sub states { Storable::dclone($_[0]{state}) }


sub models {
  my ($self, %models) = @_;
  $self->{models} = { source => $models{source}, target => $models{target} };
  return $self;
}

# --- internals ---------------------------------------------------------------

sub _clone { ref $_[0] ? Storable::dclone($_[0]) : $_[0] }

sub _frozen {
  local $Storable::canonical = 1;
  return Storable::nfreeze(\$_[0]);
}

sub _entry_view {
  my ($self, $entry, $with_options) = @_;
  my $view = {
    class     => $entry->{class},
    installed => $entry->{installed} ? 1 : 0,
    version   => $entry->{version},
    schema    => $entry->{schema},
    state     => _clone($self->{state}{ $entry->{name} }),
  };
  if ($with_options) {
    $view->{name}    = $entry->{name};
    $view->{options} = _clone($entry->{options} || {});
  }
  return $view;
}

sub _ctx {
  my ($self, $entry, %extra) = @_;
  return {
    peers => { map { $_ => $self->_entry_view($self->{entry}{$_}) }
               grep { $_ ne $entry->{name} } @{ $self->{names} } },
    self              => $self->_entry_view($entry, 1),
    driver            => $self->{driver},
    connection_schema => $self->{connection},
    restricted        => $self->{restricted},
    %extra,
  };
}

# One call of one extension. @input is copied; the answer is returned as is.
sub _call {
  my ($self, $name, $method, $input, %ctx_extra) = @_;
  my $entry = $self->{entry}{$name};
  my $class = $entry->{class};

  my @args = map { _clone($_) } @$input;
  my $ctx  = $self->_ctx($entry, %ctx_extra);
  my @before = $self->{verify_input} ? (map { _frozen($_) } @args, _ctx_data($ctx)) : ();

  my $answer = $class->$method(@args, $ctx);

  if ($self->{verify_input}) {
    for my $i (0 .. $#args) {
      DBIO::Exception->throw(
        "Extension '$name' changed its input in $method (extensions must not modify their arguments)"
      ) if _frozen($args[$i]) ne $before[$i];
    }
    DBIO::Exception->throw(
      "Extension '$name' changed its context in $method (extensions must not modify their arguments)"
    ) if _frozen(_ctx_data($ctx)) ne $before[-1];
  }
  push @{ $self->{trace}{$name}{$method} }, _clone($answer) if $self->{trace_on};
  return $answer;
}

# The data part of a context: everything but the driver helpers and the handle.
sub _ctx_data { my ($ctx) = @_; return { map { $_ => $ctx->{$_} } grep { $_ ne 'driver' && $_ ne 'dbh' } keys %$ctx } }

sub _address_key { _canon($_[0]) }

sub _check_address {
  my ($name, $method, $address) = @_;
  DBIO::Exception->throw("Extension '$name': $method must return addresses (array references of scalars)")
    unless ref $address eq 'ARRAY' && @$address && !grep { !defined $_ || ref $_ } @$address;
  return;
}

# --- phase 0 ---------------------------------------------------------------------


sub inspect {
  my ($self, $dbh) = @_;
  $self->{state} = {};
  my %state;
  for my $name (@{ $self->{run} }) {
    my $answer = $self->_call($name, 'inspect', [], dbh => $dbh);
    $state{$name} = $answer if defined $answer;
  }
  $self->{state} = { map { $_ => _clone($state{$_}) } keys %state };
  return $self->states;
}

# --- phase 1 ---------------------------------------------------------------------


sub claims {
  my ($self, $model) = @_;
  my %address;
  for my $name (@{ $self->{run} }) {
    my $answer = $self->_call($name, 'claims', [$model]);
    DBIO::Exception->throw("Extension '$name': claims must return an array reference of addresses")
      unless ref $answer eq 'ARRAY';
    for my $address (@$answer) {
      _check_address($name, 'claims', $address);
      $address{ _address_key($address) } = _clone($address);
    }
  }
  return [ map { $address{$_} } sort keys %address ];
}

# --- phase 2 ---------------------------------------------------------------------


sub annotate {
  my ($self, $model) = @_;
  my %by;
  for my $name (@{ $self->{run} }) {
    my $answer = $self->_call($name, 'annotate', [$model]);
    DBIO::Exception->throw("Extension '$name': annotate must return an array reference of triples")
      unless ref $answer eq 'ARRAY';
    for my $triple (@$answer) {
      DBIO::Exception->throw("Extension '$name': annotate must return [ \$address, \$attribute, \$value ] triples")
        unless ref $triple eq 'ARRAY' && @$triple == 3 && defined $triple->[1] && !ref $triple->[1];
      _check_address($name, 'annotate', $triple->[0]);
      my $key = _address_key($triple->[0]) . "\0" . $triple->[1];
      push @{ $by{$key} }, { name => $name, triple => _clone($triple), frozen => _frozen($triple->[2]) };
    }
  }

  my (@merged, @conflicts);
  for my $key (sort keys %by) {
    my %values;
    push @{ $values{ $_->{frozen} } }, $_ for @{ $by{$key} };
    if (keys %values > 1) {
      my ($address, $attribute) = ($by{$key}[0]{triple}[0], $by{$key}[0]{triple}[1]);
      my @parts = sort map {
        my @who = sort map { $_->{name} } @{ $values{$_} };
        join(', ', @who) . ' => ' . _canon($values{$_}[0]{triple}[2])
      } keys %values;
      push @conflicts, _address_key($address) . ".$attribute: " . join('; ', @parts);
      next;
    }
    push @merged, $by{$key}[0]{triple};
  }
  DBIO::Exception->throw(
    "Extensions annotate the same object differently:\n  " . join("\n  ", @conflicts)
  ) if @conflicts;
  return \@merged;
}

# --- phase 3 ---------------------------------------------------------------------


sub verdict {
  my ($self, $change) = @_;
  my %ask = $self->{models} ? (models => _clone($self->{models})) : ();

  my (%using, %refuse);
  for my $name (@{ $self->{run} }) {
    my $answer = $self->_call($name, 'verdict', [$change], %ask);
    next unless defined $answer;
    my ($kind, @extra) = ref $answer eq 'HASH' ? sort keys %$answer : ();
    DBIO::Exception->throw(
      "Extension '$name': verdict must return undef, { using => \$expr } or { refuse => \$message }"
    ) unless defined $kind && !@extra && ($kind eq 'using' || $kind eq 'refuse')
      && defined $answer->{$kind} && !ref $answer->{$kind};
    ($kind eq 'using' ? \%using : \%refuse)->{$name} = $answer->{$kind};
  }

  if (%refuse) {
    my @messages = map { "$_: $refuse{$_}" } sort keys %refuse;
    push @{ $self->{refusals} }, @messages;
    return { refuse => \@messages };
  }
  return undef unless %using;

  my %distinct = map { $_ => 1 } values %using;
  if (keys %distinct > 1) {
    my $message = 'conflicting answers: '
      . join('; ', map { "$_: $using{$_}" } sort keys %using);
    push @{ $self->{conflicts} }, $message;
    push @{ $self->{refusals} }, $message;
    return { refuse => [$message] };
  }
  return { using => (values %using)[0] };
}


sub refusals { @{ $_[0]{refusals} } }


sub conflicts { @{ $_[0]{conflicts} } }


sub assert_no_refusals {
  my ($self) = @_;
  return 1 unless @{ $self->{refusals} };
  DBIO::Exception->throw(
    "The diff is refused by its extensions:\n  - " . join("\n  - ", @{ $self->{refusals} })
  );
}

# --- activation --------------------------------------------------------------------------


sub activation {
  my ($self) = @_;
  my %answer;
  for my $name (@{ $self->{run} }) {
    my $answer = $self->_call($name, 'activation', []);
    next unless defined $answer;
    DBIO::Exception->throw("Extension '$name': activation must return a hash reference (data, not statements)")
      unless ref $answer eq 'HASH';
    my @unknown = grep { $_ ne 'load' && $_ ne 'search_path' } sort keys %$answer;
    DBIO::Exception->throw("Extension '$name': activation has unknown key(s) " . join(', ', @unknown)
      . " (only load and search_path)") if @unknown;
    $answer{$name} = $answer;
  }

  my (%library, %owner, @load, @path, %seen_path);
  for my $name (@{ $self->{names} }) {
    my $answer = $answer{$name} or next;

    my $load = $answer->{load};
    my @pairs = !defined $load ? ()
      : ref $load eq 'HASH'  ? map { [ $_, $load->{$_} ] } sort keys %$load
      : ref $load eq 'ARRAY' ? map { [ $_, $_ ] } @$load
      : !ref $load           ? ([ $load, $load ])
      : DBIO::Exception->throw("Extension '$name': activation load must be a name, a list or a hash");
    for my $pair (@pairs) {
      my ($lname, $lib) = @$pair;
      DBIO::Exception->throw("Extension '$name': activation load names an empty or compound value")
        unless defined $lname && !ref $lname && defined $lib && !ref $lib;
      DBIO::Util::assert_identifier_text("Extension '$name': activation load", $_) for $lname, $lib;
      if (exists $library{$lname}) {
        DBIO::Exception->throw(
          "Activation cannot compose: '$lname' is loaded from '$library{$lname}' by "
          . "$owner{$lname} and from '$lib' by $name"
        ) if $library{$lname} ne $lib;
        next;
      }
      $library{$lname} = $lib;
      $owner{$lname}   = $name;
      push @load, $lib;
    }

    my $path = $answer->{search_path};
    for my $schema (!defined $path ? () : ref $path eq 'ARRAY' ? @$path : ($path)) {
      DBIO::Exception->throw("Extension '$name': activation search_path must hold schema names")
        if !defined $schema || ref $schema;
      DBIO::Util::assert_identifier_text("Extension '$name': activation search_path", $schema);
      push @path, $schema unless $seen_path{$schema}++;
    }
  }
  return { load => \@load, search_path => \@path };
}

# --- running phases 1 and 2 on a pair of models ----------------------------------------------


sub extend_models {
  my ($self, $deploy, @models) = @_;
  my $states = $self->{state};
  for my $model (@models) {
    $model = _clone($model);
    my $claims = $self->claims($model);
    $deploy->_apply_extension_claims($model, $claims) if @$claims;
    my $triples = $self->annotate($model);
    $deploy->_apply_extension_annotations($model, $triples) if @$triples;
    $deploy->_apply_extension_states($model, _clone($states)) if keys %$states;
  }
  $self->models(source => $models[0], target => $models[1]);
  return @models;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Extension::Protocol - Runs the phases of the extension interface over the active extensions and merges their answers

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  my $protocol = DBIO::Extension::Protocol->new(
    entries           => [ $list->entries ],
    driver            => { quote_ident => sub { ... } },
    connection_schema => 'app',
    restricted        => 0,
  );

  my $states  = $protocol->inspect($dbh);                    # phase 0
  my $claims  = $protocol->claims($model);                   # phase 1
  my $triples = $protocol->annotate($model);                 # phase 2
  my $answer  = $protocol->verdict($change);                 # phase 3
  my $active  = $protocol->activation;                       # per connection

=head1 DESCRIPTION

Core's side of ADR 0066 sections 2.2 to 2.4. It builds the context C<$ctx>
(see L<DBIO::Extension/THE CONTEXT>), asks every active extension the same
question as a copy of the same input, and merges the answers. Addresses stay
opaque to it: it sorts, de-duplicates and compares them, and the driver applies
them to its model (L<DBIO::Deploy::Base/_apply_extension_claims>).

The merges are unions with a refusal on conflict and are done in B<name
order>, whatever order the extensions were called in, so no result depends on
the order. Failures are L<DBIO::Exception>s that name the extensions.

=head1 METHODS

=head2 new

Arguments (hash):

=over 4

=item C<entries>

The active entries, as L<DBIO::Extension::List/entries> returns them (with the
installed state attached). Sorted by name here.

=item C<driver>

Hash reference of the driver's helpers; becomes C<< $ctx->{driver} >>.

=item C<connection_schema>, C<restricted>

Become the same keys of the context.

=item C<run_order>

Array reference of names. Overrides the order the extensions are B<called> in
(default: name order). The merge order stays by name. For
L<DBIO::Test::ExtensionSet>.

=item C<verify_input>

True: an extension that hands back a changed copy of its input makes the call
throw. For L<DBIO::Test::ExtensionSet>; off by default because every call
already gets its own copy.

=item C<trace>

True: keeps the raw answer of every extension call, see L</trace>.

=back

=head2 names

The names of the active extensions, sorted.

=head2 trace

  my $trace = $protocol->trace;   # { $name => { $method => [ $answer, ... ] } }

With C<trace> on: a copy of every raw answer, in call order. Empty otherwise.

=head2 states

The L</inspect> states by extension name, as a copy.

=head2 models

  $protocol->models(source => $model, target => $model);

Sets the models after phase 2 that the verdicts get in C<< $ctx->{models} >>.
L</extend_models> does it.

=head2 inspect

  my $states = $protocol->inspect($dbh);

Phase 0. Calls C<inspect> of every extension with C<< $ctx->{dbh} >> set and no
state in the context. Keeps the answers that are defined, per name, and returns
them as a hash reference (a copy).

=head2 claims

  my $addresses = $protocol->claims($model);

Phase 1. The union of the addresses every extension claims on C<$model>,
de-duplicated and sorted. Claiming is idempotent: there is no conflict.

=head2 annotate

  my $triples = $protocol->annotate($model);

Phase 2. The union of the C<< [ $address, $attribute, $value ] >> triples,
de-duplicated and sorted by address and attribute. The same address and
attribute with two different values throws, naming every extension involved
and its value; the message does not depend on the order of the calls.

=head2 verdict

  my $answer = $protocol->verdict($change);

Phase 3, asked by the driver for one change it is about to write (set the
models with L</models> first). Returns C<undef> when no extension answers,
C<< { using => $expr } >> for one answer (the same answer from several is one),
or C<< { refuse => \@messages } >>:

=over 4

=item * every C<refuse> of an extension is a message C<"name: text">, in name
order; any refusal refuses, and C<using> answers beside it are ignored;

=item * two different C<using> answers are a refusal naming both extensions.

=back

Every refusal is also kept for L</refusals> and L</assert_no_refusals>. An
answer that is neither C<undef> nor a hash with exactly one of C<using> and
C<refuse> throws.

=head2 refusals

  my @messages = $protocol->refusals;

All refusals of the verdicts asked so far, in the order they were given.

=head2 conflicts

  my @messages = $protocol->conflicts;

The verdicts that were refused because two extensions gave different
C<using> answers (also in L</refusals>), apart from the plain C<refuse>
answers of single extensions. L<DBIO::Test::ExtensionSet> reports them: a set
whose members contradict each other on its fixture does not combine.

=head2 assert_no_refusals

Throws a L<DBIO::Exception> listing every refusal when there is one, so a
diff with a refused change is not applied. Returns true otherwise.

=head2 activation

  my $active = $protocol->activation;
  # { load => [ 'age', 'postgis' ], search_path => [ 'ag_catalog', 'gis' ] }

The merge of the C<activation> data of every extension, composed in name
order and de-duplicated by first appearance. C<load> is a list of library
names; two extensions that give different libraries for one name throw. The
driver turns this into statements and puts the namespace of the connection in
front of C<search_path> (ADR 0066 section 3). It refuses what it cannot
compose.

Every library name and every C<search_path> name is an B<identifier> (ADR
0077). Core refuses one with C<;>, a line break, CR or NUL (a
L<DBIO::Exception> that names C<load> or C<search_path> and the extension,
never the value). The driver writes each name only through its identifier
quoting (or as a bind) or refuses it with a L<DBIO::Exception>; it never joins
a name into a statement by string concatenation. The Names list of
L<DBIO::Test::Conformance> asks this of every driver.

=head2 extend_models

  my ($source, $target) = $protocol->extend_models($deploy, $source, $target);

Phases 1 and 2 on both sides of a diff with the same set of extensions: copies
of the two models, with the claims applied by C<< $deploy->_apply_extension_claims >>,
then the annotations by C<< $deploy->_apply_extension_annotations >>, then the
L</inspect> states by C<< $deploy->_apply_extension_states >>, in this order
(phase 2 reads the model after phase 1; the states are added last so they are
not part of any phase's input). The models are also set for L</verdict>.
Returns the two new models.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
