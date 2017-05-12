package TestApp;

use Catalyst::Runtime 5.80;
use Moose;

extends 'Catalyst';



__PACKAGE__->setup(qw(
	Widget
));

1;

