package CLI::Simple::Options;

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars);
use List::Util qw(any);
use Role::Tiny;
use Scalar::Util qw(reftype);

our $VERSION = '2.7.0';

########################################################################
sub normalize_option_specs {
########################################################################
  my ( $self, $declarations ) = @_;

  croak 'Option declarations must be an array or hash reference'
    if !ref $declarations || ( reftype($declarations) ne 'ARRAY' && reftype($declarations) ne 'HASH' );

  my @specs;
  my %metadata;

  my @declarations;

  if ( reftype($declarations) eq 'ARRAY' ) {
    foreach my $spec ( @{$declarations} ) {
      croak 'Option specifications must be strings'
        if ref $spec;
      push @declarations, [ $spec, {} ];
    }
  }
  else {
    foreach my $spec ( keys %{$declarations} ) {
      my $attributes = $declarations->{$spec};
      croak sprintf q{Attributes for option '%s' must be a hash reference}, $spec
        if !ref $attributes || reftype($attributes) ne 'HASH';
      push @declarations, [ $spec, $attributes ];
    }
  }

  foreach my $declaration (@declarations) {
    my ( $spec, $attributes ) = @{$declaration};
    my ($name) = $spec =~ /\A([\w-]+)/;
    croak sprintf q{Invalid option specification: %s}, $spec
      if !defined $name;

    $name =~ s/-/_/g;
    croak sprintf q{Duplicate canonical option name: %s}, $name
      if exists $metadata{$name};

    my $inferred_type = _infer_option_type($spec);
    my %entry         = ( spec => $spec, %{$attributes} );

    if ( defined $inferred_type ) {
      $entry{inferred_type} = $inferred_type;
      $entry{type} //= $inferred_type;
    }

    $entry{collection} = 'array' if $spec =~ /[=:][sif]@\z/;
    $entry{collection} = 'hash'  if $spec =~ /[=:][sif]%\z/;
    _check_option_constraints( $name, \%entry );

    push @specs, $spec;
    $metadata{$name} = \%entry;
  }

  return ( \@specs, \%metadata );
}

########################################################################
sub _infer_option_type {
########################################################################
  my ($spec) = @_;

  # Only infer from recognized Getopt::Long value modifiers. Unknown
  # suffixes are left uninterpreted rather than guessing a type.
  # Extract the suffix after the option names, including optional
  # arguments and multi-value (@ or %) destinations.
  my ($modifier) = $spec =~ /[=:]([sif])(?:[@%])?\z/;
  if ( defined $modifier ) {
    return 'string'  if $modifier eq 's';
    return 'integer' if $modifier eq 'i';
    return 'number'  if $modifier eq 'f';
  }

  return 'integer'
    if $spec =~ /\+\z/;

  return 'boolean'
    if $spec =~ /!\z/ || $spec =~ /\A[\w-]+(?:[|][\w-]+)*\z/;

  return;
}

########################################################################
sub _check_option_constraints {
########################################################################
  my ( $name, $entry ) = @_;

  my %allowed = map { $_ => 1 } qw(
    spec description inferred_type type collection required min max
    min_length max_length enum finalize slurp
  );
  foreach my $key ( keys %{$entry} ) {
    croak sprintf q{Unknown attribute '%s' for option '%s'}, $key, $name
      if !exists $allowed{$key};
  }

  if ( exists $entry->{slurp} ) {
    croak sprintf q{slurp must be 0 or 1 for option '%s'}, $name
      if !defined $entry->{slurp}
      || ref $entry->{slurp}
      || $entry->{slurp} !~ /\A[01]\z/;

    croak sprintf q{slurp requires type 'file' for option '%s'}, $name
      if $entry->{slurp} && ( $entry->{type} // q{} ) ne 'file';

    croak sprintf q{slurp does not support collection options: %s}, $name
      if $entry->{slurp} && $entry->{collection};
  }

  if ( exists $entry->{finalize} ) {
    croak sprintf q{finalize must be a code reference for option '%s'}, $name
      if !ref $entry->{finalize} || reftype( $entry->{finalize} ) ne 'CODE';
  }

  if ( exists $entry->{required} ) {
    croak sprintf q{required must be 0 or 1 for option '%s'}, $name
      if !defined $entry->{required} || $entry->{required} !~ /\A[01]\z/;
  }

  my $type        = $entry->{type};
  my %valid_types = map { $_ => 1 } qw(string integer number boolean file directory);
  if ( defined $type ) {
    croak sprintf q{Unknown type '%s' for option '%s'}, $type, $name
      if !exists $valid_types{$type};
  }

  my $inferred = $entry->{inferred_type};
  if ( defined $type && defined $inferred ) {
    my $compatible
      = $type eq $inferred
      || ( $inferred eq 'string'  && any { $type eq $_ } qw(file directory) )
      || ( $inferred eq 'integer' && $type eq 'number' );
    croak sprintf q{Type '%s' conflicts with specification for option '%s'}, $type, $name
      if !$compatible;
  }

  foreach my $key (qw(min max min_length max_length)) {
    next if !exists $entry->{$key};
    croak sprintf q{%s must be numeric for option '%s'}, $key, $name
      if !defined $entry->{$key}
      || ref $entry->{$key}
      || $entry->{$key} !~ /\A[+-]?(?:\d+(?:\.\d*)?|\.\d+)\z/;
  }

  if ( exists $entry->{min} || exists $entry->{max} ) {
    croak sprintf q{Numeric bounds require a numeric option: %s}, $name
      if !defined $type || !any { $type eq $_ } qw(integer number);
    croak sprintf q{min exceeds max for option '%s'}, $name
      if exists $entry->{min} && exists $entry->{max} && $entry->{min} > $entry->{max};
  }

  if ( exists $entry->{min_length} || exists $entry->{max_length} ) {
    croak sprintf q{Length bounds require a string option: %s}, $name
      if !defined $type || $type ne 'string';
    foreach my $key (qw(min_length max_length)) {
      next if !exists $entry->{$key};
      croak sprintf q{%s must be a nonnegative integer for option '%s'}, $key, $name
        if $entry->{$key} !~ /\A\d+\z/;
    }
    croak sprintf q{min_length exceeds max_length for option '%s'}, $name
      if exists $entry->{min_length}
      && exists $entry->{max_length}
      && $entry->{min_length} > $entry->{max_length};
  }

  if ( exists $entry->{enum} ) {
    croak sprintf q{enum must be a nonempty array reference for option '%s'}, $name
      if !ref $entry->{enum}
      || reftype( $entry->{enum} ) ne 'ARRAY'
      || !@{ $entry->{enum} };
    foreach my $item ( @{ $entry->{enum} } ) {
      croak sprintf q{enum entries must be defined scalars for option '%s'}, $name
        if !defined $item || ref $item;
    }
  }

  return;
}

########################################################################
sub validate_options {
########################################################################
  my ($self) = @_;

  my $metadata = $self->{_cli_simple_option_metadata} // {};

  foreach my $name ( sort keys %{$metadata} ) {
    my $rule   = $metadata->{$name};
    my $getter = 'get_' . $name;
    my $value  = $self->can($getter) ? $self->$getter() : undef;

    if ( !defined $value ) {
      croak sprintf q{Required option '%s' is undefined}, $name
        if $rule->{required};
      next;
    }

    my @values = ($value);
    if ( $rule->{collection} ) {
      my $collection = $rule->{collection};
      croak sprintf q{Option '%s' requires a %s reference}, $name, $collection
        if !ref $value || reftype($value) ne uc( $collection eq 'array' ? 'array' : 'hash' );
      @values = $collection eq 'array' ? @{$value} : values %{$value};
    }
    elsif ( ref $value ) {
      croak sprintf q{Option '%s' requires a scalar value}, $name;
    }

    foreach my $item (@values) {
      _validate_option_value( $name, $item, $rule );
    }
  }

  return $self;
}

########################################################################
sub finalize_options {
########################################################################
  my ($self) = @_;

  my $metadata = $self->{_cli_simple_option_metadata} // {};

  foreach my $name ( sort keys %{$metadata} ) {
    my $rule      = $metadata->{$name};
    my $finalizer = $rule->{finalize};
    my $slurp     = $rule->{slurp} // 0;
    next if !$slurp && !defined $finalizer;

    my $getter = 'get_' . $name;
    my $setter = 'set_' . $name;

    croak sprintf q{Missing accessor for option '%s'}, $name
      if !$self->can($getter) || !$self->can($setter);

    my $value = $self->$getter();
    next if !defined $value;

    if ($slurp) {
      my $content;

      my $ok = eval {
        open my $fh, '<', $value
          or die sprintf q{Cannot open '%s': %s}, $value, $OS_ERROR;

        local $RS = undef;

        $content = <$fh>;

        die sprintf q{Cannot read '%s': %s}, $value, $OS_ERROR
          if !defined $content && !eof $fh;

        $content //= q{};

        close $fh
          or die sprintf q{Cannot close '%s': %s}, $value, $OS_ERROR;
        1;
      };

      if ( !$ok ) {
        my $error = $EVAL_ERROR;
        croak sprintf q{Slurp failed for option '%s': %s}, $name, $error;
      }

      $value = $content;
    }

    if ( defined $finalizer ) {
      my $result;
      my $ok = eval {
        $result = $finalizer->( $self, $value );
        1;
      };

      if ( !$ok ) {
        my $error = $EVAL_ERROR;
        croak sprintf q{Finalization failed for option '%s': %s}, $name, $error;
      }
      $value = $result;
    }

    $self->$setter($value);
  }

  return $self;
}

########################################################################
sub _validate_option_value {
########################################################################
  my ( $name, $value, $rule ) = @_;

  croak sprintf q{Option '%s' contains an undefined value}, $name
    if !defined $value;

  croak sprintf q{Option '%s' contains a reference instead of a scalar}, $name
    if ref $value;

  my $type = $rule->{type};
  if ( defined $type ) {
    if ( $type eq 'integer' || $type eq 'boolean' ) {
      croak sprintf q{Option '%s' must be an integer}, $name
        if $value !~ /\A[+-]?\d+\z/;
    }
    elsif ( $type eq 'number' ) {
      croak sprintf q{Option '%s' must be a number}, $name
        if $value !~ /\A[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\z/;
    }
    elsif ( $type eq 'file' ) {
      croak sprintf q{Option '%s' must be an existing file}, $name
        if !-f $value;
    }
    elsif ( $type eq 'directory' ) {
      croak sprintf q{Option '%s' must be an existing directory}, $name
        if !-d $value;
    }
  }

  if ( exists $rule->{min} ) {
    croak sprintf q{Option '%s' must be >= %s}, $name, $rule->{min}
      if $value < $rule->{min};
  }
  if ( exists $rule->{max} ) {
    croak sprintf q{Option '%s' must be <= %s}, $name, $rule->{max}
      if $value > $rule->{max};
  }
  if ( exists $rule->{min_length} ) {
    croak sprintf q{Option '%s' is shorter than %s characters}, $name, $rule->{min_length}
      if length($value) < $rule->{min_length};
  }
  if ( exists $rule->{max_length} ) {
    croak sprintf q{Option '%s' exceeds %s characters}, $name, $rule->{max_length}
      if length($value) > $rule->{max_length};
  }
  if ( exists $rule->{enum} ) {
    croak sprintf q{Option '%s' has an unrecognized value}, $name
      if !any { $_ eq $value } @{ $rule->{enum} };
  }

  return;
}

1;

## no critic

__END__

=pod

=encoding utf8

=head1 NAME

CLI::Simple::Options - option normalization, validation, and finalization

=head1 DESCRIPTION

This role implements option normalization, validation, and finalization
for L<CLI::Simple>. For application-facing declarations, supported types,
constraints, and collection semantics, see
L<CLI::Simple/OPTION DECLARATIONS AND VALIDATION>.

=head1 METHODS AND SUBROUTINES

=head2 normalize_option_specs

  my ($specs, $metadata) = $self->normalize_option_specs($declarations);

Returns an array reference of Getopt::Long specifications and a hash
reference of associated option metadata. The supplied declarations are
not modified.

Metadata is keyed by the first name in the option specification, with
hyphens converted to underscores. Duplicate canonical names cause an
exception. Each entry includes C<spec>, the original specification,
and the declared attributes. When a type can be inferred,
C<inferred_type> records it and C<type> defaults to that value unless
an explicit type was supplied. Recognized collection suffixes produce
a C<collection> entry of C<array> or C<hash>. Unknown modifiers do not
produce an inferred type. Declaration constraints are checked during
normalization.

=head2 validate_options

  $self->validate_options;

Validates all defined option values against their metadata. Required
options must be defined after providers and defaults are applied. Optional
undefined values are skipped. Collection specifications validate each
array element or hash value. A defined collection must have the expected
reference type; each element or value must be a defined scalar. Fails
with an exception on invalid values. Returns the application instance.

=head2 finalize_options

  $self->finalize_options;

Invokes each declared C<finalize> code reference once for a defined option
value, after validation. The callback receives the application instance and current value, in that order.
For C<type =E<gt> file>, C<slurp =E<gt> 1> first reads the validated pathname
and passes its contents to the callback. With no callback, the contents
become the stored option value. C<slurp> is only supported for scalar file
options. The result replaces the accessor contents without further validation.
Optional undefined values are skipped. A callback exception is reported
with the option name. Finalizers may return references or C<undef>.
Options are processed in sorted canonical name order. Returns the
application instance.

=cut
