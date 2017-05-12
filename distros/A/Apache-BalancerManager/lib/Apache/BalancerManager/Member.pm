package Apache::BalancerManager::Member;
{
  $Apache::BalancerManager::Member::VERSION = '0.001002';
}

# ABSTRACT: ClientSide representation of Apache BalancerManager Member

use Moo;

has $_ => ( is => 'rw' ) for qw(
   load_factor
   lb_set
   route
   route_redirect
   status
);

has $_ => ( is => 'ro' ) for qw(
   times_elected
   location
);

has $_ => (
   is => 'ro',
   coerce => sub {$_[0] =~ s/\s//g; $_[0]}
) for qw(from to);

has manager => (
   is => 'ro',
   required => 1,
   weak_ref => 1,
   handles => {
      _balancer_name => 'name',
      _nonce         => 'nonce',
      _url           => 'url',
      _get           => '_get',
   },
);

sub disable { $_[0]->status(0) }
sub enable { $_[0]->status(1) }

sub update {
   my $self = shift;

   my $uri = URI->new($self->_url);
   $uri->query_form({
      lf    => $self->load_factor,
      ls    => $self->lb_set,
      wr    => $self->route,
      rr    => $self->route_redirect,
      dw    => ( $self->status ? 'Enable' : 'Disable' ),
      w     => $self->location,
      b     => $self->_balancer_name,
      nonce => $self->_nonce,
   });
   $self->_get($uri);
}

1;


__END__
=pod

=head1 NAME

Apache::BalancerManager::Member - ClientSide representation of Apache BalancerManager Member

=head1 ATTRIBUTES

=head2 load_factor

C<writeable>.  See
L<lbfactor|https://httpd.apache.org/docs/2.2/mod/mod_proxy_balancer.html#requests>.

=head2 lb_set

C<writeable>.  See
L<lbstatus|https://httpd.apache.org/docs/2.2/mod/mod_proxy_balancer.html#requests>.

=head2 route

C<writeable>.  See
L<route|https://httpd.apache.org/docs/2.2/mod/mod_proxy_balancer.html#stickyness_implementation>

=head2 route_redirect

C<writeable>.  I'm not really sure what this is.

=head2 status

C<writeable>.  Boolean for whether or not the member is enabled

=head2 times_elected

C<not writeable>.  Number of times the member has been elected

=head2 location

C<not writeable>.  The full path of the member, for example,
C<http://127.0.0.1:5021>.

=head2 from

C<not writeable>.  The amount of data that has come out of the member.

=head2 to

C<not writeable>.  The amount of data that has been sent to the member.

=head1 METHODS

=head2 enable

sets the C<status> to 1

=head2 disable

sets the C<status> to 0

=head2 update

No arguments.  Updates the balancer manager to have the value of the current
object.

   my $member = $manager->get_member_by_location('http://127.0.0.1:5001');
   $member->disable;
   $member->update;

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

