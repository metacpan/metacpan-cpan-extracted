package Airlock::HTTPMessage;

# ABSTRACT: Airlock's machine endpoints for HTTP::Request and HTTP::Response

use Moo;
use HTTP::Response;
use HTTP::Status qw( status_message );
use Types::Standard qw( InstanceOf );
use namespace::autoclean;

our $VERSION = '0.001';


has airlock => (
  is       => 'ro',
  isa      => InstanceOf['Airlock'],
  required => 1
);


sub handle {
  my ( $self, $request, %origin ) = @_;
  my $airlock = $self->airlock;
  my $content = $request->content // '';
  my $form    = ( $request->header('Content-Type') // '' ) =~ m{\Aapplication/x-www-form-urlencoded\b}i;
  my ( $status, $headers, $json ) = @{
    length $content > $airlock->max_body
      ? [ 413, { 'Content-Type' => 'application/json' }, { error => 'invalid_request' } ]
      : $airlock->respond(
        $request->method, $request->uri->path, scalar $airlock->parse_form( $form ? $content : '' ),
        { ua => scalar $request->header('User-Agent'), %origin }
      )
  };
  return HTTP::Response->new(
    $status, status_message($status), [ map { $_ => $headers->{$_} } sort keys %$headers ],
    $airlock->encode_body($json)
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::HTTPMessage - Airlock's machine endpoints for HTTP::Request and HTTP::Response

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $http     = Airlock::HTTPMessage->new( airlock => $airlock );
    my $response = $http->handle( $request, ip => $remote_address );

=head1 DESCRIPTION

For a host application that is neither PSGI nor anything Airlock knows about,
but can produce an L<HTTP::Request> and send an L<HTTP::Response>. This is a
separate class so that L<Airlock> itself does not depend on L<HTTP::Message>.

=head2 airlock

Required. The L<Airlock> to answer for.

=head2 handle

    my $response = $http->handle( $request, ip => $remote_address );

Answers an L<HTTP::Request> for C<POST .../device> or C<POST .../token> with an
L<HTTP::Response>. Pass the remote address, which a request object does not
carry.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-airlock/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
