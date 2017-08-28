package BioSAILs::Utils::Traits;

use MooseX::Types -declare => [qw( ArrayRefOfStrs  )];
use MooseX::Types::Moose qw( ArrayRef Str  );

=head1 BioSAILs:Utils::Traits

=head2 Utils

=cut

=head3 ArrayRefOfStrs

Coerce a string to a splitting by ',' and into an array

=cut

subtype ArrayRefOfStrs, as ArrayRef [Str];

coerce ArrayRefOfStrs, from Str, via { [ split( ',', $_ ) ] };

1;
