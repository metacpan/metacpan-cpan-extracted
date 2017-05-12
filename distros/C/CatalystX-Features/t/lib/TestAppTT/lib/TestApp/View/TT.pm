package TestApp::View::TT;

use strict;
use base 'CatalystX::Features::View::TT';

__PACKAGE__->config(
TEMPLATE_EXTENSION => '.tt',
root=> TestApp->path_to('root'),
 INCLUDE_PATH => [
              TestApp->path_to( 'root', 'src' ), 
            ],

);

=head1 NAME

TestApp::View::TT - TT View for TestApp

=head1 DESCRIPTION

TT View for TestApp. 

=head1 SEE ALSO

L<TestApp>

=head1 AUTHOR

Rodrigo de Oliveira

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
