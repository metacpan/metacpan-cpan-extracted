package AnyEvent::RipeRedis::Error;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.42';

our %ERROR_CODES = (
  E_CANT_CONN                  => 1,
  E_LOADING_DATASET            => 2,
  E_IO                         => 3,
  E_CONN_CLOSED_BY_REMOTE_HOST => 4,
  E_CONN_CLOSED_BY_CLIENT      => 5,
  E_NO_CONN                    => 6,
  E_OPRN_ERROR                 => 9,
  E_UNEXPECTED_DATA            => 10,
  E_NO_SCRIPT                  => 11,
  E_READ_TIMEDOUT              => 12,
  E_BUSY                       => 13,
  E_MASTER_DOWN                => 14,
  E_MISCONF                    => 15,
  E_READONLY                   => 16,
  E_OOM                        => 17,
  E_EXEC_ABORT                 => 18,
  E_NO_AUTH                    => 19,
  E_WRONG_TYPE                 => 20,
  E_NO_REPLICAS                => 21,
  E_BUSY_KEY                   => 22,
  E_CROSS_SLOT                 => 23,
  E_TRY_AGAIN                  => 24,
  E_ASK                        => 25,
  E_MOVED                      => 26,
  E_CLUSTER_DOWN               => 27,
  E_NOT_BUSY                   => 28,
);


sub new {
  my $class    = shift;
  my $err_msg  = shift;
  my $err_code = shift;

  my $self = bless {}, $class;

  $self->{message} = $err_msg;
  $self->{code}    = $err_code;

  return $self;
}

sub message {
  my $self = shift;
  return $self->{message};
}

sub code {
  my $self = shift;
  return $self->{code};
}

1;
__END__

=head1 NAME

AnyEvent::RipeRedis::Error - Class of error for AnyEvent::RipeRedis

=head1 DESCRIPTION

Class of error for L<AnyEvent::RipeRedis>. Objects of this class can be passed
to callbacks.

=head1 CONSTRUCTOR

=head2 new( $err_msg, $err_code )

Creates error object.

=head1 METHODS

=head2 message()

Get error message.

=head2 code()

Get error code.

=head1 SEE ALSO

L<AnyEvent::RipeRedis>

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

Sponsored by SMS Online, E<lt>dev.opensource@sms-online.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
