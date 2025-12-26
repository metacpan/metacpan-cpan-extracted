package AnyEvent::FTP::Response;

use strict;
use warnings;
use 5.010;
use overload
  '""' => sub { shift->as_string },
  fallback => 1,
  bool => sub { 1 }, fallback => 1;

# ABSTRACT: Response class for asynchronous ftp client
our $VERSION = '0.20'; # VERSION


sub new
{
  my($class, $code, $message) = @_;
  $message = [ $message ] unless ref($message) eq 'ARRAY';
  bless { code => $code, message => $message }, $class;
}


sub code           { shift->{code}            }


sub message        { shift->{message}         }


sub is_success     { shift->{code} !~ /^[45]/ }


sub is_preliminary { shift->{code} =~ /^1/    }


sub as_string
{
  my($self) = @_;
  sprintf "[%d] %s%s", $self->{code}, $self->{message}->[0], @{ $self->{message} } > 1 ? '...' : '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Response - Response class for asynchronous ftp client

=head1 VERSION

version 0.20

=head1 DESCRIPTION

Instances of this class represent a FTP server response.

=head1 ATTRIBUTES

=head2 code

 my $code = $client->code;

Integer code for the message.  These can be categorized thus:

=over 4

=item 1xx

Positive preliminary reply

=item 2xx

Positive completion reply

=item 3xx

Positive intermediate reply

=item 4xx

Transient negative reply

=item 5xx

Permanent negative reply

=back

Generally C<4xx> and C<5xx> messages are errors, where as C<1xx>, C<3xx> are various states of
(at least so far) successful operations.  C<2xx> indicates a completely successful
operation.

=head2 message

 my $message = $res->message;

The human readable message returned from the server.  This is always a list reference,
even if the server only returned one line.

=head1 METHODS

=head2 is_success

 my $bool = $res->is_success;

True if the response does not represent an error condition (codes C<1xx>, C<2xx> or C<3xx>).

=head2 is_preliminary

 my $bool = $res->is_preliminary;

True if the response is a preliminary positive reply (code C<1xx>).

=head2 as_string

 my $str = $res->as_string;
 my $str = "$res";

Returns a string representation of the response.  This may not be exactly what was
returned by the server, but will include the code and at least part of the message in
a human readable format.

You can also get this string by treating objects of this class as a string (using
it in a double quoted string, or by using string operators):

 print "$res";

is the same as

 print $res->as_string;

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
