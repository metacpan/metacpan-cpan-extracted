package AnyEvent::Stomper::Error;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.36';

our %ERROR_CODES = (
  E_CANT_CONN                  => 1,
  E_IO                         => 2,
  E_CONN_CLOSED_BY_REMOTE_HOST => 3,
  E_CONN_CLOSED_BY_CLIENT      => 4,
  E_OPRN_ERROR                 => 5,
  E_UNEXPECTED_DATA            => 6,
  E_READ_TIMEDOUT              => 7,
);


sub new {
  my $class     = shift;
  my $err_msg   = shift;
  my $err_code  = shift;
  my $err_frame = shift;

  my $self = bless {}, $class;

  $self->{message} = $err_msg;
  $self->{code}    = $err_code;
  $self->{frame}   = $err_frame;

  return $self;
}

# Generate getters
{
  no strict qw( refs );

  foreach my $name ( qw( message code frame ) )
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

AnyEvent::Stomper::Error - Class of error for AnyEvent::Stomper

=head1 DESCRIPTION

Class of error for L<AnyEvent::Stomper>. Objects of this class can be passed
to callbacks.

=head1 CONSTRUCTOR

=head2 new( $err_msg, $err_code [, $frame ] )

Creates error object.

=head1 METHODS

=head2 message()

Gets error message.

=head2 code()

Gets error code.

=head2 frame()

Gets error frame

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
