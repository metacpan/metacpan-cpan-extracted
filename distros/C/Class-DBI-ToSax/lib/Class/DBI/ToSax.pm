package Class::DBI::ToSax;
# @(#) $Id: ToSax.pm,v 1.25 2003/10/14 15:11:01 dom Exp $

# There's a bug in UNIVERSAL::isa() in 5.6.0 :(
use 5.006001;
use strict;
use warnings;

our $VERSION = '0.10';

use base qw( Class::Data::Inheritable );

use Carp qw( croak );
use NEXT;

sub _emit_sax_value {
    my $self = shift;
    my ( $handler, $col, $val, %opt ) = @_;
    if ( ref( $val ) && $val->can( 'to_sax' ) ) {
        # Record ourselves for our children.
        $opt{ _ancestors } ||= [];
        push @{ $opt{ _ancestors } }, $self;
        $val->to_sax( $handler, %opt );
    } else {
        my $data = {
            LocalName    => $col,
            Name         => $col,
            NamespaceURI => '',
            Prefix       => '',
        };
        $handler->start_element( $data );
        $val = '' if !defined $val || length $val == 0;
        $handler->characters(  { Data => $val } );
        $handler->end_element( $data );
    }
}

our %seen;
sub to_sax {
    my $self  = shift;
    my $class = ref $self;
    my ( $handler, %opt ) = @_;
    croak "usage: to_sax(handler,opt)\n"
      unless $handler && ref $handler && $handler->can( 'start_element' );

    # NB: Hack alert!  Calling this in array context /should/ work
    # correctly in all versions of Class::DBI, whether before or after
    # MCPK support was added.
    my @pk = $self->primary_column;
    # Avoid a warning with an undef id.  In reality, this should never
    # happen, but I've got non-database-backed objects that get
    # created without and id.  So I have to be careful here.
    my $id       = join '/', map { defined $_ ? $_ : '' } $self->get( @pk );
    my $table    = $class->table;
    my $toplevel = $opt{ notoplevel } ? 0 : !scalar %seen;
    my $wrapper  = delete $opt{ wrapper } || $self->table;

    # Ensure that we never have the same class twice in the call stack.
    return if $seen{ "$table-$id" };
    local %seen = %seen;
    $seen{ "$table-$id" }++;

    $handler->start_document( {} ) if $toplevel;
    my $table_data = {
        Name         => $wrapper,
        LocalName    => $wrapper,
        NamespaceURI => '',
        Prefix       => '',
        Attributes   => {
            '{}id' => {
                LocalName    => 'id',
                Name         => 'id',
                NamespaceURI => '',
                Prefix       => '',
                Value        => $id,
            },
        },
    };
    $handler->start_element( $table_data );

    if ( $toplevel || $self->_stop_recursion( %opt ) ) {
        my %has_a = map { $_ => 1 } @{ $self->_has_a_methods || [] };
        my %pk    = map { $_ => 1 } @pk;
        my @plain = grep { !$pk{ $_ } && !$has_a{ $_ } } $self->columns;

        foreach my $col ( sort @plain ) {
            $self->_emit_sax_value( $handler, $col, $self->$col, %opt );
        }

        foreach my $col ( sort keys %has_a ) {
            $self->_emit_sax_value( $handler, $col, $self->$col, %opt,
                wrapper => $col );
        }

        foreach my $col ( sort @{ $self->_has_many_methods || [] } ) {
            $self->_emit_sax_value( $handler, $col, $_, %opt )
                foreach $self->$col;
        }
    }

    $handler->end_element( $table_data );
    $handler->end_document( {} ) if $toplevel;
}

# If this function returns true, we won't recurse into this object,
# leaving just a reference to the object.  There are a number of ways in
# which to take this decision...
sub _stop_recursion {
    my $self = shift;
    my ( %opt ) = @_;
    return 1 unless exists $opt{ norecurse };

    my $norecurse = $opt{ norecurse };
    if ( !ref $norecurse ) {
        # A simple true scalar will stop all recursion.
        return !$norecurse;
    } elsif ( ref $norecurse eq 'HASH' ) {
        # If the hash entry for this table is true, stop the recursion.
        return !$norecurse->{ $self->table };
    } elsif ( ref $norecurse eq 'CODE' ) {
        # If we've been given a lambda, punt the decision to it.  Note
        # that the return code is the reverse of what actually happens,
        # in order to make it similiar to the hash ref case.
        my @ancestors = @{ $opt{ _ancestors } || [] };
        return !$norecurse->( @ancestors, $self );
    }
}

# Override has_many() so that we can capture the method name.
__PACKAGE__->mk_classdata( '_has_many_methods' );
sub has_many {
    my $class = shift;
    my ( $method ) = @_;
    my $method_list = $class->_has_many_methods || [];
    push @$method_list, $method;
    $class->_has_many_methods( $method_list );
    return $class->NEXT::has_many( @_ );
}

# Ditto for has_a relationships.
__PACKAGE__->mk_classdata( '_has_a_methods' );
sub has_a {
    my $class = shift;
    my ( $method ) = @_;
    my $method_list = $class->_has_a_methods || [];
    push @$method_list, $method;
    $class->_has_a_methods( $method_list );
    return $class->NEXT::has_a( @_ );
}

1;
__END__

=head1 NAME

Class::DBI::ToSax - turn database objects to SAX events

=head1 SYNOPSIS

  package My::DBI;
  # NB!  Must come first in inheritance chain!
  use base qw( Class::DBI::ToSax Class::DBI );

  # In the application...
  use XML::SAX::Writer;
  my $obj = My::DBI->retrieve( $x );
  my $w = XML::SAX::Writer->new;
  $obj->to_sax( $w );

=head1 DESCRIPTION

This module adds an extra method to Class::DBI, to_sax().  All the usual
sorts of SAX handler can be passed in.  The example above shows a writer
to send the XML to stdout.

B<NB>: This class must come first in the inheritance chain because it
overrides ordinary Class::DBI methods.

The generated XML will have:

=over 4

=item *

One wrapper element, which is the name of the table, with an I<id>
attribute.  The id attribute will be the value of the primary key.  If
there are multiple primary keys, then each value will be present,
separated by slashes.

=item *

One containing element for each column which has a scalar value.

=item *

One element for each has_a() relationship, which will be nested.  The
element will be named after the column name in the table which refers to
it, so that the containing table might be exactly reconstructed using
the XML output.

=item *

Zero or more elements for each has_many() relationship, each of which
will be nested.  The elements containing each nested row will be named
after the table that they are in.

=back

=head1 METHODS

=over 4

=item to_sax( HANDLER, [ OPTS ] )

Transform the object into XML via SAX events on HANDLER.  OPTS may be a
series of key value pairs.  Valid keys include:

=over 4

=item I<norecurse>

If true, do not recursively call contained objects.  There will still be
an element for the contained object, but it will only contain an id
attribute.

Optionally, the value of I<norecurse> may be set to a hash ref, in which
case, each key will be the name of a table which is not to be recursed
into.  This can be used to avoid retrieveing too much data from the
database when it is not needed.

If I<norecurse> is set to a coderef, then it will be called.  It is
expected to return a true value if it wants recursion stopped at that
point.  It will be passed a list of objects back up to the original
caller in order to help it make its decision.

=item I<notoplevel>

If true, then do not call start_document() and end_document().  This
lets you insert a stream of SAX events for your Class::DBI objects
into another stream of SAX events.

=back

=back

=head1 SEE ALSO

L<Class::DBI>, L<XML::SAX>, L<XML::SAX::Writer>.

If you want to generate XML directly from the database without using
Class::DBI, look at L<XML::Generator::DBI>.

=head1 BUGS

We should be able to flag some fields as containing CDATA.  I'm not sure
of the best interface to do this, however.

=head1 AUTHOR

Dominic Mitchell, E<lt>cpan@semantico.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by semantico

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

# vim: set ai et sw=4 :
