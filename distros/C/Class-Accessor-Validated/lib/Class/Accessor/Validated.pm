package Class::Accessor::Validated;

use strict;
use warnings;

use Class::Accessor::Fast;
use Class::Accessor;

use Exporter qw(import);

our @EXPORT_OK = qw(setup_accessors);
our $VERSION   = '0.04';

our $FOLLOW_BAD_PRACTICE = 0;

use parent qw(Exporter Class::Accessor::Fast);

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $arg_ref = ref $args[0] ? $args[0] : {@args};

  my @bad_keys;

  for my $maybe_valid_key ( keys %{$arg_ref} ) {
    my $follows_best_practice = $class->can("set_$maybe_valid_key") && $class->can("get_$maybe_valid_key");

    my $follows_bad_practice = $FOLLOW_BAD_PRACTICE && $class->can($maybe_valid_key);

    next if $follows_best_practice || $follows_bad_practice;

    push @bad_keys, $maybe_valid_key;
  }

  no strict 'refs';

  my %required_keys;

  for my $ancestor_class ( reverse _linear_isa($class) ) {
    my $symbol   = $ancestor_class . '::ATTRIBUTES';
    my $attr_ref = *{$symbol}{HASH};
    next if !$attr_ref;

    %required_keys = ( %required_keys, %{$attr_ref} );
  }

  my @missing_required_keys;

  for my $maybe_required_key ( keys %required_keys ) {
    next if !$required_keys{$maybe_required_key};
    next if exists $arg_ref->{$maybe_required_key};
    push @missing_required_keys, $maybe_required_key;
  }

  my @errors;

  if (@bad_keys) {
    push @errors, 'invalid argument(s): ' . join ', ', @bad_keys;
  }

  if (@missing_required_keys) {
    push @errors, 'required argument(s): ' . join ', ', @missing_required_keys;
  }

  if (@errors) {
    die join '; ', @errors;
  }

  return $class->SUPER::new($arg_ref);
}

########################################################################
sub setup_accessors {
########################################################################
  my ( $class, @keys ) = @_;
  Class::Accessor->follow_best_practice($class);
  Class::Accessor::Fast->mk_accessors( $class, @keys );

  return 1;
}

########################################################################
sub _linear_isa {
########################################################################
  my ($start_class) = @_;

  no strict 'refs';  ## no critic

  my @isa_list;
  my %seen;
  my @queue = ($start_class);

  while ( my $current = shift @queue ) {
    next if $seen{$current};
    $seen{$current} = 1;
    push @isa_list, $current;
    unshift @queue, @{ $current . '::ISA' };
  }

  return @isa_list;
}

1;

__END__

=pod

=head1 NAME

Class::Accessor::Validated - Drop-in constructor validation for
Class::Accessor::Fast-based classes

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    package MyApp::Thing;

    use parent 'Class::Accessor::Validated';

    our %ATTRIBUTES = (
        id   => 1,    # required
        name => 0,    # optional
    );

    __PACKAGE__->setup_accessors(keys %ATTRIBUTES);

    # Then in code:
    my $thing = MyApp::Thing->new({ id => 123 });

=head1 DESCRIPTION

C<Class::Accessor::Validated> extends L<Class::Accessor::Fast> to add
lightweight constructor-time validation for required and unexpected
arguments.

It supports the same hashref-based constructor pattern, and requires
you to define a C<%ATTRIBUTES> hash in your class (or inherited from a
parent class) to indicate which keys are required. Any key passed to
the constructor must correspond to an existing accessor.

This module is designed to be a minimal and backward-compatible
validator that requires no additional dependencies or heavy OO layers.

=head1 ADDITIONAL DETAILS

This module can also be used immediately in new subclasses, even when
the parent class does not itself inherit from
C<Class::Accessor::Validated>. As long as the subclass defines a
C<%ATTRIBUTES> hash and installs its accessors using setup_accessors,
the constructor validation will function correctly. This makes it
possible to incrementally adopt validation in an existing hierarchy
without modifying base classes - a practical solution for modernizing
older code or introducing stricter argument checking in new layers of
functionality.

Even in the absence of a C<%ATTRIBUTES hash>, the constructor will
still validate all arguments against the set of defined accessors. Any
option that does not correspond to known accessors (either get_foo and
set_foo or just foo) will be flagged as invalid. 

B<You are encouraged to C<follow_best_practice> since methods that are
not named C<set_> or C<get_> may be mistaken for accessors.>

However, any option that does match a known accessor but is not listed
in C<%ATTRIBUTES> will be assumed to be optional. This allows
subclasses to define additional accessors without needing to
explicitly extend C<%ATTRIBUTES>, and enables gradual adoption in
codebases where base classes are not yet updated for validation.

=head1 METHODS AND SUBROUTINES

=head2 new

  my $obj = My::Class->new({ foo => 1, bar => 2 });

The constructor performs the following checks:

=over 4

=item *

Any key passed must match an existing accessor (C<get_foo>, C<foo>,
etc.)

=item *

If a key is listed in C<%ATTRIBUTES> with a true value, it is
considered required

=item *

Keys not in C<%ATTRIBUTES> are assumed optional as long as accessors
exist

=item *

If invalid or missing keys are detected, the constructor throws an
error

=back

=head2 setup_accessors

  Class::Accessor::Validated->setup_accessors(__PACKAGE__, @keys);

Convenience method to install accessors and apply
C<follow_best_practice> for the calling package. This avoids having to
explicitly C<use Class::Accessor> in each class.

=head1 GLOBAL VARIABLES

=head2 $Class::Accessor::Validated::ALLOW_BAD_PRACTICE

If set to a true value, constructor validation will accept any method
name (e.g., C<foo>) as a valid accessor, even if it does not follow
the C<get_foo>/C<set_foo> naming pattern. This is useful for backward
compatibility with older C<Class::Accessor::Fast> code.

Defaults to false. Best practice is to use C<follow_best_practice> so
that accessors are unambiguously named and validated.

=head1 USAGE PATTERN

To use this module:

=over 4

=item *

Inherit from C<Class::Accessor::Validated>

=item *

Declare a C<%ATTRIBUTES> hash in your package

=item *

Call C<setup_accessors()> with the list of keys

=back

Subclasses do not need to redefine C<%ATTRIBUTES> unless they want to
introduce new required keys.

=head1 SEE ALSO

L<Class::Accessor>, L<Class::Accessor::Fast>

=head1 AUTHOR

Rob Lauer

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
