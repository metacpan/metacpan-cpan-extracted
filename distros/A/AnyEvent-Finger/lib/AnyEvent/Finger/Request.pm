package AnyEvent::Finger::Request;

use strict;
use warnings;
use overload
  '""' => sub { shift->as_string },
  bool => sub { 1 }, fallback => 1;

# ABSTRACT: Simple asynchronous finger request
our $VERSION = '0.12'; # VERSION


sub new
{
  bless { raw => "$_[1]" }, $_[0];
}


sub verbose
{
  my($self) = @_;
  defined $self->{verbose} ? $self->{verbose} : $self->{verbose} = ($self->{raw} =~ /^\/W/ ? 1 : 0);
}


sub username
{
  my($self) = @_;

  unless(defined $self->{username})
  {
    if($self->{raw} =~ /^(?:\/W\s*)?([^@]*)/)
    { $self->{username} = $1 }
  }

  $self->{username};
}


sub hostnames
{
  my($self) = @_;
  return $self->{hostnames} if defined $self->{hostnames};
  $self->{hostnames} = ($self->{raw} =~ /\@(.*)$/ ? [split /\@/, $1] : []);
}


sub as_string
{
  my($self) = @_;
  join('@', ($self->username, @{ $self->hostnames }));
}


sub listing_request { shift->username eq '' ? 1 : 0 }



sub forward_request { @{ shift->hostnames } > 0 ? 1 : 0}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Finger::Request - Simple asynchronous finger request

=head1 VERSION

version 0.12

=head1 SYNOPSIS

 my $request = AnyEvent::Finger::Request->new('foo@localhost');

=head1 DESCRIPTION

This class represents finger request.  It is passed into
L<AnyEvent::Finger::Server> when a finger request is made.
See the documentation on that class for more details.

=head1 CONSTRUCTOR

=head2 new

 my $request = AnyEvent::Finger::Request->new( $address )

The constructor takes a string which is the raw finger request.

=head1 ATTRIBUTES

All attributes for this class are read only.

=head2 verbose

 my $value = $request->verbose

True if request is asking for a verbose response.  False
if request is not asking for a verbose response.

=head2 username

 my $value = $request->username

The username being requested.

=head2 hostnames

 my $value = $request->hostnames

Returns a list of hostnames (as an array ref) in the request.

=head2 as_string

 my $value = $request->as_string

Converts just the username and hostnames fields into a string.

=head2 listing_request

 my $value = $request->listing_request

Return true if the request is for a listing of users.

=head2 forward_request

 my $value = $request->forward_request

Return true if the request is to query another host.

=head1 SEE ALSO

=over 4

=item

L<AnyEvent::Finger>

=item

L<AnyEvent::Finger::Client>

=item

L<AnyEvent::Finger::Server>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
