package CGI::Snapp::SubClass;

use parent 'CGI::Snapp';
use strict;
use warnings;

use Moo;

has verbose =>
(
	is       => 'rw',
	default  => sub{return 0},
	required => 0,
);

our $VERSION = '2.01';

# --------------------------------------------------

1;
