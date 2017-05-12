#!/usr/bin/perl

=head1 NAME

App::Getconf::Node - TODO: fill me

=head1 SYNOPSIS

TODO: fill me

=cut

package App::Getconf::Node;

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

TODO: fill me

Supported options:

=over

=item C<type>

=item C<check>

=item C<storage>

C<scalar>, C<array>, C<hash>

=item C<help>

=item C<value>

=item C<default>

=item C<alias>

=back

=cut

sub new {
  my ($class, %opts) = @_;

  my $self = bless {
    type    => $opts{type} || "string",
    check   => $opts{check},
    storage => $opts{storage} || "scalar",
    help    => $opts{help},
    #value   => $opts{value}, # NOTE: existence of the key will be used
    #default => $opts{default},
    alias   => $opts{alias},
  }, $class;

  # not a supported type
  if (not grep { $_ eq $self->{type} } qw{flag bool int float string}) {
    croak "Not a supported type: $self->{type}";
  }

  if ($self->{type} eq 'flag') {
    if ($self->{storage} ne 'scalar') {
      croak "Unsupported combination: flag with non-scalar storage";
    }
    $self->{value} = 0;
  }

  if ($self->{type} eq 'bool' && $self->{storage} ne 'scalar') {
    croak "Unsupported combination: bool with non-scalar storage";
  }

  if ($self->{storage} eq 'array') {
    $self->{value} = [];
  } elsif ($self->{storage} eq 'hash') {
    $self->{value} = {};
  }

  # not a supported check type
  my $check_type = ref $self->{check};
  if ($self->{check} &&
      !($check_type eq 'CODE' ||
        $check_type =~ /(^|::)Regexp$/ ||
        $check_type eq 'ARRAY')) {
    croak "Unknown check type: $check_type";
  }

  $self->set($opts{value}) if exists $opts{value};
  $self->{default} = $self->verify($opts{default}) if exists $opts{default};

  return $self;
}

#-----------------------------------------------------------------------------

=item C<uses_arg()>

Method tells whether this option I<accepts> an argument passed in command line
(but it may be still possible not to pass an argument to this option; see
C<requires_arg()> method).

=cut

sub uses_arg {
  my ($self) = @_;

  return $self->{type} eq "int" || $self->{type} eq "float" ||
         $self->{type} eq "string" || $self->{type} eq "bool";
}

=item C<requires_arg()>

Method tells whether this option I<requires> an argument in command line.

=cut

sub requires_arg {
  my ($self) = @_;

  return !($self->{type} eq 'flag' || $self->{type} eq 'bool' ||
           exists $self->{default});
}

=item C<help()>

Retrieve help message for this option.

=cut

sub help {
  my ($self) = @_;

  return $self->{help};
}

#-----------------------------------------------------------------------------

=item C<alias()>

If the node is an alias, method returns what option it points to.

If the node is autonomous, method returns C<undef>.

=cut

sub alias {
  my ($self) = @_;

  return $self->{alias};
}

#-----------------------------------------------------------------------------

=item C<set($value)>

=item C<set($key, $value)>

Set value of this option. The second form is for options with I<hash> storage.

=cut

sub set {
  my ($self, $key, $value) = @_;

  if (@_ == 2) {
    # second argument is actually the value and there's no key
    $value = $key;
    $key   = undef;
  }

  if (@_ == 1 && $self->requires_arg) {
    croak "Option requires an argument, but none was provided";
  }

  if (@_ > 1 && !$self->uses_arg) {
    croak "Option doesn't use an argument, but one was provided";
  }

  if ($self->storage eq 'hash') {
    # TODO: how about an array as the value?
    if (defined $key) {
      $self->{value}{$key} = $self->verify($value);
    } elsif ($value =~ /^(.*?)=(.*)$/) {
      $self->{value}{$1} = $self->verify($2);
    } else {
      croak "For hash option key=value pair must be provided";
    }
    return;
  }

  if (defined $key) {
    croak "Can't store key=value pair in @{[ $self->storage ]} storage";
  }

  if ($self->storage eq 'array') {
    if (ref $value eq 'ARRAY') {
      push @{ $self->{value} }, @$value;
    } else {
      push @{ $self->{value} }, $value;
    }
    return;
  }

  if (ref $value) {
    croak "Can't store @{[ ref $value ]} in scalar storage";
  }

  if ($self->type eq 'flag') {
    # for flags, just increment the counter
    $self->{value} += 1;
  } elsif ($self->type eq 'bool' && @_ == 1) {
    # if Boolean option with no argument is being set, it means the option
    # value is TRUE
    $self->{value} = 1;
  } elsif (@_ == 1 && exists $self->{default}) {
    $self->{value} = $self->{default};
  } else {
    $self->{value} = $self->verify($value);
  }
}

=item C<get()>

Retrieve value of this option.

=cut

sub get {
  my ($self) = @_;

  return $self->{value};
}

=item C<has_value()>

Tell whether the value was set somehow (with command line, config or with
initial value).

=cut

sub has_value {
  my ($self) = @_;

  return exists $self->{value};
}

=item C<has_default()>

Tell whether the value was set somehow (with command line, config or with
initial value).

=cut

sub has_default {
  my ($self) = @_;

  return exists $self->{default};
}

=item C<type()>

Determine what data type this option stores.

See C<new()> for supported types.

=cut

sub type {
  my ($self) = @_;

  return $self->{type};
}

=item C<storage()>

Determine what kind of storage this option uses.

Returned value: C<hash>, C<array> or C<scalar>.

=cut

sub storage {
  my ($self) = @_;

  return $self->{storage};
}

=item C<enum()>

If the option is enum (check was specified as an array of values), arrayref of
the values is returned. Otherwise, method returns C<undef>.

=cut

sub enum {
  my ($self) = @_;

  return ref $self->{check} eq 'ARRAY' ? $self->{check} : undef;
}

#-----------------------------------------------------------------------------

=item C<verify($value)>

Check correctness of C<$value> for this option.

Method will C<die()> if the value is incorrect.

For convenience, C<$value> is returned. This way following is possible:

  my $foo = $node->verify($value);

=cut

sub verify {
  my ($self, $value) = @_;

  my $type  = $self->{type};
  my $check = $self->{check};

  eval {
    # convert warnings to errors
    local $SIG{__WARN__} = sub { die $@ };

    if ($type eq 'string') {
      $value = defined $value ? "$value" : undef;
    } elsif ($type eq 'int') {
      # TODO: better check
      $value = int(0 + $value);
    } elsif ($type eq 'float') {
      # TODO: better check
      $value = 0.0 + $value;
    } elsif ($type eq 'bool') {
      if (defined $value && $value =~ /^(1|true|yes)$/i) {
        $value = 1;
      } elsif (defined $value && $value =~ /^(0|false|no)$/i) {
        $value = 0;
      } else {
        die "can't convert $value to bool";
      }
    }
    # XXX: flags are not supposed to be processed by this function
  };

  # on any warning, assume the data is not in correct format
  if ($@) {
    croak "Invalid value \"$value\" for type $type";
  }
  if ($type eq 'flag') {
    croak "Flag can't have a value";
  }

  # check for correctness

  if (not $self->{check}) {
    # no check, so everything is OK

    return $value;
  } elsif (ref $self->{check} eq 'CODE') {
    # check based on function

    if (do { local $_ = $value; $self->{check}->($_) }) {
      return $value;
    } else {
      croak "Value \"$value\" ($type) was not accepted by check";
    }
  } elsif (ref($self->{check}) =~ /(^|::)Regexp$/) {
    # check based on regexp

    my $re = $self->{check};
    if ($value =~ /$re/) {
      return $value;
    } else {
      croak "Value \"$value\" ($type) was not accepted by regexp check";
    }
  } elsif (ref $self->{check} eq 'ARRAY') {
    if (!defined $value && grep { !defined } @{ $self->{check} }) {
      return $value;
    }
    if (defined $value && grep { $_ eq $value } @{ $self->{check} }) {
      return $value;
    }
    $value = defined $value ? "\"$value\"" : "<undef>";
    croak "Invalid value $value for enum";
  }

  # XXX: never reached
  die "Unknown check type: @{[ ref $self->{check} ]}";
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
# vim:ft=perl
