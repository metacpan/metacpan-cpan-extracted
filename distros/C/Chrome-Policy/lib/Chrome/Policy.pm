# ABSTRACT: Chrome Policy class

use v5.37;
use Object::Pad ':experimental';

package Chrome::Policy;

class Chrome::Policy :does(Chrome::Policy::Strict);

use URI;

field $url :reader = URI -> new ('chrome://policy/');

__END__

=pod

=encoding UTF-8

=head1 NAME

Chrome::Policy - Chrome Policy class

=head1 VERSION

version 0.230360

Enterprise policies
https://chromium.googlesource.com/chromium/src/+/HEAD/docs/enterprise/policies.md

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
