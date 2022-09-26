package AnyEvent::Finger::Response;

use strict;
use warnings;

# ABSTRACT: Simple asynchronous finger response
our $VERSION = '0.14'; # VERSION


sub say
{
  shift->(\@_);
}


sub done
{
  shift->();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Finger::Response - Simple asynchronous finger response

=head1 VERSION

version 0.14

=head1 DESCRIPTION

This class provides an interface for constructing a response
from a finger server for L<AnyEvent::Finger::Server>.  See
the documentation on that class for more details.

=head1 METHODS

=head2 say

 $response->say( @lines )

Send the lines to the client.  Do not include new line characters (\r,
\n or \r\n), these will be added by L<AnyEvent::Finger::Server>.

=head2 done

 $response->done

Close the connection with the client.  This signals that the response is
complete.  Do not forget to call this!

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

This software is copyright (c) 2012-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
