package BioX::Workflow::Command::Utils::Traits;

use MooseX::Types -declare => [qw( ArrayRefOfStrs )];
use MooseX::Types::Moose qw( ArrayRef Str  );

=head1 BioX::Workflow::Command::Utils::Traits

=head2 Utils

=cut

subtype ArrayRefOfStrs, as ArrayRef [Str];

coerce ArrayRefOfStrs, from Str, via { [ split( ',', $_ ) ] };

1;
