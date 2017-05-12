#!/usr/bin/perl

=head1 NAME

App::Getconf::View - specific view of options set in App::Getconf

=head1 SYNOPSIS

  use App::Getconf;

  App::Getconf->schema(...);
  App::Getconf->cmdline(\@ARGV);

  my $view = App::Getconf->getopt;

  if ($view->help) {
    print "this is --help message\n";
    exit 0;
  }

  print "starting the program\n" if $view->verbose;

  for my $i (0 .. $view->get("bottles.number")) {
    printf "%d bottles of beer on the wall, %d bottles of beer.\n" .
           "Take one down and pass it around, %d bottles of beer on the wall.\n\n",
           99 - $i, 99 - $i, 99 - $i - 1;
  }

=cut

package App::Getconf::View;

#-----------------------------------------------------------------------------

use warnings;
use strict;

use Carp;

our @CARP_NOT = qw{App::Getconf};

#-----------------------------------------------------------------------------

=head1 METHODS

Following methods are available:

=over

=cut

#-----------------------------------------------------------------------------

=item C<new(%opts)>

Constructor. Typically you won't be calling this on your own, so don't be
excited.

Following options are honoured:

=over

=item C<prefix>

Longest prefix for options ("." is a separator). All other prefixes that will
be tried in lookup have last component chopped off, compared to previous
prefix.

=item C<options>

Hashref containing all the L<App::Getconf::Node(3)> objects.

=back

=cut

sub new {
  my ($class, %opts) = @_;

  my $self = bless {
    prefixes => undef,
    options  => $opts{options},
  }, $class;

  my @parts = split /\./, $opts{prefix};
  my $prefix = $parts[0];
  for my $i (1 .. $#parts) {
    $prefix = $parts[$i] = "$prefix.$parts[$i]";
  }
  $self->{prefixes} = [reverse @parts];

  return $self;
}

#-----------------------------------------------------------------------------

=item C<prefixes()>

List of prefixes searched by this view.

Prefixes are composed from C<prefix> option passed to the constructor.

=cut

sub prefixes {
  my ($self) = @_;

  return @{ $self->{prefixes} };
}

#-----------------------------------------------------------------------------
# find an appropriate key

=begin Internal

=pod _lookup() {{{

=item C<_lookup($option_name, $type, $storage)>

Find an option called C<$option_name> looking under prefixes.

If C<$type> was specified, option will need to have this type.

If C<$storage> was specified, option will need to have this storage type.

Returned value is full option name (C<undef> if nothing was found).

=cut

sub _lookup {
  my ($self, $optname, $type, $storage) = @_;

  for my $p ($self->prefixes) {
    my $o = "$p.$optname";

    # no node in schema => can't have a value
    next if not $self->{options}{$o};
    # type filter was requested, but current node's type doesn't match
    next if defined $type    && $self->{options}{$o}->type    ne $type;
    # storage filter was requested, but current node's storage doesn't match
    next if defined $storage && $self->{options}{$o}->storage ne $storage;

    if (exists $self->{options}{$o}) {
      return $o;
    }
  }

  return undef if not $self->{options}{$optname};
  return undef if defined $type    && $self->{options}{$optname}->type    ne $type;
  return undef if defined $storage && $self->{options}{$optname}->storage ne $storage;

  return $optname;
}

=end Internal

=pod }}}

=cut

#-----------------------------------------------------------------------------

=item C<get($option_name)>

Retrieve value of option C<$option_name>. Method performs lookup, consequently
prepending each of prefixes (see C<prefixes()> method).

=cut

sub get {
  my ($self, $optname) = @_;

  my $key = $self->_lookup($optname);
  return $key ? $self->top($key) : ();
}

=item C<top($option_name)>

Retrieve value of option C<$option_name>. Method I<does not perform> lookup.
You'll get the option which you asked for.

=cut

sub top {
  my ($self, $optname) = @_;

  if (exists $self->{options}{$optname}) {
    return $self->{options}{$optname}->get;
  }

  return;
}

#-----------------------------------------------------------------------------
# top_*()

=begin Test::Pod::Coverage

=item C<top_allinwonder($name, $type)>

Retrieve value of option C<$name> (no lookup), expecting type C<$type>. Method
does not discriminate between different storage types, it just checks the
type. It's a helper for C<top_type_*()> methods.

Method returns C<($value, App::Getconf::Node)>.

=end Test::Pod::Coverage

=cut

sub top_allinwonder {
  my ($self, $optname, $type) = @_;

  my $opt = $self->{options}{$optname};

  if (not $opt) {
    croak "Option not found: $optname";
  }

  if ($opt->type ne $type) {
    croak "Type mismatch for $optname: expected $type, got @{[$opt->type]}";
  }

  return ($opt->get, $opt);
}

=begin Test::Pod::Coverage

=item C<top_type_scalar()>

Retrieve value of option C<$name> (no lookup), expecting type C<$type> and the
option storage being a simple scalar.

Method returns value stored for the option.

=end Test::Pod::Coverage

=cut

sub top_type_scalar {
  my ($self, $optname, $type) = @_;

  my ($value, $opt) = $self->top_allinwonder($optname, $type);

  if ($opt->storage ne 'scalar') { # other possibilities: array, hash
    croak "Scalar option $optname requested, got @{[$opt->storage]}";
  }

  # convert bool to 1/0
  return ($value ? 1 : 0) if $type eq 'bool';

  # other types don't require special treatment
  return $value;
}

=begin Test::Pod::Coverage

=item C<top_type_array()>

Retrieve value of option C<$name> (no lookup), expecting type C<$type> and the
option storage being an array.

Method returns plain list (possibly empty) of values stored for the option.

=end Test::Pod::Coverage

=cut

sub top_type_array {
  my ($self, $optname, $type) = @_;

  my ($value, $opt) = $self->top_allinwonder($optname, $type);

  if ($opt->storage ne 'array') { # other possibilities: "", HASH
    my $type = $opt->storage;
    croak "Array option $optname requested, got $type";
  }

  return @{ $value || [] };
}

=begin Test::Pod::Coverage

=item C<top_type_hash($name, $type)>

Retrieve value of option C<$name> (no lookup), expecting type C<$type> and the
option storage being a hash.

In list context method returns list of pairs (key => value) of data stored for
the option. In scalar context method returns hashref of the data.

=end Test::Pod::Coverage

=cut

sub top_type_hash {
  my ($self, $optname, $type) = @_;

  my ($value, $opt) = $self->top_allinwonder($optname, $type);

  if ($opt->storage ne 'hash') { # other possibilities: scalar, array
    my $type = $opt->storage;
    croak "Hash option $optname requested, got $type";
  }

  # in list context (assignment to hash?) return all the key/value pairs
  # in scalar context (also: dereference) return hashref
  if (wantarray) {
    return %{ $value || {} };
  } else {
    return $value;
  }
}

#-----------------------------------------------------------------------------

=item C<get_{flag|bool|int|float|string}()>

=item C<top_{flag|bool|int|float|string}()>

=item C<get_{flag|bool|int|float|string}_array()>

=item C<top_{flag|bool|int|float|string}_array()>

=item C<get_{flag|bool|int|float|string}_hash()>

=item C<top_{flag|bool|int|float|string}_hash()>

Methods similar to C<get()> and C<top()>, but they also check if the result is
of matching type (C<get_*()> don't stop on non-matching options). Option
storage is also checked: it should be, respectively, a scalar, an array or
a hash.

Methods C<die()> when no matching option was found. If the option was found
but it had not been set, methods return C<undef> or empty list, whichever is
appropriate.

Methods C<*_array()> return a list of elements, which in scalar context turns
out to be a number.

Methods C<*_hash()> return a hashref (or C<undef>) in scalar context and list
of key/value pairs in list context.

=item C<< ${option_name}() >>

For convenience, options may be retrieved by calling method named after the
option. For example, following two are equivalent:
C<< $view->get('verbose') >> and C<< $view->verbose >>.

Note that this syntax performs lookup, just like C<get()> method.

Names starting with C<set_>, C<get_> and C<top_> are reserved. Use explicit
C<get()> method call to retrieve them.

=cut

our $AUTOLOAD;
sub AUTOLOAD {
  my ($self) = @_;

  my $optname = (split /::/, $AUTOLOAD)[-1];

  # unified support for top_flag(), top_bool(), top_int() and so on
  if ($optname =~ /^(get|top)_(flag|bool|int|float|string)(_(array|hash))?$/) {
    my $lookup = $1;
    my $type = $2;
    my $storage = $4 || "scalar";
    my $name = $_[1];

    if ($lookup eq 'get') {
      my $real_name = $self->_lookup($name, $type, $storage);
      if (not $real_name) {
        $storage ||= "scalar";
        croak "Option not found: $name ($type, $storage)";
      }
      $name = $real_name;
    }

    if (not $storage) {
      return $self->top_type_scalar($name, $type);
    } elsif ($storage eq 'array') {
      return $self->top_type_array($name, $type);
    } elsif ($storage eq 'hash') {
      return $self->top_type_hash($name, $type);
    }
  }

  if ($optname =~ /^(set|get|top)_/) {
    croak "Invalid option name for shorthand syntax: $optname";
  }

  return $self->get($optname);
}

#-----------------------------------------------------------------------------

sub DESTROY {
  my ($self) = @_;

  # nuffin();
}

#-----------------------------------------------------------------------------

=back

=cut

#-----------------------------------------------------------------------------

=head1 AUTHOR

Stanislaw Klekot, C<< <cpan at jarowit.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stanislaw Klekot.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<App::Getconf(3)>

=cut

#-----------------------------------------------------------------------------
1;
# vim:ft=perl:foldmethod=marker
