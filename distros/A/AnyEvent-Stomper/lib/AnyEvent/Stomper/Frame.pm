package AnyEvent::Stomper::Frame;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.36';

use Encode qw( decode );


sub new {
  my $class   = shift;
  my $command = shift;
  my $headers = shift;
  my $body    = shift;

  my $self = bless {}, $class;

  $self->{command} = $command;
  $self->{headers} = $headers;
  $self->{body}    = $body;

  return $self;
}

# Generate getters
{
  no strict qw( refs );

  foreach my $name ( qw( command headers body ) )
  {
    *{$name} = sub {
      my $self = shift;
      return $self->{$name};
    }
  }
}

1;
__END__

=head1 NAME

AnyEvent::Stomper::Frame - Class of STOMP frame for AnyEvent::Stomper

=head1 DESCRIPTION

Class of frame for L<AnyEvent::Stomper>. Objects of this class can be passed
to callbacks.

=head1 CONSTRUCTOR

=head2 new( $command, \%headers [, $body ] )

Creates error object.

=head1 METHODS

=head2 command()

Gets command name

=head2 headers()

Gets frame headers

=head2 body()

Gets frame body

=head1 SEE ALSO

L<AnyEvent::Stomper>

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

Sponsored by SMS Online, E<lt>dev.opensource@sms-online.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2017, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
