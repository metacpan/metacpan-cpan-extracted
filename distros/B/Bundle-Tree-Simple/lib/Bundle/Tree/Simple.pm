
package Bundle::Tree::Simple;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Bundle::Tree::Simple - A CPAN bundle for Tree::Simple and related modules 

=head1 SYNOPSIS

  perl -MCPAN -e 'install Bundle::Tree::Simple'

=head1 DESCRIPTION

This is a bundle file to install the Tree::Simple module and all associated modules. Since I tend to use all of 
these modules in most of my projects, this bundle is mostly to make my life easier.

=head1 MODULES

The following modules are installed by this bundle

=over 4

=item L<Tree::Simple>

=item L<Tree::Simple::View>

=item L<Tree::Simple::VisitorFactory>

=item L<Tree::Simple::Manager>

=back

In the process of installing these modules, the following modules will also get installed.

=over 4

=item L<Tree::Parser>

This is installed by L<Tree::Simple::Manager>

=over 4

=item L<Array::Iterator>

This is installed by L<Tree::Parser>.

=back

=item L<Class::Throwable>

This is installed by L<Tree::Simple::Manager> and L<Tree::Simple::View>

=item L<Test::Exception>

All of these modules use L<Test::Exception> in their test suites

=item L<Scalar::Util>

All of these modules use L<Scalar::Util>, however is a core module in most newer perls

=back

=begin _for_CPAN_only

CONTENTS is the actually listing of the modules that is used by CPAN.pm to install.
Humans can skip this part of the document.

=head1 CONTENTS

Tree::Simple

Tree::Simple::View

Tree::Simple::VisitorFactory

Tree::Simple::Manager

=end _for_CPAN_only

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


