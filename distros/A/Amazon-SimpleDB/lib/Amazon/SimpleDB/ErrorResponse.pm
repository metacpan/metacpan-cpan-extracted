package Amazon::SimpleDB::ErrorResponse;
use strict;
use warnings;

use base 'Amazon::SimpleDB::Response';

# can multiple errors happen in one response?

sub new {
    my $self = shift;
    $self->SUPER::new(@_);
    $self->{'request_id'} = $self->{content}->{Response}{RequestID};
    $self->{'box_usage'}  =
      $self->{content}->{Response}{Errors}{Error}{BoxUsage};
    return $self;
}

sub code    { return $_[0]->{content}->{Response}{Errors}{Error}{Code} }
sub message { return $_[0]->{content}->{Response}{Errors}{Error}{Message} }

1;

__END__

=head1 NAME

Amazon::SimpleDB::ErrorResponse - a class representing an
error response from the SimpleDB service.

=head1 DESCRIPTION

B<This is code is in the early stages of development. Do not
consider it stable. Feedback and patches welcome.>

This is a subclass L<Amazon::SimpleDB::Response>. See its
manpage for more.

=head1 METHODS

=head2 Amazon::SimpleDB::ErrorResponse->new($args)

Constructor. It is recommended that you use
C<Amazon::SimpleDB::Response->new($http_response)> instead
of calling this directly. It will determine if request
ended in an error from SimpleDB and will construct an object
out of this class.

=head2 $res->code

Returns the SimpleDB error code (a string). See the SimpleDB
documentation for a list of all error codes.

=head2 $res->message

Returns a human-readable message describing the error.

=head1 SEE ALSO

L<Amazon::SimpleDB::Response>

=head1 AUTHOR & COPYRIGHT

Please see the L<Amazon::SimpleDB> manpage for author, copyright, and
license information.
