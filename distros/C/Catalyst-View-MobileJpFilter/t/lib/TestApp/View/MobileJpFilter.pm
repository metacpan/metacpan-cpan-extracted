package TestApp::View::MobileJpFilter;
use strict;
use base 'Catalyst::View::MobileJpFilter';

__PACKAGE__->config->{filters} = [
    {
        module => 'Dummy',
        config => {
            prefix => 'dummy-test:{{',
            suffix => '}}',
        },
    },
];

1;
