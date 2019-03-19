package Class::Tiny::ConstrainedAccessor;

use 5.006;
use strict;
use warnings;
use Class::Tiny;

our $VERSION = '0.000003';

# Docs {{{1

=head1 NAME

Class::Tiny::ConstrainedAccessor - Generate Class::Tiny accessors that apply type constraints

=head1 SYNOPSIS

L<Class::Tiny> uses custom accessors if they are defined before the
C<use Class::Tiny> statement in a package.  This module creates custom
accessors that behave as standard C<Class::Tiny> accessors except that
they apply type constraints (C<isa> relationships).  Type constraints
can come from L<Type::Tiny>, L<MooseX::Types>, L<MooX::Types::MooseLike>,
L<MouseX::Types>, or L<Specio>.

Example of a class using this package:

    package SampleClass;
    use Scalar::Util qw(looks_like_number);

    use Type::Tiny;

    my $MediumInteger;
    BEGIN {
        # Create the type constraint
        $MediumInteger = Type::Tiny->new(
            name => 'MediumInteger',
            constraint => sub { looks_like_number($_) and $_ >= 10 and $_ < 20 }
        );
    }

    use Class::Tiny::ConstrainedAccessor {
        medint => $MediumInteger,           # create accessor sub medint()
        med_with_default => $MediumInteger,
    };

    # After using ConstrainedAccessor, actually define the class attributes.
    use Class::Tiny qw(medint regular), {
        med_with_default => 12,
    };

=head1 SUBROUTINES

=head2 import

Creates the accessors you have requested.

=cut

# }}}1

sub import {
    my $target = caller;
    my $package = shift;
    die "Need 'name => \$Constraint' pairs" if @_%2;

    my %constraints = @_;

    foreach my $k (keys(%constraints)) {
        my $constraint = $constraints{$k};

        my ($checker, $get_message) =
                _get_constraint_sub($constraint); # dies on failure

        # The accessor --- modified from the Class::Tiny docs based on
        # the source for C::T::__gen_accessor() and C::T::__gen_sub_body().
        #   Future TODO? use an accessor that is specific to the type of
        #   constraint object we have?
        my $accessor = sub {
            my $self_ = shift;
            if (@_) {                               # Set
                $checker->($_[0]) or die $get_message->($_[0]);
                return $self_->{$k} = $_[0];

            } elsif ( exists $self_->{$k} ) {       # Get
                return $self_->{$k};

            } else {                                # Get default
                my $defaults_ =
                    Class::Tiny->get_all_attribute_defaults_for( ref $self_ );

                my $def_ = $defaults_->{$k};
                $def_ = $def_->() if ref $def_ eq 'CODE';

                $checker->($def_) or die $get_message->($def_);
                return $self_->{$k} = $def_;
            }
        }; #accessor()

        { # Install the accessor
            no strict 'refs';
            my $dest = $target . '::' . $k;
            *{ $dest } = $accessor;
        }

    } #foreach constraint
} #import()

# _get_constraint_sub: Get the subroutine for a constraint.
# Returns two coderefs: checker and get_message.
sub _get_constraint_sub {
    my ($type) = @_;
    my ($checker, $get_message);

    DONE: {

        if ( eval { $type->can('compiled_check') }) { # Type::Tiny
            $checker = $type->compiled_check();
            $get_message = sub { $type->get_message($_[0]) };
            last DONE;
        }

        if (my $method = eval { $type->can('inline_check') || $type->can('_inline_check') }) { # Moose
            $checker = eval { eval sprintf 'sub { my $value = shift; %s }', $type->$method('$value') };
                # Note: will fail if type cannot be inlined
            $get_message = sub { 'Constraint failed' };     # TODO
            last DONE if $checker;
        }

        if (eval { $type->can('check') } ) { # Moose, Mouse
            $checker = sub { $type->check(@_) };
            $get_message = sub { 'Constraint failed' };     # TODO
            last DONE;
        }

        if (ref($type) eq 'CODE') { # MooX::Types
            $checker = sub { eval { $type->(@_); 1 } };
            $get_message = sub { 'Constraint failed' };     # TODO
            last DONE;
        }

        if(eval { $type->can('value_is_valid') }) { # Specio::Constraint::Simple
            $checker = sub { $type->value_is_valid(@_) };
            $get_message = sub { 'Value is not a ' . $type->description };
            last DONE;
        }

    } #DONE

    die "I don't know how to use this type (" . (ref($type)||'scalar') . ")"
        unless $checker and $get_message;

    return ($checker, $get_message);
} #_get_constraint_sub()

1; # End of Class::Tiny::ConstrainedAccessor
# Rest of the docs {{{1
__END__

=head1 AUTHOR

Christopher White, C<< <cxwembedded at gmail.com> >>.  Thanks to
Toby Inkster for code contributions.

=head1 BUGS

Please report any bugs or feature requests through the GitHub Issues interface
at L<https://github.com/cxw42/Class-Tiny-ConstrainedAccessor>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Tiny::ConstrainedAccessor

You can also look for information at:

=over 4

=item * GitHub (report bugs here)

L<https://github.com/cxw42/Class-Tiny-ConstrainedAccessor>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Tiny-ConstrainedAccessor>

=item * Search CPAN

L<https://metacpan.org/release/Class-Tiny-ConstrainedAccessor>

=back

=head1 LICENSE

Copyright 2019 Christopher White.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Apache License (2.0). You may obtain a
copy of the full license at:

L<https://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
# }}}1
# vi: set fdm=marker:
