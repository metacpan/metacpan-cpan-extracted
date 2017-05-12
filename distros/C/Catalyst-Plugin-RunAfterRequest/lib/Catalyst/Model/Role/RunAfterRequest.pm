package Catalyst::Model::Role::RunAfterRequest;
BEGIN {
  $Catalyst::Model::Role::RunAfterRequest::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $Catalyst::Model::Role::RunAfterRequest::VERSION = '0.04';
}
# ABSTRACT: run code after the response has been sent

use Moose::Role;
use Catalyst::Component::InstancePerContext;

with 'Catalyst::Component::InstancePerContext';

has '_context' => ( is => 'ro', weak_ref => 1 );

# no-op that the 'around' can wrap. Allows the higher up model to implement
# their own 'build_per_context_instance' method.
sub build_per_context_instance { return shift; }

around build_per_context_instance => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;

    $self = $self->$orig( $c, @_ );

    bless( { %$self, _context => $c }, ref($self) );
};

sub _run_after_request {
    my $self = shift;
    $self->_context->run_after_request(@_);
}


1;

__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::Model::Role::RunAfterRequest - run code after the response has been sent

=head1 DESCRIPTION

See L<Catalyst::Plugin::RunAfterRequest> for full documentation.

=for Pod::Coverage build_per_context_instance

=head1 AUTHORS

=over 4

=item *

Matt S Trout <mst@shadowcat.co.uk>

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Pedro Melo <melo@simplicidade.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Matt S Trout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

