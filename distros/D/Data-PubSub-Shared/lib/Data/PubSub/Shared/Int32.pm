package Data::PubSub::Shared::Int32;
use strict;
use warnings;
our $VERSION = '0.08';
use Data::PubSub::Shared ();
1;

__END__

=head1 NAME

Data::PubSub::Shared::Int32 - compact int32 message variant of Data::PubSub::Shared

=head1 DESCRIPTION

The 32-bit signed integer variant: same lock-free publish/subscribe API as
L<Data::PubSub::Shared::Int> in half the per-slot memory (8-byte slots). See
L<Data::PubSub::Shared> for the full API, synopsis, and cross-process semantics.

=head1 SEE ALSO

L<Data::PubSub::Shared>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
