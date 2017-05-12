package TestApp;

use Moose;
extends 'Catalyst';

__PACKAGE__->config( default_view => 'SeqIO' );
__PACKAGE__->setup;

1;
