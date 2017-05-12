package Data::BISON::Base;

use warnings;
use strict;
use Carp;
use base qw(Exporter);

our @ISA;

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;

    my $args = {};
    if ( @_ ) {
        $args = shift;
        croak "The only argument to new must be a hash reference of options"
          if @_ || ref $args ne 'HASH';
    }

    $self->_pre_init( $args );
    $self->__parse_args( $args );
    $self->_initialize( $args );

    if ( my @extra = sort keys %$args ) {
        croak "Illegal option(s): ", join( ', ', @extra );
    }

    return $self;
}

sub _pre_init    { }
sub __parse_args { }
sub _initialize  { }

# Generate methods
sub import {
    my $class  = shift;
    my $caller = caller;

    if ( my $attr_spec = shift ) {
        no strict 'refs';

        my %default = (

            # Capabilities i=init, s=set
            can => 'is',

            # Set the value of an attribute
            set => sub {
                my $self = shift;
                my $attr = shift;
                my $val  = shift;
                $self->{$attr} = $val;
            },

            # Get the value of an attribute
            get => sub {
                my $self = shift;
                my $attr = shift;
                return $self->{$attr};
            },

            # Return the default value for an attribute
            default => sub {
                my $self = shift;
                my $attr = shift;
                croak "Option $attr is required";
            },
        );

        while ( my ( $attr, $spec ) = each %$attr_spec ) {
            while ( my ( $handler, $def ) = each %default ) {
                $spec->{$handler} = $def unless exists $spec->{$handler};
            }

            # Turn keys that map to a value into a sub that returns
            # that value
            for my $handler ( qw( get default ) ) {
                unless ( ref $spec->{$handler} eq 'CODE' ) {
                    my $value = $spec->{$handler};
                    $spec->{$handler} = sub { return $value };
                }
            }

            # Getter / setter
            my $getter = $spec->{get};
            if ( $spec->{can} =~ /s/ ) {
                my $setter = $spec->{set};
                *{ $caller . '::' . $attr } = sub {
                    my $self = shift;
                    return $getter->( $self, $attr ) unless @_;
                    return $setter->( $self, $attr, @_ );
                };
            }
            else {
                *{ $caller . '::' . $attr } = sub {
                    my $self = shift;
                    return $getter->( $self, $attr ) unless @_;
                    croak "Attribute $attr is read-only";
                };
            }
        }

        *{ $caller . '::__parse_args' } = sub {
            my $self = shift;
            my $args = shift;

            {
                local @ISA = @{ $caller . '::ISA' };
                $self->SUPER::__parse_args( $args );
            }

            while ( my ( $attr, $spec ) = each %$attr_spec ) {
                my @value;
                if ( exists $args->{$attr} ) {
                    croak "Argument $attr can not be set during initialisation"
                      unless $spec->{can} =~ /i/;
                    @value = delete $args->{$attr};
                }
                else {
                    @value = $spec->{default}->( $self, $attr );
                }
                $spec->{set}->( $self, $attr, @value );
            }
        };
    }
}

1;
__END__

=head1 NAME

Data::BISON::Base - Base class for BISON encoder, decoder

=head1 VERSION

This document describes Data::BISON::Base version 0.0.3

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
