package AI::Ollama::PushModelRequest 0.05;
# DO NOT EDIT! This is an autogenerated file.

use 5.020;
use Moo 2;
use experimental 'signatures';
use stable 'postderef';
use Types::Standard qw(Enum Str Bool Num Int HashRef ArrayRef);
use MooX::TypeTiny;

use namespace::clean;

=encoding utf8

=head1 NAME

AI::Ollama::PushModelRequest -

=head1 SYNOPSIS

  my $obj = AI::Ollama::PushModelRequest->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< insecure >>

Allow insecure connections to the library.

Only use this if you are pushing to your library during development.

=cut

has 'insecure' => (
    is       => 'ro',
);

=head2 C<< name >>

The name of the model to push in the form of <namespace>/<model>:<tag>.

=cut

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 C<< stream >>

If `false` the response will be returned as a single response object, otherwise the response will be streamed as a series of objects.

=cut

has 'stream' => (
    is       => 'ro',
);


1;
