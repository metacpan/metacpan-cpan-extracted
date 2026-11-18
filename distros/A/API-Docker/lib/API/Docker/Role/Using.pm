package API::Docker::Role::Using;
# ABSTRACT: A resource class clone that bounds a run of calls
our $VERSION = '0.006';
use Moo::Role;
use Carp qw( croak );
use namespace::clean;


# The options a clone carries. Both are read by
# API::Docker::Role::HTTP::_request and by nothing else, which is what makes
# the list closeable: every other option of _request describes the one request
# a method is building, not a run of them.
my %CARRIED = map { $_ => 1 } qw( connect_timeout read_timeout );

has _request_options => (
  is      => 'ro',
  default => sub { {} },
);

sub using {
  my ($self, @args) = @_;

  croak __PACKAGE__ . '->using takes its options as pairs; got an odd number '
    . 'of arguments' if @args % 2;

  croak __PACKAGE__ . '->using was given nothing to carry, so the clone it '
    . 'would return is the object it was called on. It carries '
    . join(' and ', sort keys %CARRIED)
    . '; where the pairs are computed, test for them at the call'
    unless @args;

  my %opts = @args;
  for my $name (sort keys %opts) {
    croak __PACKAGE__ . '->using does not carry \'' . $name . '\'. It carries '
      . join(' and ', sort keys %CARRIED) . '; everything else a request '
      . 'needs is an argument of the method that builds it'
      unless $CARRIED{$name};
  }

  # Built from the client and the options rather than copied wholesale: the
  # resource classes hold exactly one piece of state, the client, and passing
  # it through the constructor is what re-weakens the reference in the clone.
  return ref($self)->new(
    client           => $self->client,
    _request_options => { %{ $self->_request_options }, %opts },
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::Using - A resource class clone that bounds a run of calls

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new(read_timeout => 30);

    # the rule, for this client
    $docker->containers->list;

    # the exception, for these calls
    my $quick = $docker->containers->using(read_timeout => 5);
    $quick->list;
    $quick->inspect($id);

    # or in passing
    $docker->images->using(connect_timeout => 2, read_timeout => 60)
      ->pull(fromImage => 'alpine');

=head1 DESCRIPTION

L<API::Docker::Role::HTTP/read_timeout> and
L<API::Docker::Role::HTTP/connect_timeout> are attributes of the client, so
they are set once and hold for every request it makes. That is the right
level for a rule and the wrong one for an exception: a client bounded at 30
seconds is no help to the one call that must give up after 2, and a client
bounded at 2 cannot pull an image.

C<using> is the exception. It returns a B<clone of the resource class>
carrying the options, and every request made through that clone is given
them:

    $docker->containers->using(read_timeout => 5)->list;

Only the two transport bounds may be carried. Everything else a request needs
-- query parameters, the body, a streaming callback -- is an argument of the
method that builds it, and a value carried past that method could only either
overwrite what it built or be overwritten by it.

=head2 The clone and the client

The clone holds the B<same client>, on the same terms: the resource classes
hold it as a C<weak_ref>, and the clone does too. So a clone never keeps a
client alive that the caller has let go, and never becomes the reason a client
outlives its scope.

The other side of that is the footgun this distribution already has:

    my $quick = API::Docker->new->containers->using(read_timeout => 5);
    $quick->list;   # dies: the client was gone at the end of the first line

Keep the client in a variable. That is not new here: the entity classes hold
it weakly for the same reason, so C<< API::Docker->new->images->list >> has
always handed back images whose C<client> was already gone.

Nothing else is shared: the options live on the clone, the original resource
class is not touched, and two clones of one resource class know nothing of
each other.

    my $r = $docker->containers;
    my $a = $r->using(read_timeout => 5);
    my $b = $r->using(read_timeout => 60);
    # $r is still unbounded, $a is 5, $b is 60

=head2 Chaining merges, key by key

    $docker->images->using(connect_timeout => 2)->using(read_timeout => 60)

carries both, and a repeated key takes the later value:

    ->using(read_timeout => 60)->using(read_timeout => 0)   # 0 wins

Merging rather than replacing, because the two bounds are independent: a
helper that hands out a resource class with a connect bound already on it, and
a caller that then tightens the read bound, are both saying what they mean --
and a C<using> that dropped the other half would do it silently, which is the
one outcome neither of them could have wanted.

=head2 What it refuses

Both are croaks rather than a shrug, because the failure they replace is
invisible: an option this role kept and no request read would leave the caller
believing a bound is in force that is not.

=over

=item * B<An unknown option.> C<< ->using(read_timout => 5) >> is a typo, and
carrying it would bound nothing while looking exactly like a call that does.

=item * B<No options at all.> C<< ->using() >> asks for a clone that differs
from the original in nothing. Where the pairs are computed rather than
written, decide it at the call:

    my $r = %bounds ? $docker->containers->using(%bounds) : $docker->containers;

=back

An odd number of arguments croaks too, before the pairs are read.

=head2 What has no clone of its own

B<The entity classes.> C<< $container->logs >> and its neighbours are
one-line delegations to the resource class, and they hold the container's own
daemon fields -- every one of them, verbatim -- rather than a call surface, so
a clone would have to copy a record whose shape is the daemon's. The bound
belongs where the request is built:

    $docker->containers->using(read_timeout => 5)->logs($container->id);

B<The client.> C<< $docker->using(...) >> would be a second client sharing
one connection state and one negotiated API version with the first. The
client already takes both bounds as constructor arguments, which is the level
it works at.

=head2 using

    my $bounded = $docker->containers->using(read_timeout => 5);

Returns a clone of the resource class that hands C<read_timeout> and
C<connect_timeout> to every request made through it. Takes those two options
and no others; an unknown one, an odd number of arguments, and an empty call
all croak.

What it carries is held in C<_request_options>, which is private and composed
into the resource classes alongside it: C<{}> on a resource class nobody
called C<using> on, and spliced by each resource method into the option list
it hands the transport.

=head1 SEE ALSO

=over

=item * L<API::Docker/TIMEOUTS> - what the two bounds cover, and what they do
not

=item * L<API::Docker::Role::HTTP/"Bounding a request that never ends"> -
C<read_timeout>, per transport

=item * L<API::Docker::Role::HTTP/"Bounding the connection itself"> -
C<connect_timeout>, per transport

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
