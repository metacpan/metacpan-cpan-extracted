package App::CamelPKI::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    CATALYST_VAR => 'Catalyst',
    INCLUDE_PATH => [
        App::CamelPKI->path_to( 'root', 'src' ),
        App::CamelPKI->path_to( 'root', 'lib' ),
        App::CamelPKI->path_to( 'root' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
});

=head1 NAME

App::CamelPKI::View::TT - Catalyst TTSite View

=head1 SYNOPSIS

See L<App::CamelPKI>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

