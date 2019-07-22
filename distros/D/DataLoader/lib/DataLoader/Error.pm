package DataLoader::Error;

=encoding utf8

=head1 NAME

DataLoader::Error - simple error message object for use with DataLoader

=head1 SYNOPSIS

 my $error = DataLoader::Error->new("timed out");

 # Recommended
 DataLoader->error("timed out")

=head1 DESCRIPTION

This is an internal error object and should be created via C<< DataLoader->error >>.
Its only purpose is to mark error results within the cache and the return values of
the batch loading function, to distinguish them from successful results.

If a caller requests a data load and an object of this class is returned, it will
trigger an exception for the caller.

=head1 METHODS

=over

=cut

use v5.14;
use warnings;

use Carp qw(croak);

=item new ( message )

Accepts C<message> (a string) and creates the error object.

=cut

sub new {
    my ($class, $message) = @_;
    defined $message or croak 'message is required';
    @_ == 2 or croak "too many arguments";
    ref $message and croak "message is not a string";

    bless { message => $message }, $class;
}

=item message ()

Returns the message for this error object.

=cut

sub message {
    my $self = shift;
    return $self->{message};
}

=item throw ()

Equivalent to C<< die $self->message >>.

=cut

sub throw {
    my $self = shift;
    die $self->message;
}

=back

=cut

1;
