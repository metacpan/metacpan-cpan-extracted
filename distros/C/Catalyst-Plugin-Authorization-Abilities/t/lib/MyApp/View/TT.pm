package MyApp::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        MyApp->path_to( 'root', 'src' ),
        MyApp->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    TEMPLATE_EXTENSION => '.tt'
});

=head1 NAME

MyApp::View::TT - Catalyst TTSite View

=head1 SYNOPSIS

See L<MyApp>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

Daniel Brosseau <dab@catapulse.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

