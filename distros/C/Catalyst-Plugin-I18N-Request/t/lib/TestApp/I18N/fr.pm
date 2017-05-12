package TestApp::I18N::fr;

use strict;
use warnings;

use base qw( TestApp::I18N );

our %Lexicon = (
    'Hello' => 'Bonjour',
    'PATH_delocalize_recherche' => 'search',
    'PATH_localize_search'      => 'recherche',
    'PARAMETER_delocalize_recherche' => 'search',
    'PARAMETER_localize_search'      => 'recherche',
);

1;
