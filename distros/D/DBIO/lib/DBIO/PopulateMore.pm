package DBIO::PopulateMore;

# ABSTRACT: Enhanced populate with cross-source references

use strict;
use warnings;

use Scalar::Util qw(refaddr weaken);
use namespace::clean;


my $MATCH_CONDITION = qr/^!(\w+:.+)$/;


sub populate_more {
  my ($self, $arg, @rest) = @_;

  $self->throw_exception("Argument is required.")
    unless $arg;

  my @args = (ref $arg && ref $arg eq 'ARRAY') ? @$arg : ($arg, @rest);

  my @definitions;
  while (@args) {
    my $next = shift @args;
    if (ref $next && ref $next eq 'HASH') {
      push @definitions, $next;
    } else {
      my $value = shift @args;
      push @definitions, { $next => $value };
    }
  }

  my %rs_index;
  my %seen;
  weaken(my $weak_self = $self);

  my $visit;
  my $dispatch;

  # Visitor: recursively walk data structures, inflating !-prefixed values
  $visit = sub {
    my ($target) = @_;
    if (ref $target eq 'ARRAY') {
      my $addr = refaddr $target;
      return $seen{$addr} if defined $seen{$addr};
      my $new = $seen{$addr} = [];
      @$new = map { $visit->($_) } @$target;
      return $new;
    } elsif (ref $target eq 'HASH') {
      my $addr = refaddr $target;
      return $seen{$addr} if defined $seen{$addr};
      my $new = $seen{$addr} = {};
      %$new = map { $_ => $visit->($target->{$_}) } keys %$target;
      return $new;
    } elsif (defined $target && $target =~ $MATCH_CONDITION) {
      return $dispatch->($1);
    } else {
      return $target;
    }
  };

  # Dispatcher: route !Name:args to the correct inflator
  $dispatch = sub {
    my ($arg) = @_;
    my ($name, $command) = ($arg =~ /^(\w+):(\S.*)$/);

    if ($name eq 'Index') {
      return $rs_index{$command}
        || $weak_self->throw_exception("Bad Index in fixture: $command");
    } elsif ($name eq 'Env') {
      return $ENV{$command}
        // $ENV{uc $command}
        // $weak_self->throw_exception("No match for $command in \%ENV");
    } elsif ($name eq 'Find') {
      my ($source, $id) = split(/\./, $command, 2);
      my $rs = $weak_self->resultset($source)
        or $weak_self->throw_exception("Can't find resultset for $source");
      if ($id =~ /^\[(.+)\]$/) {
        my %keys = map { split(/=/, $_, 2) } split(/,/, $1);
        $id = \%keys;
      }
      return $rs->find($id)
        || $weak_self->throw_exception("Can't find result for '$id' in '$source'");
    } else {
      $weak_self->throw_exception("Unknown inflator: $name");
    }
  };

  for my $definition (@definitions) {
    my ($source, $info) = %$definition;
    my @fields = ref $info->{fields} eq 'ARRAY'
      ? @{$info->{fields}}
      : ($info->{fields});

    my $data = $visit->($info->{data});

    while (my ($rs_key, $values) = each %$data) {
      my @values = ref $values eq 'ARRAY' ? @$values : ($values);

      my %create;
      for my $i (0 .. $#fields) {
        $create{$fields[$i]} = $values[$i] if defined $fields[$i] && defined $values[$i];
      }

      my $new = $self->resultset($source)->update_or_create(\%create);
      $rs_index{"$source.$rs_key"} = $new;
    }
  }

  # Break circular refs to avoid leaks
  undef $visit;
  undef $dispatch;

  return %rs_index;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PopulateMore - Enhanced populate with cross-source references

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';

  # Can be loaded as a component or used standalone
  __PACKAGE__->load_components(qw/PopulateMore/);

  # Or use directly on any schema instance:
  # DBIO::PopulateMore->populate_more($schema, [...])

Then:

  $schema->populate_more([
    { Gender => {
        fields => 'label',
        data => {
          male   => 'male',
          female => 'female',
        }}},
    { Person => {
        fields => ['name', 'age', 'gender'],
        data => {
          john => ['john', 38, '!Index:Gender.male'],
          jane => ['jane', 40, '!Index:Gender.female'],
        }}},
  ]);

See F<t/populate_more.t> for a runnable example of the C<!Index:> cross-reference.

=head1 DESCRIPTION

This module provides an enhanced version of the builtin
L<DBIO::Schema/populate> method. It allows inserting rows across multiple
result sources in one call, with cross-referencing between them via the
C<!Index:Source.key> syntax.

Based on L<DBIx::Class::Schema::PopulateMore> by John Napiorkowski.

Unlike other L<DBIO::Schema> components, this module is not a schema
plugin that inherits from L<DBIO::Schema>. It is a standalone utility
class that operates on any schema instance. It can be loaded as a
component via L<DBIO::Schema/load_components>, or used directly.

=head2 Inflators

Values starting with C<!> are processed by inflator plugins:

=over 4

=item C<!Index:Source.key> - Reference a previously inserted row

=item C<!Env:VAR_NAME> - Substitute from C<%ENV>

=item C<!Find:Source.[key=val]> - Look up an existing row

=back

=head1 METHODS

=head2 populate_more

Populate multiple sources with optional cross-source references and inflators.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
