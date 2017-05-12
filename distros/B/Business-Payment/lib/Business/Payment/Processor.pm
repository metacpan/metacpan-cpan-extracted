package Business::Payment::Processor;

use Moose::Role;
use Carp;

requires 'prepare_data';
requires 'request';

has 'charge_roles' => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    default  => sub { [] }
);

sub prepare_charge {
    my ( $self, $charge ) = @_;

    # TODO: This doesn't necessarily have to be here, there are roles that
    # are always required and roles that are sometimes required (for capture vs
    # a refund) per type.  A refund or void doesn't need all the roles
    if ( defined ( my $roles = $self->charge_roles ) ) {
        foreach my $role ( @$roles ) {
            unless ( $charge->meta->does_role( $role ) ) {
                my $ns = "Business::Payment::Charge";
                unless ( $role =~ /^$ns/ ) {
                    $role = join('::', $ns, $role);
                    if ( $charge->meta->does_role( $role ) ) {
                        next;
                    }
                }
                croak "Charge must have the role '$role' applied";
            }
        }
    }

}

sub handle {
    my ( $self, $charge ) = @_;

    $self->prepare_charge( $charge );

    my $data = $self->prepare_data( $charge );
    
    $self->prepare_result( $self->request( { }, $data ) );
}

sub prepare_result {
    my ( $self, $response ) = @_;
    return Business::Payment::Result->new(
        success         => 0,
        error_code      => -1,
        error_message   => 'No prepare_result method defined in processor'
    );
}


1;

=head1 NAME

Business::Payment::Processor - Role for all Processors

=head1 SYNOPSIS

    package My::Processor;
    
    use Moose;
    
    with 'Business::Payment::Processor';

    sub handle {
        die "Ain't got no money";
        return 1;
    }
    
    no Moose;
    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Business::Payment::Processor is the base class from which all Processors
should inherit.

=head1 AUTHOR

Cory G Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


