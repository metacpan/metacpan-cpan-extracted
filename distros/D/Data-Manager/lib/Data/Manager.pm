package Data::Manager;
{
  $Data::Manager::VERSION = '0.10';
}
use Moose;
use MooseX::Storage;

with 'MooseX::Storage::Deferred';

# ABSTRACT: The Marriage of Message::Stack & Data::Verifier

use Message::Stack;
use Message::Stack::Parser::DataVerifier;


has 'messages' => (
    is => 'ro',
    isa => 'Message::Stack',
    lazy => 1,
    default => sub { Message::Stack->new },
    handles => {
        'messages_for_scope' => 'for_scope',
    }
);

has '_parser' => (
    is => 'ro',
    isa => 'Message::Stack::DataVerifier',
);


has 'results' => (
    traits => [ 'Hash' ],
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
    handles => {
        'set_results' => 'set',
        'get_results' => 'get'
    }
);


has 'verifiers' => (
    traits => [ 'Hash', 'DoNotSerialize' ],
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
    handles => {
        'set_verifier' => 'set',
        'get_verifier' => 'get'
    }
);


sub success {
    my ($self) = @_;

    foreach my $res (keys %{ $self->results }) {
        return 0 unless $self->get_results($res)->success;
    }

    return 1;
}


sub verify {
    my ($self, $scope, $data) = @_;

    my $verifier = $self->get_verifier($scope);
    die("No verifier for scope: $scope") unless defined($verifier);

    my $results = $verifier->verify($data);
    $self->set_results($scope, $results);

    Message::Stack::Parser::DataVerifier::parse($self->messages, $scope, $results);

    return $results;
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__
=pod

=head1 NAME

Data::Manager - The Marriage of Message::Stack & Data::Verifier

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use Data::Manager;
    use Data::Verifier;

    my $dm = Data::Manager->new;

    # Create a verifier for the 'billing_address'
    my $verifier = Data::Verifier->new(
        profile => {
            address1 => {
                required=> 1,
                type    => 'Str'
            }
            # ... more fields
        }
    );
    $dm->set_verifier('billing_address', $verifier);

    # Addresses are the same, reuse the verifier
    $dm->set_verifier('shipping_address', $verifier);

    my $ship_data = {
        address1 => { '123 Test Street' },
        # ... more
    };
    my $bill_data => {
        address1 => { '123 Test Street' }
        # ... more
    };

    $dm->verify('billing_address', $bill_data);
    $dm->verify('shipping_address', $ship_data);
    
    # Later...
    
    my $bill_results = $dm->get_results('billing_address');
    my $bill_stack = $dm->messages_for_scope('billing_address');
    
    my $ship_results = $dm->get_results('shipping_address');
    my $ship_stack = $dm->messages_for_scope('shipping_address');

=head1 DESCRIPTION

Data::Manager provides a convenient mechanism for managing multiple
L<Data::Verifier> inputs with a single L<Message::Stack>, as well as
convenient retrieval of the results of verification.

This module is useful if you have complex forms and you'd prefer to create
separate L<Data::Verifier> objects, but want to avoid creating a complex
hashref of your own creation to manage things.

It should also be noted that if married with L<MooseX::Storage>, this entire
object and it's contents can be serialized.  This maybe be useful with
L<Catalyst>'s C<flash> for storing the results of verification between
redirects.

=head1 SERIALIZATION

The Data::Manager object may be serialized thusly:

  my $ser = $dm->freeze({ format => 'JSON' });
  # later
  my $dm = Data::Manager->thaw($ser, { format => 'JSON' });

This is possible thanks to the magic of L<MooseX::Storage>.  All attributes
B<except> C<verifiers> are stored.  B<Serialization causes the verifiers
attribute to be set to undefined, as those objects are not serializable>.

=head1 ATTRIBUTES

=head2 messages

The L<Message::Stack> object for this manager.  This attribute is lazily
populated, parsing the L<Data::Verifier::Results> objects.  After fetching
this attribute any changes to the results B<will not be reflected in the
message stack>.

=head2 results

HashRef of L<Data::Verifier::Results> objects, keyed by scope.

=head2 verifiers

HashRef of L<Data::Verifier> objects, keyed by scope.

=head1 METHODS

=head2 messages_for_scope ($scope)

Returns a L<Message::Stack> object containing messages for the specified
scope.

=head2 get_results ($scope)

Gets the L<Data::Verifier::Results> object for the specified scope.

=head2 set_results ($scope, $results)

Sets the L<Data::Verifier::Results> object for the specified scope.

=head2 success

Convenience method that checks C<success> on each of the results in this
manager.  Returns false if any are false.

=head2 verify ($scope, $data);

Verify the data against the specified scope.  After verification the results
and messages will be automatically created and stored.  The
L<Data::Verifier::Results> class will be returned.

=head1 ACKNOWLEDGEMENTS

Justin Hunter

Jay Shirley

Brian Cassidy

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

