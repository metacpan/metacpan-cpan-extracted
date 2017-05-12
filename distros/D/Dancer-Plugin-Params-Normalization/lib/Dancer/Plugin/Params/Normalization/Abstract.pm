#
# This file is part of Dancer-Plugin-Params-Normalization
#
# This software is copyright (c) 2011 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dancer::Plugin::Params::Normalization::Abstract;
{
  $Dancer::Plugin::Params::Normalization::Abstract::VERSION = '0.52';
}
use strict;
use warnings;

# ABSTRACT: class for custom parameters normalization

use base 'Dancer::Engine';

# args: ($class)
# Overload this method in your normalization class if you have some init stuff to do,
# such as a database connection or making sure a directory exists...
# sub init { return 1; }

# args: ($self, $hashref)
# receives a hashref of parameters names/values. It should return a hashrefs of
# the normalized (modified) parameters.
sub normalize {
    die "retrieve not implemented";
}

# Methods below this this line should not be overloaded.

# The constructor is inherited from Dancer::Engine, itself inherited from Dancer::Object.

1;

__END__

=pod

=head1 NAME

Dancer::Plugin::Params::Normalization::Abstract - class for custom parameters normalization

=head1 VERSION

version 0.52

=head1 DESCRIPTION

This virtual class describes how to build a custom normalization object for
L<Dancer::Plugin::Params::Normalization>. This is done in order to allow
custom transformation of the parameters with a common interface.

Any custom normalization package must inherits from
Dancer::Plugin::Params::Normalization::Abstract and implement the following
abstract methods.

=head1 METHODS

=head2 init()

Is called once, on initialization of the class. Can be used to create needed
initialization objects, like a database connection, etc.

=head2 normalize($hashref)

Receives a hashref that contains the parameters keys/value. It should return a
hashref (it can be the same), containing modified parameters.

=head1 NAME

Dancer::Plugin::Params::Normalization::Abstract - abstract class for custom parameters normalization

=head1 Abstract Methods

=head1 Inherited Methods

None for now.

=head1 SEE ALSO

L<Dancer>, L<Dancer::Engine>

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
