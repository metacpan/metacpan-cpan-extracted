#!perl

# ########################################################################## #
# Title:         Data stream sink
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Receives data from data stream
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Target.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# #TODO Sources should not by default be constructed with an explicit typespec, since this may be derived from the data source
# ########################################################################## #

package DS::Target;

use strict;
use Carp qw{ croak cluck confess carp };
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.2 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $source_type, $source ) = @_;

    my $self = {};
    bless $self, $class;
    
    if( defined( $source_type ) ) {
        $self->in_type( $source_type );
    }
    
    if( defined( $source ) ) {
        $self->attach_source( $source );
    }
    
    return $self;
}

# Receives row - invoked by source.
sub receive_row {
    confess("This method is abstract. Don't call it. Override it.");
}

sub attach_source {
    my( $self, $source ) = @_;
    
    my $result;
    
    assert( $source, '$source should be defined' );
    assert( $source->isa('DS::Source'), "ref(\$source) = " . ref( $source ) . " != DS::Source" );
    
    # First break link with old source, if any
    if( $self->{source} ) {
        $self->{source}->{target} = undef;
    }
    if( $self->source( $source ) ) {
        $source->target( $self );
        $result = 1;
    }
    return $result;
}

# This is a primarily private method
# Important caveat: this method is just a field accessor method.
# Maintaining consistent links with source is handled by attach_source
sub source {
    my( $self, $source ) = @_;

    my $result;
    if( $source ) {
        assert($source->isa('DS::Source'));
        if( my $source_type = $source->out_type ) {
            if( not $self->validate_source_type( $source_type ) ) {
                my $target_fields = join(", ", keys %{$self->in_type->{fields}});
                my $source_fields = join(", ", keys %{$source_type->{fields}});
                croak("Validation of source ($source with fields $source_fields) for me ($self with fields $target_fields) failed.");
            } #TODO Consider throwing a type incompatibility exception here
        } else {
            cluck("Type checking of stream from $source to $self skipped because source has no outgoing type specification.");
        }
        $self->{source} = $source;
        $result = 1;
    } else {
        $result = $self->{source};
    }
    return $result;        
}

sub validate_source_type {
    my( $self, $source_type ) = @_;
    my $result = 1;
    # We accept if the sender of data are passing more fields to us, than we require
    if( $self->in_type ) {
        $result = $source_type->contains( $self->in_type );
    } else {
        cluck("Type checking of stream to $self skipped because $self has no ingoing type specification.");
    }
    return $result;
}

sub in_type {
    my( $self, $type ) = @_;

    my $result;
    if( defined( $type ) ) {
        assert($type->isa('DS::TypeSpec'));
        $self->{in_type} = $type;
    } else {
        $result = $self->{in_type};
    }
    return $result;        
}

1;

__END__
=pod

=head1 NAME

DS::Target - target of rows.

=head1 DESCRIPTION

This class is the target of rows. It can be bound to any C<DS::Source>,
which will send rows to it. Unless you are into writing complicated
classes, you will probably never need to inherit directly from this class.

=head1 SUPER CLASSES

None.

=head1 METHODS

=head2 new( $class, $in_type, $source )

Constructor. Instantiates an object of class C<$class>, taking the type 
C<$in_type>, attached to the source C<$source>. Besides C<$class>, any of the
parameters can be left out.

=head2 receive_row( $row )

Triggers processing of C<$row>. This method calls C<process> with
C<$row>, and then passes the result to C<pass_row>.

=head2 attach_source( $source )

Attaches C<$source> as source. This method also validates data types
by calling C<validate_source_type>, throwing an exception if the 
validation fails.

=head2 source( $source )

Accessor for source. This method sets the source of this object and 
triggers type checking.

=head2 validate_source_type( $source_type )

Validates source type. If the C<$source_type> is not valid, it returns
false, true otherwise. By default, this method ensures that the ingoing 
type of this object contains no fields not specified in C<$source_type>.
Override if you need more complex checking.

=head2 in_type( $type )

Accessor for ingoing type.

=head1 SEE ALSO

L<DS::Transformer>, L<DS::Source>.

=head1 AUTHOR

Written by Michael Zedeler.
