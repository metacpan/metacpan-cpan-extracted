package TestApp::View::TT::Encoding;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    PRE_CHOMP          => 1,
    POST_CHOMP         => 1,
    TEMPLATE_EXTENSION => '.tt',
    'TEMPLATE_EXTENSION' => '.tt',
    'DEFAULT_ENCODING'   => 'utf-8',
    PROVIDERS            => [
        {
            name        => 'Encoding',
            copy_config => [qw(INCLUDE_PATH DEFAULT_ENCODING PRE_CHOMP POST_CHOMP)]
        }
    ],
) if eval { require Template::Provider::Encoding; };

1;
