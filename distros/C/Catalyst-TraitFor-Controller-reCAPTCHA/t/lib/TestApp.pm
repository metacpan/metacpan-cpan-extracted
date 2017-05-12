package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use Catalyst ();
extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

__PACKAGE__->config->{recaptcha}->{pub_key} = '6LcsbAAAAAAAAPDSlBaVGXjMo1kJHwUiHzO2TDze';
__PACKAGE__->config->{recaptcha}->{priv_key} = '6LcsbAAAAAAAANQQGqwsnkrTd7QTGRBKQQZwBH-L';

__PACKAGE__->setup;

1;
