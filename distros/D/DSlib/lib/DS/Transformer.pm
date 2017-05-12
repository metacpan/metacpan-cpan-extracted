#!perl

# ########################################################################## #
# Title:         Data stream transformer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Transforms data stream
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer;

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.2 $' =~ /(\d+\.\d+)/;

require DS::TypeSpec;
require DS::Target;
require DS::Source;

our( @ISA ) = qw{ DS::Target DS::Source };


sub new {
    my( $class, $in_type, $out_type, $source, $target ) = @_;

    bless my $self = {}, $class;

    if( $in_type ) {
        $self->in_type( $in_type );
    }
    if( $out_type ) {
        $self->out_type( $out_type );
    }
    if( $source ) {
        $self->attach_source( $source );
    }
    if( $target ) {
        $self->attach_target( $target );
    }

    return $self;
}

# Override this method if you want to change how the transformer passes
# rows onto its target when this method is called. If you just want to
# transform the row without changing how data is passed on, override
# process() in stead.
# This method MUST NOT return anything. If errors occur, croak or die with exceptions
sub receive_row {
    my( $self, $row ) = @_;

    $self->pass_row( $self->process( $row ) );

    return;
}

# Process row (possibly transforming it) before passing it to
# the next transformer.
# Just no operation (this method is here to be overridden)
sub process {
    return $_[1];
}

1;

__END__
=pod

=head1 NAME

DS::Transformer - receives, transforms and passes on rows

=head1 DESCRIPTION

This class is the base class of all transformers in DS. If you need to
write a transformer, first consider if L<DS::Transformer::Sub> will do.
It supports any kind of row-wise transformations where there is a 
one-to-one correspondence between incoming and outgoing rows.

=head1 SUPER CLASSES

DS::Transformer is a mixin of L<DS::Source> and L<DS::Target>.

=head1 METHODS

=head2 process( $row )

Method for processing of ingoing data. This method is supposed
to be overridden. By default it will return C<$row>.

=head2 new( $class, $in_type, $out_type, $source, $target )

Constructor. Instantiates an object of class C<$class>, taking the
type C<$in_type>, returning the type C<$out_type>, attached to the source 
C<$source> and attaced to the target C<$target>. Besides C<$class>,
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

L<DS::Transformer::Sub>, L<DS::Source>, L<DS::Target>.

=head1 AUTHOR

Written by Michael Zedeler.
