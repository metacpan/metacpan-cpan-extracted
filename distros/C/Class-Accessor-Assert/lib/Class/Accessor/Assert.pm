package Class::Accessor::Assert;
use 5.006;
use strict;
use warnings;
use base qw(Class::Accessor Class::Data::Inheritable);
use Carp qw(croak confess);
our $VERSION = '1.41';

sub _mk_accessors {
    my ( $self, $maker, @fields ) = @_;
    $self->mk_classdata("accessor_specs")
      unless $self->can("accessor_specs");

    my %spec = $self->parse_fields(@fields);
    $self->accessor_specs( { %spec, %{ $self->accessor_specs || {} } } );

    $self->SUPER::_mk_accessors( 'rw', keys %spec );

    {
        no strict 'refs';

        # additional methods for magic array methods
        my $class = ref $self || $self;
	# Note how we curry the subs with the lexical "$field":
	# The subs are closures and therefore have access to their lexical
	# scope. Clarity suffers from this, but the performance should be
	# about 25% higher than a cleaner approach due to a saved subroutine
	# call for every ary_*(...) call.
        for my $field ( grep { $spec{$_}{array} } keys %spec ) {
	    # foo_push sub
            *{"${class}::${field}_push"} = sub {
                my ( $self, @values ) = @_;
                $self->{$field} = [] unless defined $self->{$field};
                push @{ $self->{$field} }, @values;
            };
	    # foo_pop sub
            *{"${class}::${field}_pop"} = sub {
                my ( $self ) = @_;
                return pop @{ $self->{$field} || [] };
            };
	    # foo_unshift sub
            *{"${class}::${field}_unshift"} = sub {
                my ( $self, @values ) = @_;
                $self->{$field} = [] unless defined $self->{$field};
                unshift @{ $self->{$field} }, @values;
            };
	    # foo_shift sub
            *{"${class}::${field}_shift"} = sub {
                my ( $self ) = @_;
                return shift @{ $self->{$field} || [] };
            };
        }
    }
}

sub new {
    my ( $self, $stuff ) = @_;
    my $not_a_void_context = eval { %{ $stuff || {} } };
    croak "$stuff doesn't look much like a hash to me" if $@;
    if ( $self->can("accessor_specs") ) {
        my $spec = $self->accessor_specs;
        for my $k ( keys %$spec ) {
            confess "Required member $k not given to constructor"
              if $spec->{$k}->{required}
              and not exists $stuff->{$k};
            confess "Member $k needs to be of type " . $spec->{$k}->{class}
              if exists $spec->{$k}->{class}
              and exists $stuff->{$k}
              and !UNIVERSAL::isa( $stuff->{$k}, $spec->{$k}->{class} );
        }
    }
    return $self->SUPER::new($stuff);
}

sub set {
    return shift->SUPER::set(@_) unless $_[0]->can("accessor_specs");
    my ( $self, $key ) = splice( @_, 0, 2 );
    my $spec = $self->accessor_specs;
    return $self->SUPER::set( $key, @_ )
      if !exists $spec->{$key}
      or @_ > 1;    # No support for arrays
    confess "Member $key needs to be of type " . $spec->{$key}->{class}
      if defined $_[0]
      and exists $spec->{$key}->{class}
      and !UNIVERSAL::isa( $_[0], $spec->{$key}->{class} );

    $_[0] = [ $_[0] ]
      if defined $_[0]
      and $spec->{$key}->{array}
      and ref $_[0] ne 'ARRAY';

    $self->{$key} = $_[0];
}

sub get {
    return shift->SUPER::get(@_) unless $_[0]->can("accessor_specs");
    my ( $self, $key ) = splice( @_, 0, 2 );
    my $spec = $self->accessor_specs;
    return $self->SUPER::get( $key, @_ )
      if !exists $spec->{$key}
      or @_ > 1;    # No support for arrays
    if ( $spec->{$key}{array} ) {
        wantarray
          ? @{ $self->SUPER::get( $key, @_ ) || [] }
          : $self->SUPER::get( $key, @_ );
    }
    else {
        $self->SUPER::get( $key, @_ );
    }
}

sub parse_fields {
    my ( $self, @fields ) = @_;
    my %spec;
    for my $f (@fields) {
        my $orig_f = $f;    # For error reporting
        my %subspec;

        # All the tests go here
        $subspec{required} = $f =~ s/^\+//;
        $f =~ s/=(.*)// and $subspec{class} = $1;
        $subspec{array} = $f =~ s/^\@//;
        $f =~ /^\w+$/
          or croak "Couldn't understand field specification $orig_f";
        $spec{$f} = \%subspec;
    }
    return %spec;
}

1;
__END__

=head1 NAME

Class::Accessor::Assert - Accessors which type-check

=head1 SYNOPSIS

  use Class::Accessor::Assert;
  __PACKAGE__->mk_accessors( qw( +foo bar=Some::Class baz @bits ) );

=head1 DESCRIPTION

This is a version of L<Class::Accessor> which offers rudimentary
type-checking and existence-checking of arguments to constructors
and set accessors. 

To specify that a member is mandatory in the constructor, prefix its
name with a C<+>. To specify that it needs to be of a certain class
when setting that member, suffix C<=CLASSNAME>. Unblessed reference
types such as C<=HASH> or C<=ARRAY> are acceptable.

To specify that a member is an array, prefix its name with a C<@>.
These members also have the following four special methods that wrap
the builtin array operations C<push>, C<pop>, C<unshift>, and 
C<shift>:

    # for a @bits member:
    
    $y->bits_push(@new_values);
    print $y->bits_pop;
    
    $y->bits_unshift(@new_values);
    print $y->bits_shift;

The C<@> can be combined with the C<+> prefix to make a member that
is an array that you must set in the constructor. The C<+> must 
precede the C<@>.

    # 'foo' is required in the constructor
    __PACKAGE__->mk_accessors(qw( +@foo ));

=head1 SEE ALSO

L<Class::Accessor>

=head1 AUTHOR

This module is maintained by

  Steffen Mueller, accessor-module at steffen-mueller dot net

Original author is

  Simon Cozens, simon@simon-cozens.org

Please direct inquiries, bug reports, etc. towards the maintainer, not the
original author. Simon no longer provides support for this module, so please
respect that.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
