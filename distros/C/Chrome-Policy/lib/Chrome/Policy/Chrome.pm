# ABSTRACT: Google Chrome Policy class

use v5.37;
use Object::Pad ':experimental';

package Chrome::Policy::Chrome;

class Chrome::Policy::Chrome :isa(Chrome::Policy);

use Path::Tiny;

field $policy_path :reader = path '/etc/opt/chrome/policies';

field $managed_policy_path :reader { $self -> policy_path -> child( 'managed' ) };

field $binary_path :reader = path '/opt/google/chrome/google-chrome';

__END__

=pod

=encoding UTF-8

=head1 NAME

Chrome::Policy::Chrome - Google Chrome Policy class

=head1 VERSION

version 0.230410

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
