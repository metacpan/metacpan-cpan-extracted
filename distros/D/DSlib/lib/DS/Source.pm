#!perl

# ########################################################################## #
# Title:         Data stream generator
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Generates data stream data
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Source.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Source;

use strict;
use Carp;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.2 $' =~ /(\d+\.\d+)/;
our ($STATE) = '$State: Exp $' =~ /:\s+(.+\S)\s+\$$/;


sub new {
    my( $class, $out_type, $target ) = @_;

    my $self = {
        row => {}
    };
    bless $self, $class;

    if( defined( $out_type ) ) {
        $self->out_type( $out_type );
    }

    if( defined( $target ) ) {
        $self->attach_target( $target );
    }

    return $self;
}

sub attach_target {
    my( $self, $target ) = @_;

    assert( $target->isa('DS::Target') );
    # First break link with old target, if any
    if( $self->{target} ) {
        $self->{target}->{source} = undef;
    }
    if( $target->source( $self ) ) {
        $self->target( $target );
    }
}

# This is a primarily private method
# Important caveat: this method is just a field accessor method.
# Maintaining consistent links with target is handled by attach_target
sub target {
    my( $self, $target ) = @_;

    my $result;
    if( $target ) {
        assert($target->isa('DS::Target'));
        $self->{target} = $target;
        $result = 1;
    } else {
        $result = $self->{target};
    }
    return $result;        
}

# Send row to target
sub pass_row {
    my( $self, $row ) = @_;
    confess("Can't pass rows since no target has been set") unless $self->target;
    $self->target()->receive_row( $row );
}

sub out_type {
    my( $self, $type ) = @_;

    my $result;
    if( $type ) {
        assert($type->isa('DS::TypeSpec'));
        $self->{out_type} = $type;
    } else {
        $result = $self->{out_type};
    }
    return $result;        
}

1;

__END__
=pod

=head1 NAME

DS::Source - component that is the source of rows

=head1 DESCRIPTION

This class is the source of rows. It can be bound to any C<DS::Target>,
which will receive rows from it. Unless you are into writing complicated
classes, you will probably never need to inherit directly from this class.

If you need to write a class that retrieves data from outside a chain and
passes it on as rows, please take a look at C<DS::Importer>.

=head1 SUPER CLASSES

None.

=head1 METHODS

=head2 new( $class, $out_type, $target )

Constructor. Instantiates an object of class C<$class>, returning the type 
C<$out_type>, attaced to the target C<$target>. Besides C<$class>,
any of the parameters can be left out.

=head2 attach_target( $target )

Attaches target C<$target> to this object. This method also triggers
type checking, ensuring that the outgoing type of this object is
sufficient for C<$target>. If the type check fails, an exception
is thrown.

=head2 target( $target )

This is a method mostly for internal use. It will get or set the
target, bypassing type checks.

=head2 pass_row( $row )

Calling this metod will cause the transformer to pass C<$row> to the target
C<$target>.

=head2 out_type( $type )

This is an accessor that gets or sets the outgoing type of this object.

=head1 SEE ALSO

L<DS::Importer>, L<DS::Transformer>, L<DS::Target>.

=head1 AUTHOR

Written by Michael Zedeler.
