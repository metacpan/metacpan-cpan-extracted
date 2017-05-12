package TestApp;
use strict;
use warnings;

use Catalyst;

__PACKAGE__->config->{recaptcha}->{pub_key} = '6LcsbAAAAAAAAPDSlBaVGXjMo1kJHwUiHzO2TDze';
__PACKAGE__->config->{recaptcha}->{priv_key} = '6LcsbAAAAAAAANQQGqwsnkrTd7QTGRBKQQZwBH-L';


__PACKAGE__->setup;

1;
