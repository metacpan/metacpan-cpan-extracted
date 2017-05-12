package CatalystX::CRUD::Iterator;
use strict;
use warnings;
use Carp;
use base qw( CatalystX::CRUD );

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD::Iterator - generic iterator wrapper for CXCM iterator() results

=head1 SYNOPSIS

 package MyApp::Model::MyModel;
 use CatalystX::CRUD::Iterator;
 use MyModel;
 __PACKAGE__->config->{object_class} = 'MyModel::Object';
 
 sub iterator {
     my ($self, $query) = @_;
     
     my $iterator = MyModel->search_for_something;
     
     # $iterator must have a next() method
     
     return CatalystX::CRUD::Iterator->new(
                                        $iterator,
                                        $self->object_class
                                        );
 }

=head1 DESCRIPTION

CatalystX::CRUD::Iterator is a general iterator class that wraps
a real iterator and blesses return results into a specified class.
CatalystX::CRUD::Iterator is a glue that provides
for a similar level of abstraction across all kinds of CXCM classes.

=cut

=head1 METHODS

=head2 new( I<iterator>, I<class_name> )

Returns a CatalystX::CRUD::Iterator instance.

I<iterator> must have a next() method and (optionally) a finish() method.

See next().

=cut

# hasa a CXCM iterator() result and calls its next() method,
# wrapping the result in the Iterator's CXCO class instance

sub new {
    my $class      = shift;
    my $iterator   = shift or $class->throw_error("need an iterator object");
    my $cxco_class = shift
        or $class->throw_error("need the name of a CXCO class");

    # sanity checks
    unless ( $iterator->can('next') ) {
        $class->throw_error("iterator $iterator has no next() method");
    }

    unless ( $cxco_class->can('new') ) {
        $class->throw_error("no new() method defined for $cxco_class");
    }

    unless ( $cxco_class->isa('CatalystX::CRUD::Object') ) {
        $class->throw_error(
            "$cxco_class does not inherit from CatalystX::CRUD::Object");
    }

    return bless(
        {   iterator => $iterator,
            cxco     => $cxco_class
        },
        $class
    );
}

=head2 next

Calls the next() method on the internal I<iterator> object,
stashing the result in an object returned by I<class_name>->new
under the I<method_name> accessor.

=cut

sub next {
    my $self = shift;
    my $next = $self->{iterator}->next;
    return unless $next;

    my $obj = $self->{cxco}->new;
    $obj->{delegate} = $next;
    return $obj;
}

=head2 finish

If the internal I<iterator> object has a finish() method,
this will call and return it. Otherwise returns true (1).

=cut

sub finish {
    my $self = shift;
    if ( $self->{iterator}->can('finish') ) {
        return $self->{iterator}->finish;
    }
    return 1;
}

=head2 serialize

Returns array ref of all objects, having called
serialize() on each one. Short-hand for:

 my $objects = [];
 while ( my $o = $iterator->next ) {
     push @$objects, $o->serialize();
 }

=cut

sub serialize {
    my $self    = shift;
    my $objects = [];
    while ( my $o = $self->next ) {
        push @$objects, $o->serialize();
    }
    return $objects;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
