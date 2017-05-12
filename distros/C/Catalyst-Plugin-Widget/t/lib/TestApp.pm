package TestApp;

=head NAME

TestApp - Just a test application

=cut

use Catalyst::Runtime 5.80;
use Moose;

extends 'Catalyst';

# Go!
__PACKAGE__->setup(qw(
	Widget
));


1;

