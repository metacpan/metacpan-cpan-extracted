package TestApp::View::Pkgconfig;

use strict;
use base 'Catalyst::View::TD';

__PACKAGE__->config(
    dispatch_to   => [qw(TestApp::TMPL::Pkgconfig)],
    postprocessor => sub {
        local $_ = shift;
        s/^\s+//msg;
        s/\s+$//msg;
        $_;
    },
    around_template => sub {
        my ($orig, $path, $args, $code) = @_;
        unshift @{ $args }, 'Shoved in by around_template';
        $orig->();
    },
);

1;
